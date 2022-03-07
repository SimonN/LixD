module net.server.server;

/* The daemon runs an instance of this. This can take many connections
 * from other people's NetClients.
 *
 * The game runs a NetServer instance if you click (I want to be server)
 * in the lobby. Then, the game creates a NetClient too, connects to the
 * local NetServer, and treats that NetServer without knowing it's local.
 */

import std.exception;
import std.format;

import derelict.enet.enet;

import net.server.adapter;
import net.server.hotel;
import net.server.outbox;
import net.enetglob;
import net.packetid;
import net.plnr;
import net.profile;
import net.structs;
import net.versioning;

enum minAcceptedOnServer = Version(0, 9, 0);
bool acceptedOnServer(Version ofClient) pure nothrow @safe @nogc
{
    return ofClient.compatibleWith(Version(0, 9, 0))
        || ofClient.compatibleWith(Version(0, 10, 0));
}

static assert(minAcceptedOnServer.acceptedOnServer);
static assert(net.versioning.gameVersion.acceptedOnServer);

class NetServer {
private:
    ENetHost* _host; // We own it.
    Hotel _hotel; // We create and own this.
    Inboxes _inboxes; // All of them forward to hour _hotel.
    SendViaEnetHost _sendWithEnet; // We own it.
    DispatchingOutbox _outbox; // Sends via our our _host.

public:
    this(in int port)
    {
        enforce(port >= 0 && port <= 0xFFFF, format("Invalid UPD port: %d"
            ~ "\nPlease choose a UPD port >= 0 and <= 65535.", port));
        initializeEnet();
        scope (failure) {
            deinitializeEnet();
        }
        ENetAddress address;
        address.host = ENET_HOST_ANY;
        address.port = port & 0xFFFF;
        _host = enet_host_create(&address,
            127, // max connections. PlNr is ubyte, redesign PlNr if want more
            2, // allow up to 2 channels to be used, 0 and 1
            0, // assume any amount of incoming bandwidth
            0); // assume any amount of outgoing bandwidth
        enforce(_host, format("Can't create enet server on UPD port %d."
            ~ "\nIs UDP port %d free for listening?"
            ~ "\nIs another Lix server already listening there?", port, port));

        _sendWithEnet = new SendViaEnetHost(_host);
        _outbox = new DispatchingOutbox(_sendWithEnet);
        _hotel = Hotel(_outbox);
        _inboxes = Inboxes(&_hotel);
    }

    void dispose()
    {
        _hotel.dispose();
        if (_host) {
            enet_host_destroy(_host);
            _host = null;
            deinitializeEnet();
        }
    }

    bool anyoneConnected() const { return ! _hotel.empty; }

    void calc()
    {
        assert (_host);
        ENetEvent event = void;
        while (enet_host_service(_host, &event, 0) > 0) {
            _sendWithEnet.computeSizeOfEnetPeer(event.peer);
            immutable PlNr from = PlNr(event.peer.incomingPeerID & 0xFF);

            final switch (event.type) {
            case ENET_EVENT_TYPE_NONE:
                assert (false, "enet_host_service should have returned 0");
            case ENET_EVENT_TYPE_CONNECT:
                // Don't add the player to the hotel rooms yet.
                // We will do that when the peer sends its hello packet.
                break;
            case ENET_EVENT_TYPE_RECEIVE:
                receivePacket(from,
                    event.packet.data[0 .. event.packet.dataLength]);
                enet_packet_destroy(event.packet);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                // There are two types of disconnections:
                // We threw him out for old version by disconnect_later(),
                // then we don't have to do anything else now.
                // Or he disconnected by his own will. The difference is
                // whether he's in our player array. Remove from hotel and
                // let the hotel decide what to do.
                _hotel.removePlayerWhoHasDisconnected(from);
                break;
            }
        }
        _hotel.calc();
        enet_host_flush(_host);
    }

private:
    void receivePacket(in PlNr from, in ubyte[] got) nothrow
    {
        if (got.length < 1) {
            return;
        }
        try {
            if (got[0] == PacketCtoS.hello) {
                receiveHello(from, got);
            }
            else {
                Inbox inbox = _inboxes.protocolOf(from);
                if (inbox !is null) switch (got[0]) {
                case PacketCtoS.toExistingRoom:
                    inbox.receiveRoomChange(from, got);
                    break;
                case PacketCtoS.createRoom:
                    inbox.receiveCreateRoom(from, got);
                    break;
                case PacketCtoS.myProfile:
                    inbox.receiveProfileChange(from, got);
                    break;
                case PacketCtoS.chatMessage:
                    inbox.receiveChat(from, got);
                    break;
                case PacketCtoS.levelFile:
                    inbox.receiveLevel(from, got);
                    break;
                case PacketCtoS.myPly:
                    inbox.receivePly(from, got);
                    break;
                default:
                    break;
                }
            }
        }
        catch (Exception) {}
    }

    void receiveHello(in PlNr from, in ubyte[] got)
    {
        immutable hello = HelloPacket(got);
        auto answer = HelloAnswerPacket();
        answer.header.plNr = from;
        answer.header.packetID = hello.fromVersion.acceptedOnServer
                               ? PacketStoC.youGoodHeresPlNr
                               : hello.fromVersion < minAcceptedOnServer
                               ? PacketStoC.youTooOld : PacketStoC.youTooNew;
        answer.serverVersion = gameVersion;
        answer.enetSendTo(_sendWithEnet.getPeer(from));

        if (answer.header.packetID == PacketStoC.youGoodHeresPlNr) {
            _inboxes.setProtocol(from, hello.fromVersion);
            _outbox.setProtocol(from, hello.fromVersion);
            _hotel.addNewPlayerToLobby(from,
                hello.profile.to2022with(hello.fromVersion));
        }
        else {
            _sendWithEnet.disconnectLater(from);
        }
    }
}

private struct Inboxes {
private:
    Inbox _inbox2016;
    Inbox _inbox2022;
    Inbox[] _receiveVia;

    this(Hotel* whereToSend) {
        _inbox2016 = new Inbox2016(whereToSend);
        _inbox2022 = new Inbox2022(whereToSend);
    }

    void setProtocol(in PlNr who, in Version hisClient) nothrow @safe
    {
        if (who >= _receiveVia.length) {
            _receiveVia.length = who + 1;
        }
        _receiveVia[who] = hisClient >= Version(0, 10, 0) ? _inbox2022
            : _inbox2016;
    }

    Inbox protocolOf(in PlNr who)
    in { assert (who < _receiveVia.length); }
    do {
        return _receiveVia[who];
    }
}

/*
 * DispatchingOutbox: Implements the outbox interface, but merely delegates
 * to other Outboxes (that it owns) that know what to send per client version.
 *
 * Server can give the DispatchingOutbox to the hotel, then the hotel can
 * call whatever the hotel likes on the PlNrs without worrying about how
 * exactly the resulting packet should look like.
 */
private class DispatchingOutbox : Outbox {
private:
    Outbox _outbox_0_9_x;
    Outbox _outbox_0_10_x;
    Outbox[] _dispatchVia;

public:
    this(SendWithEnet whereToSend) {
        _outbox_0_9_x = new Outbox_0_9_x(whereToSend);
        _outbox_0_10_x = new Outbox_0_10_x(whereToSend);
    }

    void setProtocol(in PlNr who, in Version hisClient) nothrow @safe
    {
        if (who >= _dispatchVia.length) {
            _dispatchVia.length = who + 1;
        }
        _dispatchVia[who] = hisClient >= Version(0, 10, 0) ? _outbox_0_10_x
            : _outbox_0_9_x;
    }

    /*
     * Implement each Outbox interface method by:
     * Look up the recipient's Outbox (e.g., Outbox_0_10_x) in the array,
     * then forward the method call there, with identical arguments.
     */
    import net.permu;
    import net.repdata;
    static foreach (func; __traits(allMembers, Outbox)) {
        import net.server.meta;
        mixin(format!q{
            override void %s(%s) {
                assert (_dispatchVia[receiv] !is null,
                    "Call setProtocol(receiv, hisClient) before calling %s.");
                _dispatchVia[receiv].%s(%s);
            }
        }(func, ParamTypesAndNames!(Outbox, func),
            func, func, ParamNamesOnly!(Outbox, func)));
    }
}

private class SendViaEnetHost : SendWithEnet {
private:
    ENetHost* _host; // We don't own it. We merely know the server's host.

    /*
     * Hack to detect size of ENetPeer at runtime, independently from the
     * D bindings version.
     *
     * Why do I need it: For a given int x, I must be able to send to
     * _host.peers[x] in the C-style array _host.peers. Normally, one knows
     * where in memory that is by ENetPeer.sizeof. But this depends on the
     * C header or D bindings that we use at build time. People might have
     * all sorts of enet binaries installed, and we might not fetch the
     * correct D headers for their binaries.
     *
     * We use the header's answer sizeof(ENetPeer) until I get a packet
     * from a peer with peer.incomingPeerID == 1. Then I'll use that peer's
     * offset from _host.peers to overwrite sizeOfEnetPeer.
     */
    ptrdiff_t sizeOfEnetPeer = ENetPeer.sizeof;

public:
    this(ENetHost* viaWhichWeSend)
    {
        _host = viaWhichWeSend;
    }

    ENetPeer* getPeer(in PlNr plNr) const pure nothrow @system @nogc
    {
        return cast(ENetPeer*)(cast(void*)_host.peers + plNr * sizeOfEnetPeer);
    }

    // Call this at least once before sending anything to that peer.
    void computeSizeOfEnetPeer(in ENetPeer* peerInArray) nothrow @system @nogc
    {
        if (peerInArray.incomingPeerID == 0) {
            return; // Can't guess size from peer at start of array.
        }
        sizeOfEnetPeer
            = (cast(const void*) peerInArray - cast(const void*) _host.peers)
            / peerInArray.incomingPeerID;
    }

    override void disconnectLater(in PlNr toDiscon)
    {
        enet_peer_disconnect_later(getPeer(toDiscon), 0);
    }
}
