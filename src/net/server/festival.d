module net.server.festival;

/* A Festival defines what's going on in a room.
 * Only the server knows about festivals.
 * Not about who is in a room, because NetServer._profiles keep track of that.
 *
 * Festival is manually memory-managed, all of it is @nogc.
 */

// DTODO: Make the replay known in the network, include in Festival,
// such that (a player who joins during an already-running game)
// gets the correct replay and can jump right into the action.

import core.stdc.stdlib;

import net.structs;
import net.repdata;

package:

struct Festival {
@nogc:
private:
    ubyte[] _level; // send this data to new-joiners. Manually memory-managed.

public:
    PlNr owner; // creator of the room, I plan that he shall kick others
    PlNr levelChooser; // who has chosen the most recent level?
    bool playing; // is a game in progress?
    Update update; // if game in progress, players should sync to this

    @property const(ubyte)[] level() const { return _level; }
    @property void level(const(ubyte[]) toCopy)
    {
        if (_level.ptr !is null)
            free(_level.ptr);
        duplicate(toCopy);
    }

    @disable this(const(void)[]); // instead, copy-construct and assign level

    this(this) { duplicate(level); }

    ref Festival opAssign(ref const(Festival) fe)
    {
        if (fe is this)
            return this;
        if (_level.ptr !is null)
            free(_level.ptr);
        duplicate(fe.level);
        owner = fe.owner;
        levelChooser = fe.levelChooser;
        playing = fe.playing;
        update = fe.update;
        return this;
    }

    ~this() { dispose(); }

    void dispose()
    {
        owner = owner.init;
        levelChooser = levelChooser.init;
        playing = playing.init;
        update = update.init;
        if (_level.ptr !is null) {
            free(_level.ptr);
            _level = null;
        }
    }

private:
    void duplicate(const(ubyte[]) toCopy)
    {
        void* p = toCopy.length > 0 ? malloc(toCopy.length) : null;
        if (p is null)
            _level = null;
        else {
            _level = cast (ubyte[]) p[0 .. toCopy.length];
            _level[] = toCopy[];
        }
    }
}

unittest
{
    Festival fe;
    assert(fe.level is null);
    fe.level = cast (immutable(ubyte)[]) "hallo";
    assert(fe.level !is null);
    assert(fe.level.length == 5);

    Festival another = fe;
    assert(fe.level !is another.level);
    assert(fe.level == another.level);

    fe.level = cast (immutable(ubyte)[]) "a";
    fe = fe;
    assert (cast (const(char)[]) fe.level == "a");
    fe = another;
    assert (cast (const(char)[]) fe.level == "hallo");
    fe.dispose;
    assert (fe.level is null);
}
