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
import net.repdata;
import net.structs;
import net.versioning;

class NetServer : IHotelObserver {
private:
    ENetHost* _host;
    Profile[PlNr] _profiles;
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
        if (_host is null)
            assert (false, "error creating enet server host");
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

    bool anyoneConnected() const { return _profiles.length != 0; }

    void calc()
    {
        assert (_host);
        ENetEvent event;
        while (enet_host_service(_host, &event, 0) > 0)
            final switch (event.type) {
            case ENET_EVENT_TYPE_NONE:
                assert (false, "enet_host_service should have returned 0");
            case ENET_EVENT_TYPE_CONNECT:
                // Don't write the player's information into _profiles.
                // We will do that when the peer sends its hello packet.
                break;
            case ENET_EVENT_TYPE_RECEIVE:
                receivePacket(event.peer, event.packet);
                enet_packet_destroy(event.packet);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                broadcastDisconnection(event.peer);
                break;
            }
        enet_host_flush(_host);
    }

// ############################################################################
// ######################################################### friend class Hotel

    const(Profile[PlNr]) allPlayers() const @nogc { return _profiles; }

    // This doesn't notify anyone, they must do it on a packet receive
    void unreadyAllInRoom(Room roomWithChange) @nogc
    {
        foreach (ref profile; _profiles)
            if (profile.room == roomWithChange)
                profile.setNotReady();
    }

    void sendLevelByChooser(PlNr receiv, const(ubyte[]) level, PlNr from) @nogc
    {
        if (_host.peers + receiv is null)
            return;
        PacketHeader header;
        header.packetID = PacketStoC.peerLevelFile;
        header.plNr = from;
        auto p = createPacket(header.len + level.length);
        header.serializeTo(p.data[0 .. header.len]);
        p.data[header.len .. p.dataLength] = level[0 .. $];
        enet_peer_send(_host.peers + receiv, 0, p);
    }

    void sendReplayData(PlNr receiv, ReplayData data)
    {
        if (_host.peers + receiv is null)
            return;
        ENetPacket* p = data.createPacket(PacketStoC.peerReplayData);
        enet_peer_send(_host.peers + receiv, 0, p);
    }

    // describeRoom will send 1 or 2 packets to receiv.
    void describeRoom(PlNr receiv, const(ubyte[]) level, PlNr from)
    {
        auto informMover = ProfileListPacket();
        informMover.header.packetID = PacketStoC.peersAlreadyInYourNewRoom;
        informMover.header.plNr = receiv;
        immutable toRoom = _profiles[receiv].room;
        _profiles.byKeyValue
            .filter!(kv => kv.value.room == toRoom) // including themself
            .each!((kv) {
                informMover.indices ~= kv.key;
                informMover.profiles ~= kv.value;
            });
        enet_peer_send(_host.peers + receiv, 0, informMover.createPacket());
        if (toRoom == Room(0))
            informLobbyistAboutRooms(receiv);
        else if (level)
            sendLevelByChooser(receiv, level, from);
    }

    void informLobbyistAboutRooms(PlNr receiv)
    {
        assert (_host);
        assert (_host.peers);
        assert (receiv in _profiles);
        assert (_profiles[receiv].room == 0);
        enet_peer_send(_host.peers + receiv, 0,roomsForLobbyists.createPacket);
    }

    void sendPeerEnteredYourRoom(PlNr receiv, PlNr mover)
    {
        assert (_host);
        assert (_host.peers);
        auto pa = ProfilePacket();
        pa.header.packetID = PacketStoC.peerJoinsYourRoom;
        pa.header.plNr = mover;
        pa.profile = _profiles[mover];
        enet_peer_send(_host.peers + receiv, 0, pa.createPacket);
    }

    void sendPeerLeftYourRoom(PlNr receiv, PlNr mover)
    {
        assert (_host);
        assert (_host.peers);
        assert (receiv in _profiles);
        assert (mover in _profiles);
        auto pa = RoomChangePacket();
        pa.header.packetID = PacketStoC.peerLeftYourRoom;
        pa.header.plNr = mover;
        pa.room = _profiles[mover].room;
        enet_peer_send(_host.peers + receiv, 0, pa.createPacket);
    }

    void startGame(PlNr roomOwner, int permuLength)
    {
        unreadyAllInRoom(_profiles[roomOwner].room);
        auto pa = StartGameWithPermuPacket(permuLength);
        pa.header.packetID = PacketStoC.gameStartsWithPermu;
        pa.header.plNr = roomOwner;
        broadcastToRoom(pa);
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
        with (PacketCtoS) switch (got.data[0]) {
            case hello: receiveHello(peer, got); break;
            case toExistingRoom: receiveRoomChange(peer, got); break;
            case createRoom: receiveCreateRoom(peer, got); break;
            case myProfile: receiveProfileChange(peer, got); break;
            case chatMessage: receiveChat(peer, got); break;
            case levelFile: receiveLevel(peer, got); break;
            case myReplayData: receiveReplayData(peer, got); break;
            default: break;
        }
    }

    PlNr peerToPlNr(ENetPeer* peer) const
    {
        return PlNr((peer - _host.peers) & 0xFF);
    }

    template broadcastTemplate(bool includingSubject) {
        // This examines the struct's header for what room to broadcast.
        // This can or cannot broadcast to packet.header.plNr.
        void broadcastTemplate(Struct)(in Struct st)
            if (!is (Struct == ENetPacket*))
        {
            assert (_host);
            if (auto subject = st.header.plNr in _profiles)
                _profiles.byKeyValue
                    .filter!(kv => kv.value.room == subject.room
                        && (includingSubject || kv.key != st.header.plNr))
                    .each!(kv => enet_peer_send(_host.peers + kv.key,
                                                0, st.createPacket));
        }
    }
    alias broadcastToRoom = broadcastTemplate!true;
    alias broadcastToOthersInRoom = broadcastTemplate!false;

    void broadcastDisconnection(ENetPeer* peer)
    {
        auto discon = SomeoneDisconnectedPacket();
        discon.packetID = PacketStoC.peerDisconnected;
        discon.plNr = peerToPlNr(peer);
        broadcastToOthersInRoom(discon);
        _profiles.remove(discon.plNr);
    }

    RoomListPacket roomsForLobbyists()
    {
        Profile[Room] temp;
        foreach (profile; _profiles)
            temp[profile.room] = profile;
        temp.remove(Room(0));
        RoomListPacket roomList;
        roomList.header.packetID = PacketStoC.listOfExistingRooms;
        // We don't need to set a player number on this packet of general info
        roomList.indices = temp.keys;
        roomList.profiles = temp.values;
        return roomList;
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
        enet_peer_send(peer, 0, answer.createPacket());

        _profiles.remove(plNr);
        if (answer.header.packetID == PacketStoC.youGoodHeresPlNr) {
            _profiles[plNr] = hello.profile;
            _profiles[plNr].room = Room(0);
            _hotel.newPlayerInLobby(plNr);
        }
        else {
            // Remove peer, so that it won't get the broadcast, but don't
            // generate any packets. The peer already got our answer packet
            // and will disconnect themself.
            enet_peer_reset(peer);

            auto misfit = SomeoneMisfitsPacket();
            misfit.header.packetID = hello.fromVersion < gameVersion
                ? PacketStoC.someoneTooOld : PacketStoC.someoneTooNew;
            misfit.header.plNr = plNr;
            misfit.misfitProfile = hello.profile;
            misfit.misfitVersion = hello.fromVersion;
            misfit.serverVersion = gameVersion;
            enet_host_broadcast(_host, 0, misfit.createPacket());
        }
    }

    void receiveRoomChange(ENetPeer* peer, ENetPacket* got)
    {
        auto wish = RoomChangePacket(got);
        wish.header.plNr = peerToPlNr(peer);
        auto oldProfile = wish.header.plNr in _profiles;
        immutable oldRoom = oldProfile ? oldProfile.room : Room(0);
        if (! oldProfile || oldProfile.room == wish.room)
            return;
        oldProfile.room = wish.room;
        _hotel.playerHasMoved(wish.header.plNr, oldRoom, wish.room);
    }

    void receiveCreateRoom(ENetPeer* peer, ENetPacket* got)
    {
        immutable plNr = peerToPlNr(peer);
        auto oldProfile = plNr in _profiles;
        immutable oldRoom = oldProfile ? oldProfile.room : Room(0);
        immutable newRoom = _hotel.firstFreeRoomElseLobby();
        if (! oldProfile || oldProfile.room == newRoom)
            return;
        oldProfile.room = newRoom;
        _hotel.playerHasMoved(plNr, oldRoom, newRoom);
    }

    void receiveProfileChange(ENetPeer* peer, ENetPacket* got)
    {
        auto changed = ProfilePacket(got);
        auto plNr = peerToPlNr(peer);
        auto oldProfile = plNr in _profiles;
        if (! oldProfile) {
            // Do nothing, even though we should never get here.
            // Let this function put the profile into _profiles and broadcast.
        }
        else if (oldProfile.room != changed.profile.room)
            // room changes require another packet in our protocol
            return;
        else if (oldProfile.wouldForceAllNotReadyOnReplace(changed.profile))
            unreadyAllInRoom(_profiles[plNr].room);
        _profiles[plNr] = changed.profile;

        changed.header.packetID = PacketStoC.peerProfile;
        changed.header.plNr = plNr;
        broadcastToRoom(changed); // including to the sender!
        _hotel.maybeStartGame(_profiles[plNr].room);
    }

    void receiveChat(ENetPeer* peer, ENetPacket* got)
    {
        auto answer = ChatPacket(got);
        auto plNr = peerToPlNr(peer);
        auto profile = plNr in _profiles;
        if (! profile)
            return;
        answer.header.plNr = plNr;
        answer.header.packetID = PacketStoC.peerChatMessage;
        broadcastToRoom(answer);
    }

    void receiveLevel(ENetPeer* peer, ENetPacket* got)
    {
        auto plNr = peerToPlNr(peer);
        auto profile = plNr in _profiles;
        // Any level data is okay, even an empty one.
        // We don't impose a max size. We probably should.
        if (! profile || got.dataLength < 2)
            return;
        _hotel.receiveLevel(profile.room, plNr, got.data[2 .. got.dataLength]);
        unreadyAllInRoom(profile.room);
    }

    void receiveReplayData(ENetPeer* peer, ENetPacket* got)
    {
        auto plNr = peerToPlNr(peer);
        auto profile = plNr in _profiles;
        if (! profile || got.dataLength != ReplayData.len)
            return;
        auto data = ReplayData(got);
        data.player = plNr; // Don't trust the client. We decide who sent it!
        _hotel.receiveReplayData(profile.room, data);
    }
}
