module net.server.adapter;

/*
 * net.server.adapter: Concrete Inboxes and Outboxes that NetServer will use.
 */
import std.array;
import std.algorithm;

import derelict.enet.enet;
import net.enetglob;
import net.header;
import net.plnr;
import net.repdata;
import net.server.hotel;
import net.server.outbox;
import net.packetid;
import net.permu;
import net.profile;
import net.structs;
import net.versioning;

package:

// ############################################################################
// Client to Server: ##########################################################
// ############################################################################

/*
 * Inbox don't have receiveHello.
 * Reason: The server should handle Hello and, based on that, choose the
 * correct Inbox (adapter) for all future packets after Hello.
 *
 * in ubyte[] got is the full payload of the ENetPacket that we received.
 * Caller calls these interface functions with: pkg.data[0 .. pkg.dataLength]
 */
interface Inbox {
    void receiveRoomChange(in PlNr from, in ubyte[] got);
    void receiveCreateRoom(in PlNr from, in ubyte[] got);
    void receiveProfileChange(in PlNr from, in ubyte[] got);
    void receiveChat(in PlNr from, in ubyte[] got);
    void receiveLevel(in PlNr from, in ubyte[] got);
    void receivePly(in PlNr from, in ubyte[] got);
}

/*
 * Convention: When we make a struct from the packet data, this struct contains
 * a header, but we don't trust header.plNr. To see who sent this
 * packet, we always rely on (PlNr from) passed by our caller, the NetServer.
 */
class Inbox2016 : Inbox {
private:
    Hotel* _hotel; // We don't own it. We merely know it and forward to it.

public:
    this(Hotel* thatWeShallForwardTo) { _hotel = thatWeShallForwardTo; }
    mixin commonInboxMethods;

    void receiveProfileChange(in PlNr from, in ubyte[] got)
    {
        _hotel.changeProfileButKeepVersion(from, ProfilePacket2016(got)
            .profile.to2022with(Version(0, 7, 77)) // Hotel ignores version.
        );
    }
}

class Inbox2022 : Inbox {
private:
    Hotel* _hotel; // We don't own it. We merely know it and forward to it.

public:
    this(Hotel* thatWeShallForwardTo) { _hotel = thatWeShallForwardTo; }
    mixin commonInboxMethods;

    void receiveProfileChange(in PlNr from, in ubyte[] got)
    {
        _hotel.changeProfileButKeepVersion(from, ProfilePacket2022(got).neck);
    }
}

private mixin template commonInboxMethods() {
    void receiveRoomChange(in PlNr from, in ubyte[] got)
    {
        _hotel.movePlayer(from, RoomChangePacket(got).room);
    }

    void receiveCreateRoom(in PlNr from, in ubyte[] got)
    {
        _hotel.movePlayer(from, _hotel.firstFreeRoomElseLobby());
    }

    void receiveChat(in PlNr from, in ubyte[] got)
    {
        _hotel.broadcastChat(from, ChatPacket(got).text);
    }

    void receiveLevel(in PlNr from, in ubyte[] got)
    {
        if (got.length < 2) {
            return; // Too short for even an empty level.
        }
        _hotel.receiveLevel(from, got[2 .. $]);
    }

    void receivePly(in PlNr from, in ubyte[] got)
    {
        auto ply = PlyPacket(got).ply;
        ply.player = from; // Don't trust. The server decides who sent it!
        _hotel.receivePly(ply);
    }
}

// ############################################################################
// Server to Client: ##########################################################
// ############################################################################

interface SendWithEnet {
    ENetPeer* getPeer(in PlNr plNr) const pure nothrow @system @nogc;
    void disconnectLater(in PlNr toDiscon);
}

class Outbox_0_9_x : Outbox {
private:
    SendWithEnet _out; // We don't own it. We merely know the server's.

public:
    this(SendWithEnet viaWhichWeSend) { _out = viaWhichWeSend; }
    mixin commonOutboxMethods;
    mixin informLobbyist2016;
    mixin describePeers2016;
    mixin sendPeerEnteredYourRoom2016;
    mixin sendProfile2016;
}

class Outbox_0_10_x : Outbox {
private:
    SendWithEnet _out; // We don't own it. We merely know the server's.

public:
    this(SendWithEnet viaWhichWeSend) { _out = viaWhichWeSend; }
    mixin commonOutboxMethods;
    mixin informLobbyist2022;
    mixin describePeers2022;
    mixin sendPeerEnteredYourRoom2022;
    mixin sendProfile2022;
}

private mixin template commonOutboxMethods() {
    void sendChat(in PlNr receiv, in PlNr fromChatter, in string text)
    {
        ChatPacket chat;
        chat.header.packetID = PacketStoC.peerChatMessage;
        chat.header.plNr = fromChatter;
        chat.text = text;
        chat.enetSendTo(_out.getPeer(receiv));
    }

    void sendPeerLeftYourRoom(PlNr receiv, PlNr mover, in Room toWhere)
    {
        auto pa = RoomChangePacket();
        pa.header.packetID = PacketStoC.peerLeftYourRoom;
        pa.header.plNr = mover;
        pa.room = toWhere;
        pa.enetSendTo(_out.getPeer(receiv));
    }

    void sendPeerDisconnected(in PlNr receiv, in PlNr disconnected)
    {
        auto discon = SomeoneDisconnectedPacket();
        discon.packetID = PacketStoC.peerDisconnected;
        discon.plNr = disconnected;
        discon.enetSendTo(_out.getPeer(receiv));
    }

    void sendLevelByChooser(PlNr receiv, const(ubyte[]) level, PlNr from) @nogc
    {
        struct LevelPacket {
            const(ubyte[]) _level;
            PlNr _from;
            int len() const pure nothrow @safe @nogc
            {
                return (2 + _level.length) & 0x7FFF_FFFF;
            }
            void serializeTo(ubyte[] buf) const nothrow @nogc {
                assert (buf.length >= len);
                PacketHeader2016 header;
                header.packetID = PacketStoC.peerLevelFile;
                header.plNr = _from;
                header.serializeTo(buf[0 .. header.len]);
                buf[header.len .. $] = _level[0 .. $];
            }
        }
        auto levpkg = LevelPacket(level, from);
        levpkg.enetSendTo(_out.getPeer(receiv));
    }

    void startGame(in PlNr receiv, in StartGameWithPermuPacket wellShuffled)
    {
        wellShuffled.enetSendTo(_out.getPeer(receiv));
    }

    void sendPly(PlNr receiv, Ply ply)
    {
        auto pp = PlyPacket(PacketStoC.peerPly, ply);
        pp.enetSendTo(_out.getPeer(receiv));
    }

    void sendMillisecondsSinceGameStart(PlNr receiv, int millis)
    {
        auto pa = MillisecondsSinceGameStartPacket();
        pa.header.packetID = PacketStoC.millisecondsSinceGameStart;
        pa.header.plNr = receiv; // doesn't matter
        pa.milliseconds = millis;
        pa.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template informLobbyist2016() {
    void informLobbyistAboutRooms(
        in PlNr receiv,
        in Version ofReceiver,
        RoomListEntry2022[] roomEntries)
    {
        RoomListPacket2016 old;
        old.header.packetID = PacketStoC.listOfExistingRooms;
        old.header.plNr = receiv;
        foreach (ref const e; roomEntries) {
            if (! e.owner.clientVersion.compatibleWith(ofReceiver)) {
                /*
                 * Don't show un-enterable rooms to 2016 protocol users;
                 * they expect all shown rooms to be enterable.
                 */
                continue;
            }
            old.indices ~= e.room;
            old.profiles ~= e.owner.to2016with(e.room);
        }
        old.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template informLobbyist2022() {
    void informLobbyistAboutRooms(
        in PlNr receiv,
        in Version ofReceiver_LegacyFor2016toFilterIncompatibleRooms,
        RoomListEntry2022[] entries)
    {
        RoomListPacket2022 rlp;
        rlp.packetId = PacketStoC.listOfExistingRooms;
        rlp.subject = receiv;
        rlp.subjectsRoom = Room(0);
        rlp.arr = entries;
        rlp.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template describePeers2016() {
    void describeLobbyists(
        in PlNr receiv,
        in Profile2022[PlNr] contents,
    ) {
        describePeersInRoom(receiv, Room(0), contents, receiv);
    }

    void describePeersInRoom(
        in PlNr receiv,
        in Room here,
        in Profile2022[PlNr] contents,
        in PlNr ownerOfHere_unusedIn2016,
    ) {
        auto informMover = ProfileListPacket2016();
        informMover.header.packetID = PacketStoC.peersAlreadyInYourNewRoom;
        informMover.header.plNr = receiv;
        foreach (key, prof; contents) {
            informMover.indices ~= key;
            informMover.profiles ~= prof.to2016with(here);
        }
        informMover.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template describePeers2022() {
    void describeLobbyists(
        in PlNr receiv,
        in Profile2022[PlNr] contents,
    ) {
        auto informMover = PeersInRoomPacket2022();
        informMover.setHeader(PacketStoC.peersAlreadyInYourNewRoom,
            Room(0), receiv);
        foreach (key, prof; contents) {
            PeerInRoomEntry2022 entry;
            entry.plnr = key;
            entry.isOwner = false;
            entry.profile = prof;
            informMover.arr ~= entry;
        }
        informMover.enetSendTo(_out.getPeer(receiv));
    }

    void describePeersInRoom(
        in PlNr receiv,
        in Room here,
        in Profile2022[PlNr] contents,
        in PlNr ownerOfHere)
    {
        auto informMover = PeersInRoomPacket2022();
        informMover.setHeader(PacketStoC.peersAlreadyInYourNewRoom,
            here, receiv);
        foreach (key, prof; contents) {
            PeerInRoomEntry2022 entry;
            entry.plnr = key;
            entry.isOwner = (key == ownerOfHere);
            entry.profile = prof;
            informMover.arr ~= entry;
        }
        informMover.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template sendPeerEnteredYourRoom2016() {
    void sendPeerEnteredYourRoom(
        in PlNr receiv,
        in Room here,
        in PlNr mover,
        in Profile2022 ofMover)
    {
        auto pa = ProfilePacket2016();
        pa.header.packetID = PacketStoC.peerJoinsYourRoom;
        pa.header.plNr = mover;
        pa.profile = ofMover.to2016with(here);
        pa.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template sendPeerEnteredYourRoom2022() {
    void sendPeerEnteredYourRoom(
        in PlNr receiv,
        in Room here,
        in PlNr mover,
        in Profile2022 ofMover)
    {
        auto pa = ProfilePacket2022();
        pa.setHeader(PacketStoC.peerJoinsYourRoom, here, mover);
        pa.neck = ofMover;
        pa.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template sendProfile2016() {
    void sendProfileChangeBy(
        in PlNr receiv,
        in Room here,
        in PlNr ofWhom,
        in Profile2022 full)
    {
        ProfilePacket2016 pa;
        pa.header.packetID = PacketStoC.peerProfile;
        pa.header.plNr = ofWhom;
        pa.profile = full.to2016with(here);
        pa.enetSendTo(_out.getPeer(receiv));
    }
}

private mixin template sendProfile2022() {
    void sendProfileChangeBy(
        in PlNr receiv,
        in Room here,
        in PlNr ofWhom,
        in Profile2022 full)
    {
        ProfilePacket2022 pa;
        pa.setHeader(PacketStoC.peerProfile, here, ofWhom);
        pa.neck = full;
        pa.enetSendTo(_out.getPeer(receiv));
    }
}
