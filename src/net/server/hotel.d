module net.server.hotel;

/* A Hotel is a collection of Rooms, each room independent from the other,
 * rooms. In each Room, there is a Festival, defining what's going on in the
 * Room. The Hotel has a lobby, room #0, where you can't do anything special.
 *
 * Only the server knows about the hotel. Clients know their Room.
 * The server makes people move between rooms by demanding that from the hotel.
 *
 * Hotel doesn't check whether the packets are an attack against the server.
 * The Server is reponsible for that, and it calls Hotel methods if the packet
 * is good.
 */

import std.algorithm;

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
        ob.describeRoom(mover, festivals[to].level,festivals[to].levelChooser);
        foreach (pl, prof; ob.allPlayers)
            if (prof.room == from) {
                ob.sendPeerLeftYourRoom(pl, mover);
                if (from == Room(0))
                    ob.informLobbyistAboutRooms(pl);
            }
            else if (prof.room == to && pl != mover)
                ob.sendPeerEnteredYourRoom(pl, mover);
    }

private:
    bool isInRoom(in PlNr plNr, Room room)
    {
        assert (ob);
        auto ptr = plNr in ob.allPlayers;
        return ptr && ptr.room == room;
    }

    void relayLevelToAll(Room room)
    {
        foreach (const plNr, ref const profile; ob.allPlayers)
            if (profile.room == room)
                ob.sendLevelByChooser(plNr, festivals[room].level,
                                            festivals[room].levelChooser);
    }
}

