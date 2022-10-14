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

import net.packetid;
import net.repdata;
import net.server.outbox;
import net.server.suite;
import net.profile;
import net.structs;
import net.style;

package:

struct Hotel {
private:
    // _suites[0] is the lobby.
    // None of these Suites ever null, none are ever deallocated/replaced.
    // The level inside them is kept in the @nogc Festival.
    Suite[Room.maxExclusive] _suites;

public:
    this(Outbox outbox) {
        foreach (ubyte room, ref sui; _suites) {
            if (room == 0) {
                sui = new Lobby(outbox);
            }
            else {
                sui = new GameSuite(Room(room), outbox);
            }
        }
    }

    @disable this();
    @disable this(this);
    ~this() { dispose(); }

    void dispose()
    {
        foreach (ref sui; _suites) {
            if (sui is null) {
                continue;
            }
            sui.dispose();
            destroy(sui);
            sui = null;
        }
    }

    bool empty() const pure nothrow @safe @nogc
    {
        return _suites[].all!(sui => sui.empty);
    }

    // Returns new room ID > 0 when we have successfully created that room.
    // Returns Room(0) when we're full. The player should stay in the lobby.
    Room firstFreeRoomElseLobby()
    {
        auto candidate = Room(1);
        while (candidate < Room.maxExclusive && ! _suites[candidate].empty) {
            candidate = Room((candidate + 1) & 0xFF);
        }
        return candidate == Room.maxExclusive ? Room(0) : candidate;
    }

    void addNewPlayerToLobby(in PlNr nrOfNewbie, Profile2022 newbie)
    {
        if (! newbie.style.goodForMultiplayer) {
            newbie.style = Style.red;
        }
        _suites[Room(0)].add(nrOfNewbie, newbie);
        // It would be enough to send the overview only to the newbie.
        // But it's easiest to ask to send it to all. (Hotel knows no outbox.)
        informLobbyistsAboutRooms();
    }

    // The server should call this after the server has set the mover's room
    // to the 'to' room. Pass the 'from' room nonetheless.
    void movePlayer(in PlNr mover, in Room to)
    {
        auto from = _suites[].find!(sui => sui.contains(mover)).takeOne;
        if (from.empty) {
            return;
        }
        assert (_suites[from.front.room].room == from.front.room);
        assert (_suites[from.front.room] is from.front);
        if (_suites[to].contains(mover)) {
            return;
        }
        if (! _suites[to].allows(from.front.profileOf(mover).clientVersion)) {
            // Idea: Invent an error packet to send back here.
            // Hotel-/suite-wise, it's correct to keeping everything as-is.
            return;
        }
        const pr = from.front.pop(mover,
            Suite.PopReason(Suite.PopReason.Reason.movedToRoom, to));
        _suites[to].add(mover, pr);
        informLobbyistsAboutRooms();
    }

    // The server calls this when it got a disconnection packet.
    void removePlayerWhoHasDisconnected(PlNr who)
    {
        _suites[]
            .filter!(s => s.contains(who))
            .each!(s => s.pop(who,
                Suite.PopReason(Suite.PopReason.Reason.disconnected)));
    }

    void changeProfileButKeepVersion(in PlNr ofWhom, Profile2022 wish)
    {
        if (! wish.style.goodForMultiplayer) {
            wish.style = Style.red;
        }
        foreach (where; _suites[].find!(sui => sui.contains(ofWhom)).takeOne) {
            where.changeProfileButKeepVersion(ofWhom, wish);
        }
    }

    void broadcastChat(in PlNr chatter, in string text)
    {
        foreach (sui; _suites[].find!(s => s.contains(chatter)).takeOne) {
            sui.broadcastChat(chatter, text);
        }
    }

    void receiveLevel(PlNr chooser, const(ubyte[]) level)
    {
        foreach (sui; _suites[].find!(s => s.contains(chooser)).takeOne) {
            sui.receiveLevel(chooser, level);
        }
    }

    void receivePly(in Ply ply)
    {
        foreach (sui; _suites[].find!(s => s.contains(ply.player)).takeOne) {
            sui.receivePly(ply);
        }
    }

    void calc()
    {
        foreach (suite; _suites) {
            suite.sendTimeSyncingPackets();
        }
    }

private:
    void informLobbyistsAboutRooms()
    {
        RoomListEntry2022[] entries = _suites[]
            .filter!(sui => ! sui.empty && sui.room != Room(0))
            .map!((in Suite sui) {
                RoomListEntry2022 entry;
                entry.room = sui.room;
                entry.numInhabitants = sui.numInhabitants;
                entry.owner = sui.owner;
                return entry;
            }).array;
        _suites[Room(0)].informLobbyistsAboutRooms(entries);
    }
}
