module net.client;

/* Interactive mode runs an instance of this during network games.
 * This is the high-level message API that the game and lobby call when
 * they want to send stuff over the network.
 * This receives data from a NetServer and caches it for the gameplay.
 */

import std.string;
import std.exception;
import derelict.enet.enet;

import net.enetglob;
import net.iclient;
import net.packetid;
import net.structs;
import net.style;
import net.versioning;

struct NetClientCfg {
    void delegate(string) log; // where to print messages
    string hostname;
    int port;

    string ourPlayerName;
    Style ourStyle;
}

class NetClient : INetClient {
private:
    ENetHost* _ourClient;
    ENetPeer* _serverPeer;
    PlNr _ourPlNr;
    Profile[PlNr] _profilesInOurRoom;

    NetClientCfg _cfg;

public:
    /* Immediately tries to connect to hostname:port.
     * Hostname can be a domain, e.g., "example.com" or "localhost",
     * or a dot-separated decimal IP address, e.g. "127.0.0.1"
     *
     * logFunc specifies where this prints all its log messages. This could be
     * the ingame console printer, or writeln to stdout. I want to design the
     * client and server environment-agnostic.
     */
    this(NetClientCfg cfg)
    {
        initializeEnet();
        _cfg = cfg;
        _ourClient = enet_host_create(null, // create a client == no listener
            1, // allow up to 1 outgoing connection
            2, // allow up to 2 channels to be used, 0 and 1
            0, // unlimited downstream from the server
            0); // unlimited upstream to the server
        enforce(_ourClient, "error creating enet client host");
        ENetAddress address;
        enet_address_set_host(&address, _cfg.hostname.toStringz);
        address.port = _cfg.port & 0xFFFF;
        _serverPeer = enet_host_connect(_ourClient, &address, 2, 0);
        enforce(_serverPeer, "no available peers for an enet connection");

        // We display a disconnection to our user when the server hasn't
        // replied after about 5 to 10 seconds.
        enet_peer_timeout(_serverPeer, 0, 5_000, 5_000);
    }

    ~this()
    {
        if (_ourClient) {
            enet_host_destroy(_ourClient);
            _ourClient = null;
        }
        deinitializeEnet();
    }

    void calc() { implCalc(); }

    void sendChatMessage(string aText)
    {
        assert (_ourClient);
        assert (_serverPeer);
        ChatPacket chat;
        chat.header.packetID = PacketCtoS.chatMessage;
        chat.text = aText;
        enet_peer_send(_serverPeer, 0, chat.createPacket());
    }

    @property bool connected() const
    {
        return _ourClient && _serverPeer;
    }

    void disconnect()
    {
        assert (connected);
        enet_peer_disconnect_now(_serverPeer, 0);
        enet_host_flush(_ourClient);
        destroyEnetPointers();
        _cfg.log("We have logged out.");
        // We won't wait for the disconnection return packet.
    }

    @property string ourPlayerName() const { return _cfg.ourPlayerName; }
    @property Style ourStyle() const { return _cfg.ourStyle; }
    @property Room ourRoom() const
    {
        auto ptr = _ourPlNr in _profilesInOurRoom;
        return ! connected || ! ptr ? Room(0) : ptr.room;
    }

    const(Profile[PlNr]) profilesInOurRoom() const
    {
        return _profilesInOurRoom;
    }

    // Call this when the GUI has chosen a new Lix style.
    // The GUI may update ahead of time, but what the server knows, decides.
    @property void ourStyle(Style sty)
    {
        _cfg.ourStyle = sty;
        sendUpdatedProfile((ref Profile p) {
            p.style = sty;
            p.setNotReady();
        });
    }

    // Feeling is readiness, and whether we want to observe.
    @property void ourFeeling(Profile.Feeling feel)
    {
        sendUpdatedProfile((ref Profile p) { p.feeling = feel; });
    }

    void gotoExistingRoom(Room newRoom)
    {
        if (! connected)
            return;
        RoomChangePacket wish;
        wish.header.packetID = PacketCtoS.toExistingRoom;
        wish.room = newRoom;
        enet_peer_send(_serverPeer, 0, wish.createPacket);
    }

    void createRoom()
    {
        if (! connected)
            return;
        PacketHeader wish;
        wish.packetID = PacketCtoS.createRoom;
        enet_peer_send(_serverPeer, 0, wish.createPacket);
    }

    void selectLevel(const(void[]) buffer)
    {
        if (! connected)
            return;
        ENetPacket* p = .createPacket(buffer.length + 2);
        p.data[0] = PacketCtoS.levelFile;
        p.data[2 .. p.dataLength] = (cast (const(ubyte[])) buffer)[0 .. $];
        enet_peer_send(_serverPeer, 0, p);
    }

private:
    void implCalc()
    {
        if (! connected)
            return;
        bool destroyEnetAfterCalc = false;
        ENetEvent event;
        while (enet_host_service(_ourClient, &event, 0) > 0)
            final switch (event.type) {
            case ENET_EVENT_TYPE_NONE:
                assert (false, "enet_host_service should have returned 0");
            case ENET_EVENT_TYPE_CONNECT:
                _cfg.log("We connected to a server at %s:%u.".format(
                    toDottedIpAddress(event.peer.address.host),
                    event.peer.address.port));
                sayHello();
                break;
            case ENET_EVENT_TYPE_RECEIVE:
                receivePacket(event.packet);
                enet_packet_destroy(event.packet);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                _cfg.log("The server threw us out.");
                destroyEnetAfterCalc = true;
                break;
            }
        if (destroyEnetAfterCalc)
            destroyEnetPointers();
        else
            enet_host_flush(_ourClient);
    }

    void destroyEnetPointers()
    {
        assert (connected);
        enet_host_destroy(_ourClient);
        _serverPeer = null;
        _ourClient = null;
    }

    string toDottedIpAddress(uint inNetworkByteOrder)
    {
        ubyte* ptr = cast (ubyte*) &inNetworkByteOrder;
        return "%d.%d.%d.%d".format(ptr[0], ptr[1], ptr[2], ptr[3]);
    }

    string playerName(PlNr plNr)
    {
        auto ptr = plNr in _profilesInOurRoom;
        return ptr ? ptr.name : "?";
    }

    ref Profile ourProfile()
    {
        assert (_ourClient);
        auto ptr = _ourPlNr in _profilesInOurRoom;
        assert (ptr);
        return *ptr;
    }

    void sayHello()
    {
        HelloPacket hello;
        hello.header.packetID = PacketCtoS.hello;
        hello.fromVersion = gameVersion;
        hello.profile = generateOurProfile();
        assert (_serverPeer);
        enet_peer_send(_serverPeer, 0, hello.createPacket);
    }

    Profile generateOurProfile()
    {
        Profile ret;
        ret.name = _cfg.ourPlayerName;
        ret.style = _cfg.ourStyle;
        return ret;
    }

    void sendUpdatedProfile(void delegate(ref Profile) changeTheProfile)
    {
        if (! connected || _ourPlNr !in _profilesInOurRoom)
            return;
        // Never affect our profiles directly. Always send the desire
        // to change color over the network and wait for the return packet.
        ProfilePacket newStyle;
        newStyle.header.packetID = PacketCtoS.myProfile;
        newStyle.profile = ourProfile;
        changeTheProfile(newStyle.profile);
        enet_peer_send(_serverPeer, 0, newStyle.createPacket());
    }

    // This updates a profile and logs stuff. When I dispatch events to the
    // game, this should be refactored.
    void tempFunc(ENetPacket* got, string formatstr)
    {
        auto updated = ProfilePacket(got);
        auto ptr = updated.header.plNr in _profilesInOurRoom;
        if (ptr is null || ptr.wouldForceAllNotReadyOnReplace(updated.profile))
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
        _profilesInOurRoom[updated.header.plNr] = updated.profile;
        _cfg.log(formatstr.format(ourProfile.room, updated.header.plNr,
                                                   updated.profile.name));
        describeEverything();
    }

    package void describeEverything() // test function
    {
        foreach (key, profile; _profilesInOurRoom)
            _cfg.log("    -> plNr=%d, Room=%d, name=%s, style=%s, feeling=%s"
                .format(key, profile.room, profile.name, profile.style,
                        profile.feeling));
    }

    void receivePacket(ENetPacket* got)
    {
        if (got.dataLength < 1)
            return;
        else if (got.data[0] == PacketStoC.youGoodHeresPlNr) {
            auto helloAnswered = HelloAnswerPacket(got);
            _ourPlNr = helloAnswered.header.plNr;
            _profilesInOurRoom[_ourPlNr] = generateOurProfile();
            _cfg.log("We're good! Our player number is %d.".format(_ourPlNr));
        }
        else if (got.data[0] == PacketStoC.peerJoinsYourRoom)
            tempFunc(got, "Here in room %d, player %d (%s) has joined us.");
        else if (got.data[0] == PacketStoC.peersAlreadyInYourNewRoom) {
            auto list = ProfileListPacket(got);
            _profilesInOurRoom.clear();
            foreach (i, plNr; list.plNrs)
                _profilesInOurRoom[plNr] = list.profiles[i];
            enforce(_ourPlNr in _profilesInOurRoom);
            _cfg.log("We moved into room %d.".format(ourProfile.room));
            describeEverything();
        }
        else if (got.data[0] == PacketStoC.peerProfile) {
            tempFunc(got, "In room %d, player %d (%s) updated their profile:");
        }
        else if (got.data[0] == PacketStoC.peerChatMessage) {
            auto chat = ChatPacket(got);
            if (chat.header.plNr != _ourPlNr) {
                _cfg.log("Player %d (%s) says: %s".format(chat.header.plNr,
                    playerName(chat.header.plNr), chat.text));
            }
        }
        else if (got.data[0] == PacketStoC.peerLevelFile) {
            if (got.dataLength >= 2) {
                // We only display the level when we get it back from server.
                _cfg.log("Player %d (%s) has selected the following level.".
                    format(got.data[1], playerName(PlNr(got.data[1]))));
                foreach (ref profile; _profilesInOurRoom)
                    profile.setNotReady();
                _cfg.log("--- BEGIN TRANSFERRED LEVEL ---");
                _cfg.log((cast (char*) got.data)[2 .. got.dataLength].idup);
                _cfg.log("--- END TRANSFERRED LEVEL ---");
            }
        }
        else if (got.data[0] == PacketStoC.peerDisconnected) {
            auto discon = SomeoneDisconnectedPacket(got);
            _profilesInOurRoom.remove(discon.plNr);
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
            _cfg.log("Player %d (%s) has disconnected.".format(
                discon.plNr, playerName(discon.plNr)));
            describeEverything();
        }
    }
}
