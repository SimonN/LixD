module net.server;

/* The daemon runs an instance of this. This can take many connections
 * from other people's NetClients.
 *
 * The game runs a NetServer instance if you click (I want to be server)
 * in the lobby. Then, the game creates a NetClient too, connects to the
 * local NetServer, and treats that NetServer without knowing it's local.
 */

import std.algorithm;
import derelict.enet.enet;

import net.enetglob;
import net.packetid;
import net.structs;
import net.versioning;

class NetServer {
private:
    ENetHost* _host;
    Profile[PlNr] _profiles;

public:
    this(in int port)
    {
        initializeEnet();
        ENetAddress address;
        address.host = ENET_HOST_ANY;
        address.port = port & 0xFFFF;
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

    // This doesn't notify anyone, they must do it on a packet receive
    void unreadyAllInRoom(in Room roomWithChange)
    {
        foreach (ref profile; _profiles)
            if (profile.room == roomWithChange)
                profile.setNotReady();
    }

    void putPlayerInRoom(in PlNr mover, in Room intoRoom,
                         const(Profile)* insertThisIf404 = null
    ) {
        if (mover in _profiles) {
            // Upon room movement, all involved players unready themselves.
            // The server does this too now, but doesn't tell anyone.
            unreadyAllInRoom(_profiles[mover].room);
            auto tellOldRoom = RoomChangePacket();
            tellOldRoom.header.packetID = PacketStoC.peerLeftYourRoom;
            tellOldRoom.header.plNr = mover;
            tellOldRoom.room = intoRoom;
            broadcastToOthersInRoom(tellOldRoom);
        }
        else {
            assert (insertThisIf404 !is null);
            _profiles[mover] = *insertThisIf404;
        }
        assert (mover in _profiles);
        _profiles[mover].room = intoRoom;
        {
            auto tellNewRoom = ProfilePacket();
            tellNewRoom.header.packetID = PacketStoC.peerJoinsYourRoom;
            tellNewRoom.header.plNr = mover;
            tellNewRoom.profile = _profiles[mover];
            broadcastToOthersInRoom(tellNewRoom);
        } {
            auto informMover = ProfileListPacket();
            informMover.header.packetID = PacketStoC.peersAlreadyInYourNewRoom;
            informMover.header.plNr = mover;
            _profiles.byKeyValue
                .filter!(kv => kv.value.room == intoRoom) // including mover
                .each!((kv) {
                    // Fill the structure of arrays. I didn't make a new struct
                    informMover.plNrs ~= kv.key;
                    informMover.profiles ~= kv.value;
                });
            enet_peer_send(_host.peers + mover, 0, informMover.createPacket());
        }
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
            putPlayerInRoom(plNr, Room(0), &hello.profile);
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
        putPlayerInRoom(wish.header.plNr, wish.room);
    }

    void receiveCreateRoom(ENetPeer* peer, ENetPacket* got)
    {
        auto plNr = peerToPlNr(peer);
        auto oldProfile = plNr in _profiles;
        if (! oldProfile)
            return;
        // Find the first nonexistant room.
        // Room 0 is the lobby, this always exists, even if empty.
        Room roomToCreate = Room(1);
        while (roomToCreate < netRoomsMax
            && _profiles.byValue.any!(profile => profile.room == roomToCreate)
        ) {
            roomToCreate = Room((roomToCreate + 1) & 0xFF);
        }
        putPlayerInRoom(plNr,
            // If all rooms are full, put the player into the room they're in.
            roomToCreate == netRoomsMax ? oldProfile.room : roomToCreate);
            putPlayerInRoom(plNr, oldProfile.room);
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
        // Levels aren't wrapped in a normal struct, they're too large.
        // We avoid unnecessary copying, and instead pass this minimal struct
        // that copies from *got directly to the packets to be sent.
        struct AvoidingLevelCopy {
            PacketHeader header;
            ENetPacket* createPacket() const nothrow
            {
                auto ret = .createPacket(got.dataLength);
                header.serializeTo(ret.data[0 .. 2]);
                ret.data[2 .. got.dataLength] = got.data[2 .. got.dataLength];
                return ret;
            }
        }
        AvoidingLevelCopy lev;
        lev.header.packetID = PacketStoC.peerLevelFile;
        lev.header.plNr = peerToPlNr(peer);
        if (auto profile = lev.header.plNr in _profiles)
            unreadyAllInRoom(profile.room);
        broadcastToRoom(lev);
    }
}
