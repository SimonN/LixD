module net.client.impl;

/* Interactive mode runs an instance of this during network games.
 * This is the high-level message API that the game and lobby call when
 * they want to send stuff over the network.
 * This receives data from a NetServer and caches it for the gameplay.
 */

import std.algorithm;
import std.array;
import std.string;
import std.exception;
import derelict.enet.enet;

import net.client.adapter;
import net.client.client;
import net.enetglob;
import net.handicap;
import net.header;
import net.packetid;
import net.permu;
import net.plnr;
import net.profile;
import net.repdata;
import net.structs;
import net.style;
import net.versioning;

class NetClient : INetClient {
private:
    ENetHost* _ourClient;
    ENetPeer* _serverPeer;
    NetClientObserver[] _observers;
    ClientAdapter _adapter;

    NetClientCfg _cfg;
    PlNr _ourPlNr;
    Room _ourRoom = Room(0);
    Profile2022[PlNr] _profilesInOurRoom;

public:
    /* Immediately tries to connect to hostname:port.
     * Hostname can be a domain, e.g., "example.com" or "localhost",
     * or a dot-separated decimal IP address, e.g. "127.0.0.1"
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
        _adapter = ClientAdapter.factory(_cfg.clientVersion);
        enforce(_serverPeer, "no available peers for an enet connection");

        // We display a disconnection to our user when the server hasn't
        // replied after about 5 to 10 seconds.
        enet_peer_timeout(_serverPeer, 0, 5_000, 5_000);
    }

    void disconnectAndDispose()
    {
        if (connected || connecting) {
            enet_peer_disconnect_now(_serverPeer, 0);
            enet_host_flush(_ourClient);
            // We won't wait for the disconnection return packet.
        }
        if (_ourClient) {
            enet_host_destroy(_ourClient);
            _ourClient = null;
        }
        _serverPeer = null;
        _profilesInOurRoom.clear();
        _observers = [];
        deinitializeEnet();
    }

    void calc() { implCalc(); }

    void register(NetClientObserver obs)
    {
        assert (! _observers.canFind(obs), "Don't add same observer twice");
        _observers ~= obs;
    }

    void unregister(NetClientObserver obs)
    {
        // Don't assert; Game will double-unregister on lost connection. Hmm.
        // assert (_observers.canFind(obs), "Can't remove unknown observer");
        _observers = _observers[].remove!(entry => entry is obs);
    }

    void sendChatMessage(string aText)
    {
        assert (_ourClient);
        assert (_serverPeer);
        ChatPacket chat;
        chat.header.packetID = PacketCtoS.chatMessage;
        chat.text = aText;
        chat.enetSendTo(_serverPeer);
    }

    bool connected() const
    {
        return _ourClient && _serverPeer && _ourPlNr in _profilesInOurRoom;
    }

    bool connecting() const
    {
        return _ourClient && _serverPeer && ! (_ourPlNr in _profilesInOurRoom);
    }

    string enetLinkedVersion() const
    {
        return net.enetglob.enetLinkedVersion();
    }

    PlNr ourPlNr() const pure
    {
        assert (connected, "call this function only when you're connected");
        return _ourPlNr;
    }

    Room ourRoom() const pure
    {
        assert (connected, "call this function only when you're connected");
        return _ourRoom;
    }

    const(Profile2022) ourProfile() const pure nothrow @safe @nogc
    in { assert (connected, "call this function only when you're connected"); }
    do {
        /*
         * Normally, we'd return _profilesInOurRoom[_ourPlNr] which is @nogc,
         * but DMD before 2.102.0 had a bug that saw that line as yes-gc.
         * Let's code around that fixed DMD bug for Flathub and Debian 12.
         */
        const ptr = _ourPlNr in _profilesInOurRoom;
        assert (ptr !is null, "connected() should require that ptr != null");
        return *ptr;
    }

    const(Profile2022[PlNr]) profilesInOurRoom() const
    {
        return _profilesInOurRoom;
    }

    bool mayWeDeclareReady() const
    {
        if (! connected
            || _ourRoom == Room(0)
            || _profilesInOurRoom.length < 2
            || _profilesInOurRoom.byValue.all!(pro
                => pro.feeling == Profile2022.Feeling.observing)
        ) {
            return false;
        }
        final switch (ourProfile.feeling) {
            case Profile2022.Feeling.thinking: return true;
            case Profile2022.Feeling.ready: return true;
            case Profile2022.Feeling.observing: return false;
        }
    }

    // Call this when the GUI has chosen a new Lix style.
    // The GUI may update ahead of time, but what the server knows, decides.
    void setOurProfile(in Profile wish)
    {
        if (! connected)
            return;
        _cfg.ourStyle = wish.style;
        // Never affect our profiles directly. Always send the desire
        // to change color over the network and wait for the return packet.
        _adapter.sendOurUpdatedProfile(_serverPeer, wish, _ourPlNr, _ourRoom);
    }

    void gotoExistingRoom(Room newRoom)
    {
        if (! connected)
            return;
        RoomChangePacket wish;
        wish.header.packetID = PacketCtoS.toExistingRoom;
        wish.room = newRoom;
        wish.enetSendTo(_serverPeer);
    }

    void createRoom()
    {
        if (! connected)
            return;
        PacketHeader2016 wish;
        wish.packetID = PacketCtoS.createRoom;
        wish.enetSendTo(_serverPeer);
    }

    void selectLevel(const(void[]) levelAsRawBytes)
    {
        if (! connected)
            return;
        struct LevelPacket {
            int len() const nothrow @nogc
            {
                return (2 + levelAsRawBytes.length) & 0x7FFF_FFFF;
            }
            void serializeTo(ubyte[] buf) const nothrow @nogc
            {
                assert (buf.length >= len);
                buf[0] = PacketCtoS.levelFile;
                buf[2 .. $] = (cast (const(ubyte[])) levelAsRawBytes)[0 .. $];
            }
        }
        LevelPacket().enetSendTo(_serverPeer);
    }

    void sendPly(in Ply data)
    {
        if (! connected)
            return;
        PlyPacket(PacketCtoS.myPly, data).enetSendTo(_serverPeer);
    }

private:
    void implCalc()
    {
        if (! _ourClient || ! _serverPeer) // stricter than if (! connected)
            return;
        ENetEvent event;
        // We test _ourClient every loop iteration, because the Lobby can
        // tell us to disconnect in a callback, or we can destroy ourselves
        // on disconnect.
        while (_ourClient && enet_host_service(_ourClient, &event, 0) > 0)
            final switch (event.type) {
            case ENET_EVENT_TYPE_NONE:
                assert (false, "enet_host_service should have returned 0");
            case ENET_EVENT_TYPE_CONNECT:
                sayHello();
                break;
            case ENET_EVENT_TYPE_RECEIVE:
                receivePacket(event.packet.data[0 .. event.packet.dataLength]);
                enet_packet_destroy(event.packet);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                foreach (obs; _observers) {
                    if (connected) {
                        obs.onConnectionLost();
                    }
                    else {
                        obs.onCannotConnect();
                    }
                }
                disconnectAndDispose();
                break;
            }
        if (_ourClient)
            enet_host_flush(_ourClient);
    }

    string toDottedIpAddress(uint inNetworkByteOrder)
    {
        ubyte* ptr = cast (ubyte*) &inNetworkByteOrder;
        return "%d.%d.%d.%d".format(ptr[0], ptr[1], ptr[2], ptr[3]);
    }

    string playerName(PlNr plNr) const pure nothrow @safe @nogc
    {
        auto ptr = plNr in _profilesInOurRoom;
        return ptr ? ptr.name : "?";
    }

    void sayHello()
    {
        HelloPacket hello;
        hello.header.packetID = PacketCtoS.hello;
        hello.fromVersion = _cfg.clientVersion;
        hello.profile = generateOurProfile2016();
        assert (_serverPeer);
        hello.enetSendTo(_serverPeer);
    }

    Profile2016 generateOurProfile2016()
    {
        Profile2016 ret;
        ret.name = _cfg.ourPlayerName;
        ret.style = _cfg.ourStyle;
        return ret;
    }

    void insertReceivedProfile(in PlNr forWho, in Profile2022 next)
    out { assert (forWho in _profilesInOurRoom); }
    do {
        const ptr = forWho in _profilesInOurRoom;
        const old = ptr is null ? next : *ptr;
        if (old.wouldForceAllNotReadyOnReplace(next)) {
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
        }
        _profilesInOurRoom[forWho] = next;
    }

    // Call with: got = packet.data[0 .. dataLength]
    void receivePacket(in ubyte[] got)
    {
        version (unittest) {
            // Let exceptions fly out of the test suite, failing the test.
            receivePacketMaybeThrow(got);
        }
        else version (lixDaemon) {
            assert (false,
                "The server daemon should call NetClients only in tests.");
        }
        else {
            import file.log;
            try {
                receivePacketMaybeThrow(got);
            }
            catch (Exception e) {
                log("Exception during incoming package:");
                logf("    -> ", e.msg);
                log("    -> Discarding the packet. Keep running.");
            }
            catch (Throwable e) {
                log("Unrecoverable error during incoming package:");
                logf("    -> ", e.msg);
                log("    -> Terminating Lix.");
                throw e; // Let e fly out of NetClient and out of main().
            }
        }
    }

    // Call with: got = packet.data[0 .. dataLength]
    void receivePacketMaybeThrow(in ubyte[] got)
    {
        if (got.length < 1) {
            return;
        }
        else if (got[0] == PacketStoC.youGoodHeresPlNr) {
            auto answer = HelloAnswerPacket(got);
            _ourPlNr = answer.header.plNr;
            _profilesInOurRoom[_ourPlNr]
                = generateOurProfile2016().to2022with(_cfg.clientVersion);
            foreach (obs; _observers) {
                obs.onConnect();
            }
        }
        else if (got[0] == PacketStoC.youTooOld
            ||   got[0] == PacketStoC.youTooNew
        ) {
            auto answer = HelloAnswerPacket(got);
            foreach (obs; _observers) {
                obs.onVersionMisfit(answer.serverVersion);
            }
            disconnectAndDispose();
        }
        else if (got[0] == PacketStoC.peerJoinsYourRoom) {
            const pkg = _adapter.receiveProfilePacket(got);
            insertReceivedProfile(pkg.subject, pkg.neck);
            foreach (ref profile; _profilesInOurRoom) {
                profile.setNotReady();
            }
            foreach (obs; _observers) {
                obs.onPeerJoinsRoom(pkg.neck);
            }
        }
        else if (got[0] == PacketStoC.peerLeftYourRoom) {
            auto gone = RoomChangePacket(got);
            auto name = playerName(gone.header.plNr);
            _profilesInOurRoom.remove(gone.header.plNr);
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
            foreach (obs; _observers) {
                obs.onPeerLeavesRoomTo(name, gone.room);
            }
        }
        else if (got[0] == PacketStoC.peersAlreadyInYourNewRoom) {
            auto list = _adapter.receivePeersAlreadyInYourNewRoom(got);
            _ourRoom = list.subjectsRoom;
            _profilesInOurRoom.clear();
            foreach (entry; list.arr) {
                _profilesInOurRoom[entry.plnr] = entry.profile;
            }
            enforce(_ourPlNr in _profilesInOurRoom);
            foreach (obs; _observers) {
                obs.onWeChangeRoom(_ourRoom);
            }
        }
        else if (got[0] == PacketStoC.listOfExistingRooms) {
            auto list = _adapter.receiveRoomListPacket(got);
            foreach (obs; _observers) {
                obs.onListOfExistingRooms(list.arr[]);
            }
        }
        else if (got[0] == PacketStoC.peerProfile) {
            const pkg = _adapter.receiveProfilePacket(got);
            const ptr = pkg.subject in _profilesInOurRoom;
            const old = ptr ? *ptr : pkg.neck;
            insertReceivedProfile(pkg.subject, pkg.neck);
            foreach (obs; _observers) {
                obs.onPeerChangesProfile(old, pkg.neck);
            }
        }
        else if (got[0] == PacketStoC.peerChatMessage) {
            auto chat = ChatPacket(got);
            auto from = chat.header.plNr in _profilesInOurRoom;
            if (from) {
                foreach (obs; _observers) {
                    obs.onChatMessage(*from, chat.text);
                }
            }
            else {
                auto dummy = Profile2022();
                dummy.name = "?";
                dummy.feeling = Profile2022.Feeling.observing;
                foreach (obs; _observers) {
                    obs.onChatMessage(dummy, chat.text);
                }
            }
        }
        else if (got[0] == PacketStoC.peerLevelFile) {
            if (got.length >= 2) {
                // We only display the level when we get it back from server.
                foreach (ref profile; _profilesInOurRoom)
                    profile.setNotReady();
                foreach (obs; _observers) {
                    obs.onLevelSelect(
                        playerName(PlNr(got[1])),
                        got[2 .. $]);
                }
            }
        }
        else if (got[0] == PacketStoC.gameStartsWithPermu) {
            if (got.length >= 3) {
                foreach (ref profile; _profilesInOurRoom)
                    profile.setNotReady();
                auto pa = StartGameWithPermuPacket(got);
                Permu permu = new Permu(pa.arr);
                foreach (obs; _observers) {
                    obs.onGameStart(permu);
                }
            }
        }
        else if (got[0] == PacketStoC.peerPly) {
            const Ply peerPly = PlyPacket(got).ply;
            foreach (obs; _observers) {
                obs.onPeerSendsPly(peerPly);
            }
        }
        else if (got[0] == PacketStoC.peerDisconnected) {
            auto discon = SomeoneDisconnectedPacket(got);
            auto name = playerName(discon.header.plNr);
            _profilesInOurRoom.remove(discon.plNr);
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
            foreach (obs; _observers) {
                obs.onPeerDisconnect(name);
            }
        }
        else if (got[0] == PacketStoC.millisecondsSinceGameStart) {
            assert (_serverPeer);
            auto pkg = MillisecondsSinceGameStartPacket(got);
            foreach (obs; _observers) {
                obs.onMillisecondsSinceGameStart(
                    pkg.milliseconds + _serverPeer.roundTripTime);
            }
        }
    }
}
