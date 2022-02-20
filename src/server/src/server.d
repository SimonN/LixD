module net.server.server;

/* The daemon runs an instance of this. This can take many connections
 * from other people's NetClients.
 *
 * The game runs a NetServer instance if you click (I want to be server)
 * in the lobby. Then, the game creates a NetClient too, connects to the
 * local NetServer, and treats that NetServer without knowing it's local.
 */

import std.algorithm;
import derelict.enet.enet;

import net.server.ihotelob;
import net.server.hotel;
import net.enetglob;
import net.packetid;
import net.permu;
import net.profile;
import net.structs;
import net.repdata;
import net.versioning;

class NetServer : Outbox {
private:
    ENetHost* _host;
    Hotel _hotel;

public:
    this(in int port)
    {
        initializeEnet();
        ENetAddress address;
        address.host = ENET_HOST_ANY;
        address.port = port & 0xFFFF;
        _hotel = Hotel(this);
        _host = enet_host_create(&address,
            127, // max connections. PlNr is ubyte, redesign PlNr if want more
            2, // allow up to 2 channels to be used, 0 and 1
            0, // assume any amount of incoming bandwidth
            0); // assume any amount of outgoing bandwidth
        assert (_host, "error creating enet server host");
    }

    ~this()
    {
        if (_host) {
            enet_host_destroy(_host);
            _host = null;
        }
        _hotel.dispose();
        deinitializeEnet();
    }

    bool anyoneConnected() const { return ! _hotel.empty; }

    void calc()
    {
        assert (_host);
        ENetEvent event;
        while (enet_host_service(_host, &event, 0) > 0)
            final switch (event.type) {
            case ENET_EVENT_TYPE_NONE:
                assert (false, "enet_host_service should have returned 0");
            case ENET_EVENT_TYPE_CONNECT:
                // Don't add the player to the hotel rooms yet.
                // We will do that when the peer sends its hello packet.
                break;
            case ENET_EVENT_TYPE_RECEIVE:
                receivePacket(event.peer, event.packet);
                enet_packet_destroy(event.packet);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                // There are two types of disconnections:
                // We threw him out for old version by disconnect_later(),
                // then we don't have to do anything else now.
                // Or he disconnected by his own will. The difference is
                // whether he's in our player array. Remove from hotel and
                // let the hotel decide what to do.
                _hotel.removePlayerWhoHasDisconnected(peerToPlNr(event.peer));
                break;
            }
        _hotel.calc();
        enet_host_flush(_host);
    }

// ############################################################################
// ######################################################### friend class Hotel

    void sendChat(in PlNr receiv, in PlNr fromChatter, in string text)
    {
        ChatPacket chat;
        chat.header.packetID = PacketStoC.peerChatMessage;
        chat.header.plNr = fromChatter;
        chat.text = text;
        chat.enetSendTo(_host.peers + receiv);
    }

    void sendLevelByChooser(PlNr receiv, const(ubyte[]) level, PlNr from) @nogc
    {
        struct LevelPacket {
            const(ubyte[]) _level;
            PlNr _from;
            ENetPacket* createPacket() const @nogc {
                PacketHeader header;
                header.packetID = PacketStoC.peerLevelFile;
                header.plNr = _from;
                auto ret = .createPacket(header.len + _level.length);
                header.serializeTo(ret.data[0 .. header.len]);
                ret.data[header.len .. ret.dataLength] = _level[0 .. $];
                return ret;
            }
        }
        LevelPacket(level, from).enetSendTo(_host.peers + receiv);
    }

    void sendProfileChangeBy(in PlNr receiv, in PlNr ofWhom, in Profile full)
    {
        ProfilePacket pa;
        pa.header.packetID = PacketStoC.peerProfile;
        pa.header.plNr = ofWhom;
        pa.profile = full;
        pa.enetSendTo(_host.peers + receiv);
    }

    void sendPly(PlNr receiv, Ply data)
    {
        data.enetSendTo(_host.peers + receiv, PacketStoC.peerPly);
    }

    void describeRoom(in PlNr receiv, in Profile[PlNr] contents)
    {
        auto informMover = ProfileListPacket();
        informMover.header.packetID = PacketStoC.peersAlreadyInYourNewRoom;
        informMover.header.plNr = receiv;
        foreach (key, prof; contents) {
            informMover.indices ~= key;
            informMover.profiles ~= prof;
        }
        informMover.enetSendTo(_host.peers + receiv);
    }

    void informLobbyistAboutRooms(PlNr receiv, in RoomListPacket rlp)
    {
        assert (_host);
        assert (_host.peers);
        rlp.enetSendTo(_host.peers + receiv);
    }

    void sendPeerEnteredYourRoom(PlNr receiv, PlNr mover, in Profile ofMover)
    {
        assert (_host);
        assert (_host.peers);
        auto pa = ProfilePacket();
        pa.header.packetID = PacketStoC.peerJoinsYourRoom;
        pa.header.plNr = mover;
        pa.profile = ofMover;
        pa.enetSendTo(_host.peers + receiv);
    }

    void sendPeerLeftYourRoom(PlNr receiv, PlNr mover, in Room toWhere)
    {
        assert (_host);
        assert (_host.peers);
        auto pa = RoomChangePacket();
        pa.header.packetID = PacketStoC.peerLeftYourRoom;
        pa.header.plNr = mover;
        pa.room = toWhere;
        pa.enetSendTo(_host.peers + receiv);
    }

    void sendPeerDisconnected(in PlNr receiv, in PlNr disconnected)
    {
        auto discon = SomeoneDisconnectedPacket();
        discon.packetID = PacketStoC.peerDisconnected;
        discon.plNr = disconnected;
        discon.enetSendTo(_host.peers + receiv);
    }

    void startGame(in PlNr receiv, in PlNr roomOwner, in int permuLength)
    {
        auto pa = StartGameWithPermuPacket(permuLength);
        pa.header.packetID = PacketStoC.gameStartsWithPermu;
        pa.header.plNr = roomOwner;
        pa.enetSendTo(_host.peers + receiv);
    }

    void sendMillisecondsSinceGameStart(PlNr receiv, int millis)
    {
        auto pa = MillisecondsSinceGameStartPacket();
        pa.header.packetID = PacketStoC.millisecondsSinceGameStart;
        pa.header.plNr = receiv; // doesn't matter
        pa.milliseconds = millis;
        pa.enetSendTo(_host.peers + receiv);
    }

// ############################################################################

private:
    void receivePacket(ENetPeer* peer, ENetPacket* got)
    {
        assert (_host);
        assert (peer);
        assert (got);
        if (got.dataLength < 1)
            return;
        /* Convention:
         * When we make a struct from the packet data, this struct contains
         * a header, but we don't trust header.plNr. To see who sent this
         * packet, we always infer the plNr from peerToPlNr.
         */
        with (PacketCtoS) try switch (got.data[0]) {
            case hello: receiveHello(peer, got); break;
            case toExistingRoom: receiveRoomChange(peer, got); break;
            case createRoom: receiveCreateRoom(peer, got); break;
            case myProfile: receiveProfileChange(peer, got); break;
            case chatMessage: receiveChat(peer, got); break;
            case levelFile: receiveLevel(peer, got); break;
            case myPly: receivePly(peer, got); break;
            default: break;
        }
        catch (Exception) {}
    }

    PlNr peerToPlNr(ENetPeer* peer) const
    {
        return PlNr((peer - _host.peers) & 0xFF);
    }

    void receiveHello(ENetPeer* peer, ENetPacket* got)
    {
        immutable hello = HelloPacket(got);
        auto answer = HelloAnswerPacket();
        immutable plNr = peerToPlNr(peer);
        answer.header.plNr = plNr;
        answer.header.packetID = hello.fromVersion.compatibleWith(gameVersion)
                               ? PacketStoC.youGoodHeresPlNr
                               : hello.fromVersion < gameVersion
                               ? PacketStoC.youTooOld : PacketStoC.youTooNew;
        answer.serverVersion = gameVersion;
        answer.enetSendTo(peer);

        if (answer.header.packetID == PacketStoC.youGoodHeresPlNr) {
            _hotel.addNewPlayerToLobby(plNr, hello.profile);
        }
        else {
            enet_peer_disconnect_later(peer, answer.header.packetID);
        }
    }

    void receiveRoomChange(ENetPeer* peer, ENetPacket* got)
    {
        immutable wish = RoomChangePacket(got);
        _hotel.movePlayer(peerToPlNr(peer), wish.room);
    }

    void receiveCreateRoom(ENetPeer* peer, ENetPacket* got)
    {
        _hotel.movePlayer(peerToPlNr(peer), _hotel.firstFreeRoomElseLobby());
    }

    void receiveProfileChange(ENetPeer* peer, ENetPacket* got)
    {
        _hotel.changeProfile(peerToPlNr(peer), ProfilePacket(got).profile);
    }

    void receiveChat(ENetPeer* peer, ENetPacket* got)
    {
        _hotel.broadcastChat(peerToPlNr(peer), ChatPacket(got).text);
    }

    void receiveLevel(ENetPeer* peer, ENetPacket* got)
    {
        if (got.dataLength < 2) {
            return; // Too short for even an empty level.
        }
        _hotel.receiveLevel(peerToPlNr(peer), got.data[2 .. got.dataLength]);
    }

    void receivePly(ENetPeer* peer, ENetPacket* got)
    {
        if (got.dataLength != Ply.len) {
            return;
        }
        auto ply = Ply(got);
        ply.player = peerToPlNr(peer); // Don't trust. We decide who sent it!
        _hotel.receivePly(ply);
    }
}
