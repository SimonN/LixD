module net.server.festival;

/* A Festival defines what's going on in a room.
 * Only the server knows about festivals.
 * Not about who is in a room, because NetServer._profiles keep track of that.
 *
 * All of Festival is @nogc.
 *
 * Call updatesToSuggestOrZero() often, it suggests to the client the number
 * of physics updates the server would have done. The client can add the
 * client's own lag to see where he should be.
 */

// DTODO: Make the replay known in the network, include in Festival,
// such that (a player who joins during an already-running game)
// gets the correct replay and can jump right into the action.

import core.stdc.stdlib;
import core.time;

import net.structs;
import net.repdata;
import net.packetid : updatesPerSecond;

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
        _gameStart = fe._gameStart;
        _recentSync = fe._recentSync;
        owner = fe.owner;
        levelChooser = fe.levelChooser;
        update = fe.update;
        return this;
    }

    ~this() { dispose(); }

    void dispose()
    {
        endGame();
        owner = owner.init;
        levelChooser = levelChooser.init;
        update = update.init;
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
        assert (! gameRunning);
        _gameStart = MonoTime.currTime;
        _recentSync = MonoTime.currTime;
    }

    void endGame()
    {
        _gameStart = MonoTime.zero;
        _recentSync = MonoTime.zero;
    }

    Update updatesToSuggestOrZero()
    {
        if (! gameRunning
            || MonoTime.currTime - _recentSync < dur!"seconds"(3))
            return Update(0);
        enum oneUpdate = dur!"hnsecs"(10_000_000 / updatesPerSecond);
        auto updatesSinceStart = (MonoTime.currTime - _gameStart) / oneUpdate;
        _recentSync = MonoTime.currTime;
        return Update(updatesSinceStart & 0x7FFF_FFFF);
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
