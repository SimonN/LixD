module net.server.hotel;

/* A Hotel is a collection of Rooms, each room independent from the other,
 * rooms. In each Room, there is a Festival, defining what's going on in the
 * Room. The Hotel has a lobby, room #0, where you can't do anything special.
 *
 * Only the server knows about the hotel. Clients know their Room.
 * The server makes people move between rooms by demanding that from the hotel.
 *
 * Call calc() frequently to poll stuff, e.g., for syncing packets.
 * Not every calc() leads to a syncing packet send, Hotel takes care.
 *
 * Hotel doesn't check whether the packets are an attack against the server.
 * The Server is reponsible for that, and it calls Hotel methods if the packet
 * is good.
 */

import std.algorithm;
import std.conv;
import std.range;

import net.repdata;
import net.server.ihotelob;
import net.server.festival;
import net.structs;

package:

struct Hotel {
private:
    Festival[Room.maxExclusive] festivals;
    IHotelObserver ob;

    invariant() { assert (festivals[0].level is null); }

public:
    this(IHotelObserver ob) { this.ob = ob; }

    @disable this();
    @disable this(this);
    ~this() { dispose(); }

    void dispose()
    {
        ob = null;
        foreach (ref fe; festivals)
            fe.dispose();
    }

    PlNr owner(in Room ofRoom)
    {
        return festivals[ofRoom].owner;
    }

    // Returns new room ID > 0 when we have successfully created that room.
    // Returns Room(0) when we're full. The player should stay in the lobby.
    Room firstFreeRoomElseLobby()
    {
        auto roomToCreate = Room(1);
        while (roomToCreate < Room.maxExclusive && ob.allPlayers.byValue
                                .any!(profile => profile.room == roomToCreate)
        ) {
            roomToCreate = Room((roomToCreate + 1) & 0xFF);
        }
        return roomToCreate == Room.maxExclusive ? Room(0) : roomToCreate;
    }

    void receiveLevel(Room room, PlNr chooser, const(ubyte[]) level)
    {
        festivals[room].levelChooser = chooser;
        festivals[room].level = level; // this makes a copy
        relayLevelToAll(room);
    }

    // Call after the player has been inserted into allPlayers with room = 0.
    void newPlayerInLobby(PlNr newbie)
    {
        assert (isInRoom(newbie, Room(0)));
        ob.describeRoom(newbie, null, newbie); // 3rd argument doesn't matter
        foreach (pl, prof; ob.allPlayers)
            if (prof.room == Room(0) && pl != newbie)
                ob.sendPeerEnteredYourRoom(pl, newbie);
    }

    // The server should call this after the server has set the mover's room
    // to the 'to' room. Pass the 'from' room nonetheless.
    void playerHasMoved(PlNr mover, Room from, Room to)
    {
        assert (isInRoom(mover, to));
        assert (from != to);
        ob.unreadyAllInRoom(from);
        ob.unreadyAllInRoom(to);
        makeOwnerIfAlone(mover);
        ob.describeRoom(mover, festivals[to].level,festivals[to].levelChooser);
        foreach (pl, prof; ob.allPlayers)
            if (prof.room == from) {
                ob.sendPeerLeftYourRoom(pl, mover);
                if (from == Room(0))
                    ob.informLobbyistAboutRooms(pl);
            }
            else if (prof.room == to && pl != mover)
                ob.sendPeerEnteredYourRoom(pl, mover);
        maybeCleanRoom(from);
    }

    // The server calls this while the player is still in the profile array,
    // but the server got a disconnection packet already. We tell the
    // server to remove the player, it won't do by itself.
    void playerHasDisconnected(PlNr who)
    {
        auto prof = who in ob.allPlayers;
        assert (prof, "remove from hotel before removing from player list");
        auto room = prof.room;
        ob.broadcastDisconnectionOfAndRemove(who);
        ob.unreadyAllInRoom(room);
        maybeCleanRoom(room);
    }

    void maybeStartGame(Room room)
    {
        if (room == Room(0))
            return;
        auto party = ob.allPlayers.byValue.filter!(prof => prof.room == room);
        if ( ! party.any!(prof => prof.feeling == Profile.Feeling.ready)
            || party.any!(prof => prof.feeling == Profile.Feeling.thinking))
            return;
        version (assert) {
            auto p = festivals[room].owner in ob.allPlayers;
            assert (p);
            assert (p.room == room);
            assert (party.walkLength > 0);
        }
        festivals[room].startGame();
        ob.startGame(festivals[room].owner,
            party.filter!(prof => prof.feeling == Profile.Feeling.ready)
                 .walkLength.to!int);
    }

    void receiveReplayData(Room room, ReplayData data)
    {
        // DTODONETWORK: Remember these during a game, send all to whoever
        // late-joins the room.
        // Right now, we merely relay to existing players except sender.
        foreach (const plNr, ref const profile; ob.allPlayers)
            if (profile.room == room && plNr != data.player)
                ob.sendReplayData(plNr, data);
    }

    void calc()
    {
        sendTimeSyncingPackets();
    }

private:
    bool isInRoom(in PlNr plNr, Room room) @nogc
    {
        assert (ob);
        auto ptr = plNr in ob.allPlayers;
        return ptr && ptr.room == room;
    }

    void maybeCleanRoom(Room room) @nogc
    {
        foreach (ref const prof; ob.allPlayers)
            if (prof.room == room)
                return;
        festivals[room].dispose();
    }

    void relayLevelToAll(Room room)
    {
        foreach (const plNr, ref const profile; ob.allPlayers)
            if (profile.room == room)
                ob.sendLevelByChooser(plNr, festivals[room].level,
                                            festivals[room].levelChooser);
    }

    void makeOwnerIfAlone(PlNr plNr) @nogc
    {
        Room room = Room(0);
        foreach (pl, prof; ob.allPlayers) {
            if (pl == plNr)
                room = prof.room;
            else if (prof.room == room)
                return; // we aren't alone
        }
        if (room != Room(0))
            festivals[room].owner = plNr;
    }

    void sendTimeSyncingPackets()
    {
        for (Room ro = Room(0); ro < Room.maxExclusive;
                                ro = Room(1 + ro & 0xFF))
            if (int since = festivals[ro].millisecondsSinceGameStartOrZero)
                foreach (const plNr, ref const profile; ob.allPlayers)
                    if (profile.room == ro)
                        ob.sendMillisecondsSinceGameStart(plNr, since);
    }
}
