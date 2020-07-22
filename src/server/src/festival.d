module net.server.festival;

/* A Festival defines what's going on in a room.
 * Only the server knows about festivals.
 * Not about who is in a room, because NetServer._profiles keep track of that.
 *
 * All of Festival is @nogc.
 *
 * Call updatesToSuggestOrZero() often, it suggests to the client the time
 * in milliseconds that has passed since game start. Festival doesn't know
 * how fast physics update. The client can add the client's own lag to
 * see where he should be.
 */

// DTODO: Make the replay known in the network, include in Festival,
// such that (a player who joins during an already-running game)
// gets the correct replay and can jump right into the action.

import core.stdc.stdlib;
import core.time;

import net.structs;

package:

struct Festival {
@nogc:
private:
    ubyte[] _level; // send this data to new-joiners. Manually memory-managed.
    MonoTime _gameStart;
    MonoTime _recentSync;

public:
    PlNr owner; // creator of the room, I plan that he shall kick others
    PlNr levelChooser; // who has chosen the most recent level?

    @property const(ubyte)[] level() const { return _level; }
    @property void level(const(ubyte[]) toCopy)
    {
        if (_level.ptr !is null)
            free(_level.ptr);
        duplicate(toCopy);
    }

    @disable this(const(void)[]); // instead, copy-construct and assign level

    this(this) { duplicate(level); }

    ref Festival opAssign(ref const(Festival) fe) return
    {
        if (fe is this)
            return this;
        if (_level.ptr !is null)
            free(_level.ptr);
        duplicate(fe.level);
        _gameStart = fe._gameStart;
        _recentSync = fe._recentSync;
        owner = fe.owner;
        levelChooser = fe.levelChooser;
        return this;
    }

    ~this() { dispose(); }

    void dispose()
    {
        endGame();
        _gameStart = MonoTime.zero;
        _recentSync = MonoTime.zero;
        owner = owner.init;
        levelChooser = levelChooser.init;
        if (_level.ptr !is null) {
            free(_level.ptr);
            _level = null;
        }
    }

    @property bool gameRunning() const
    {
        return _gameStart != MonoTime.zero;
    }

    void startGame()
    {
        // DTODONETWORK: Implement something that calls endGame.
        // Then assert (! gameRunning) here in startGame().
        _gameStart = MonoTime.currTime;
        _recentSync = MonoTime.currTime;
    }

    void endGame()
    {
        _gameStart = MonoTime.zero;
        _recentSync = MonoTime.zero;
    }

    int millisecondsSinceGameStartOrZero()
    {
        if (! tellMillisecondsSinceGameStartNow)
            return 0;
        immutable ret = (MonoTime.currTime - _gameStart) / dur!"msecs"(1);
        _recentSync = MonoTime.currTime;
        return ret & 0x7FFF_FFFF;
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

    bool tellMillisecondsSinceGameStartNow() const
    {
        if (! gameRunning)
            return false;
        if (MonoTime.currTime - _gameStart <= dur!"seconds"(5))
            return MonoTime.currTime - _recentSync >= dur!"msecs"(500);
        else
            return MonoTime.currTime - _recentSync >= dur!"seconds"(5);
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

    fe._gameStart  = MonoTime.zero + dur!"msecs"(  1);
    fe._recentSync = MonoTime.zero + dur!"msecs"(600);
    assert (fe.millisecondsSinceGameStartOrZero >  0);
    assert (fe.millisecondsSinceGameStartOrZero == 0);

    fe.dispose;
    assert (fe.level is null);
}
