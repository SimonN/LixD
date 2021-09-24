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
import net.permu;
import net.repdata;
import net.structs;
import net.style;
import net.versioning;

struct NetClientCfg {
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

    void delegate() _onConnect;
    void delegate() _onCannotConnect;
    void delegate(Version serverVersion) _onVersionMisfit;
    void delegate() _onConnectionLost;
    void delegate(string name, string chat) _onChatMessage;
    void delegate(string name) _onPeerDisconnect;
    void delegate(const(Profile*)) _onPeerJoinsRoom;
    void delegate(string name, Room toRoom) _onPeerLeavesRoomTo;
    void delegate(const(Profile*)) _onPeerChangesProfile;
    void delegate(Room toRoom) _onWeChangeRoom;
    void delegate(const(Room[]), const(Profile[])) _onListOfExistingRooms;
    void delegate(string name, const(ubyte[]) data) _onLevelSelect;
    void delegate(Permu) _onGameStart;
    void delegate(Ply) _onPeerSendsPly;
    void delegate(int) _onMillisecondsSinceGameStart;

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
        deinitializeEnet();
    }

    void calc() { implCalc(); }

    // NetClient's caller should register some event callbacks.
    // It's okay to register not even a single callback, these will always
    // be tested for existence before the call.
    @property void onConnect(typeof(_onConnect) dg) { _onConnect = dg; }
    @property void onCannotConnect(typeof(_onCannotConnect) dg) { _onCannotConnect = dg; }
    @property void onVersionMisfit(typeof(_onVersionMisfit) dg) { _onVersionMisfit = dg; }
    @property void onConnectionLost(typeof(_onConnectionLost) dg) { _onConnectionLost = dg; }
    @property void onChatMessage(typeof(_onChatMessage) dg) { _onChatMessage = dg; }
    @property void onPeerDisconnect(typeof(_onPeerDisconnect) dg) { _onPeerDisconnect = dg; }
    @property void onPeerJoinsRoom(typeof(_onPeerJoinsRoom) dg) { _onPeerJoinsRoom = dg; }
    @property void onPeerLeavesRoomTo(typeof(_onPeerLeavesRoomTo) dg) { _onPeerLeavesRoomTo = dg; }
    @property void onPeerChangesProfile(typeof(_onPeerChangesProfile) dg) { _onPeerChangesProfile = dg; }
    @property void onWeChangeRoom(typeof(_onWeChangeRoom) dg) { _onWeChangeRoom = dg; }
    @property void onListOfExistingRooms(typeof(_onListOfExistingRooms) dg) { _onListOfExistingRooms = dg; }
    @property void onLevelSelect(typeof(_onLevelSelect) dg) { _onLevelSelect = dg; }
    @property void onGameStart(typeof(_onGameStart) dg) { _onGameStart = dg; }
    @property void onPeerSendsPly(typeof(_onPeerSendsPly) dg) { _onPeerSendsPly = dg; }
    @property void onMillisecondsSinceGameStart(typeof(_onMillisecondsSinceGameStart) dg) { _onMillisecondsSinceGameStart = dg; }

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
        return _ourClient && _serverPeer && _ourPlNr in _profilesInOurRoom;
    }

    @property bool connecting() const
    {
        return _ourClient && _serverPeer && ! (_ourPlNr in _profilesInOurRoom);
    }

    @property string enetLinkedVersion() const
    {
        return net.enetglob.enetLinkedVersion();
    }

    @property PlNr ourPlNr() const
    {
        assert (connected, "call this function only when you're connected");
        return _ourPlNr;
    }

    @property const(Profile) ourProfile() const
    {
        assert (connected, "call this function only when you're connected");
        return _profilesInOurRoom[_ourPlNr];
    }

    @property const(Profile[PlNr]) profilesInOurRoom() const
    {
        return _profilesInOurRoom;
    }

    @property bool mayWeDeclareReady() const
    {
        if (! connected || ! mayRoomDeclareReady(_profilesInOurRoom.byValue))
            return false;
        final switch (ourProfile.feeling) {
            case Profile.Feeling.thinking:
            case Profile.Feeling.ready: return true;
            case Profile.Feeling.observing: return false;
        }
    }

    // Call this when the GUI has chosen a new Lix style.
    // The GUI may update ahead of time, but what the server knows, decides.
    @property void ourStyle(Style sty)
    {
        _cfg.ourStyle = sty;
        sendPhyudProfile((ref Profile p) {
            p.style = sty;
            p.feeling = Profile.Feeling.thinking; // = not observing
        });
    }

    // Feeling is readiness, and whether we want to observe.
    @property void ourFeeling(Profile.Feeling feel)
    {
        sendPhyudProfile((ref Profile p) { p.feeling = feel; });
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

    void sendPly(in Ply data)
    {
        if (! connected)
            return;
        enet_peer_send(_serverPeer, 0,
            data.createPacket(PacketCtoS.myPly));
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
                receivePacket(event.packet);
                enet_packet_destroy(event.packet);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                if (connected)
                    _onConnectionLost && _onConnectionLost();
                else
                    _onCannotConnect && _onCannotConnect();
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

    string playerName(PlNr plNr)
    {
        auto ptr = plNr in _profilesInOurRoom;
        return ptr ? ptr.name : "?";
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

    void sendPhyudProfile(void delegate(ref Profile) changeTheProfile)
    {
        if (! connected)
            return;
        // Never affect our profiles directly. Always send the desire
        // to change color over the network and wait for the return packet.
        ProfilePacket newStyle;
        newStyle.header.packetID = PacketCtoS.myProfile;
        newStyle.profile = _profilesInOurRoom[_ourPlNr];
        changeTheProfile(newStyle.profile);
        enet_peer_send(_serverPeer, 0, newStyle.createPacket());
    }

    Profile* receiveProfilePacket(ENetPacket* got)
    {
        auto updated = ProfilePacket(got);
        auto ptr = updated.header.plNr in _profilesInOurRoom;
        if (ptr is null || ptr.wouldForceAllNotReadyOnReplace(updated.profile))
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
        _profilesInOurRoom[updated.header.plNr] = updated.profile;
        return updated.header.plNr in _profilesInOurRoom;
    }

    void receivePacket(ENetPacket* got)
    {
        if (got.dataLength < 1)
            return;
        else if (got.data[0] == PacketStoC.youGoodHeresPlNr) {
            auto answer = HelloAnswerPacket(got);
            _ourPlNr = answer.header.plNr;
            _profilesInOurRoom[_ourPlNr] = generateOurProfile();
            _onConnect && _onConnect();
        }
        else if (got.data[0] == PacketStoC.youTooOld
            ||   got.data[0] == PacketStoC.youTooNew
        ) {
            auto answer = HelloAnswerPacket(got);
            _onVersionMisfit && _onVersionMisfit(answer.serverVersion);
            disconnectAndDispose();
        }
        else if (got.data[0] == PacketStoC.peerJoinsYourRoom) {
            const(Profile*) changed = receiveProfilePacket(got);
            _onPeerJoinsRoom && _onPeerJoinsRoom(changed);
        }
        else if (got.data[0] == PacketStoC.peerLeftYourRoom) {
            auto gone = RoomChangePacket(got);
            auto ptr = gone.header.plNr in _profilesInOurRoom;
            auto name = ptr ? ptr.name : "?";
            _profilesInOurRoom.remove(gone.header.plNr);
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
            _onPeerLeavesRoomTo && _onPeerLeavesRoomTo(name, gone.room);
        }
        else if (got.data[0] == PacketStoC.peersAlreadyInYourNewRoom) {
            auto list = ProfileListPacket(got);
            _profilesInOurRoom.clear();
            foreach (i, const(PlNr) plNr; list.indices)
                _profilesInOurRoom[plNr] = list.profiles[i];
            enforce(_ourPlNr in _profilesInOurRoom);
            _onWeChangeRoom && _onWeChangeRoom(
                _profilesInOurRoom[_ourPlNr].room);
        }
        else if (got.data[0] == PacketStoC.listOfExistingRooms) {
            auto list = RoomListPacket(got);
            if (_onListOfExistingRooms)
                _onListOfExistingRooms(list.indices, list.profiles);
        }
        else if (got.data[0] == PacketStoC.peerProfile) {
            const(Profile*) changed = receiveProfilePacket(got);
            _onPeerChangesProfile && _onPeerChangesProfile(changed);
        }
        else if (got.data[0] == PacketStoC.peerChatMessage) {
            auto chat = ChatPacket(got);
            // We display our own chat only now.
            // Users should be able to estimate their ping with a chat echo.
            if (_onChatMessage)
                _onChatMessage(playerName(chat.header.plNr), chat.text);
        }
        else if (got.data[0] == PacketStoC.peerLevelFile) {
            if (got.dataLength >= 2) {
                // We only display the level when we get it back from server.
                foreach (ref profile; _profilesInOurRoom)
                    profile.setNotReady();
                _onLevelSelect && _onLevelSelect(playerName(PlNr(got.data[1])),
                                    got.data[2 .. got.dataLength]);
            }
        }
        else if (got.data[0] == PacketStoC.gameStartsWithPermu) {
            if (got.dataLength >= 3) {
                foreach (ref profile; _profilesInOurRoom)
                    profile.setNotReady();
                auto pa = StartGameWithPermuPacket(got);
                Permu permu = new Permu(pa.arr);
                _onGameStart && _onGameStart(permu);
            }
        }
        else if (got.data[0] == PacketStoC.peerPly) {
            if (got.dataLength == Ply.len && _onPeerSendsPly)
                _onPeerSendsPly(Ply(got));
        }
        else if (got.data[0] == PacketStoC.peerDisconnected) {
            auto discon = SomeoneDisconnectedPacket(got);
            auto ptr = discon.header.plNr in _profilesInOurRoom;
            auto name = ptr ? ptr.name : "?";
            _profilesInOurRoom.remove(discon.plNr);
            foreach (ref profile; _profilesInOurRoom)
                profile.setNotReady();
            _onPeerDisconnect && _onPeerDisconnect(name);
        }
        else if (got.data[0] == PacketStoC.millisecondsSinceGameStart) {
            assert (_serverPeer);
            _onMillisecondsSinceGameStart && _onMillisecondsSinceGameStart(
                MillisecondsSinceGameStartPacket(got).milliseconds
                + _serverPeer.roundTripTime
            );
        }
    }
}
