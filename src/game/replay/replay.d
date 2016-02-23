module game.replay.replay;

import core.stdc.string; // memmove
import std.algorithm; // isSorted

import basics.help; // array.len of type int
import basics.globconf;
import basics.help;
import basics.nettypes;
import basics.versioning;
import game.replay.io;
import file.date;
import file.filename;
import level.level;
import level.metadata;
import lix.enums;

class Replay {
    static struct Player {
        PlNr   number;
        Style  style;
        string name;
    }

package:
    bool _fileNotFound;
    Version _gameVersionRequired;
    Player[] _players;
    Permu _permu;
    ReplayData[] _data;

public:
    Date     levelBuiltRequired;
    Filename levelFilename;
    PlNr     playerLocal;

    static newForLevel(Filename levFn, Date levBuilt)
    {
        return new this(levFn, levBuilt, null);
    }

    static loadFromFile(Filename loadFrom)
    {
        return new this(null, null, loadFrom);
    }

    auto clone() const { return new Replay(this); }
    this(in typeof(this) rhs)
    {
        _fileNotFound        = rhs._fileNotFound;
        _gameVersionRequired = rhs._gameVersionRequired;

        levelBuiltRequired   = rhs.levelBuiltRequired;
        levelFilename        = rhs.levelFilename ? rhs.levelFilename.clone() : null; // DTODO: make filename immutable
        playerLocal          = rhs.playerLocal;

        _players             = rhs._players.dup;
        _permu               = rhs._permu.clone();
        _data                = rhs._data.dup;
    }

private:
    this(Filename levFn, Date levBuilt, Filename loadFrom)
    {
        touch();
        levelFilename = levFn ? levFn : nullFilename;
        _permu        = new Permu(1);

        // This is a hack, expecting only one immutable member in (this).
        // That's why we can set it via return value.
        // Once I make more members proprely immutable, I need to improve this.
        if (loadFrom)
            levelBuiltRequired = this.implLoadFromFile(loadFrom);
        else
            levelBuiltRequired = levBuilt;
    }

public:
    @property fileNotFound() const        { return _fileNotFound;        }
    @property gameVersionRequired() const { return _gameVersionRequired; }

    @property const(Player)[] players() const  { return _players;      }
    @property const(Permu)    permu()   const  { return _permu;        }
    @property       Permu     permu(Permu p)   { _permu = p; return p; }

    @property int latestUpdate() const
    {
        return (_data.length > 0) ? _data[$-1].update : 0;
    }

    @property string playerLocalName() const
    {
        foreach (pl; _players)
            if (pl.number == playerLocal)
                return pl.name;
        return null;
    }

    void touch()
    {
        _gameVersionRequired = gameVersion();
        _fileNotFound = false;
    }

    void addPlayer(PlNr nr, Style s, string name)
    {
        _players ~= Player(nr, s, name);
    }

    // This doesn't check whether the metadata/general data is the same.
    // We assume that Game only calls this on replays of the same level.
    bool isSubsetOf(in Replay rhs) const
    {
        assert (rhs !is null);
        return _data.length <= rhs._data.length
            && _data[]      == rhs._data[0 .. this._data.length];
    }

    // this function is necessary to keep old replays working in new versions
    // that skip the first 30 or so updates, to get into the action faster.
    // The first spawn is still at update 60.
    void increaseEarlyDataToUpdate(in Update upd)
    {
        foreach (d; _data) {
            if (d.update < upd)
                d.update = upd;
            else break;
        }
        // This doesn't call touch().
    }

    void eraseEarlySingleplayerNukes()
    {
        // Game updates nukes, then spawns, then lix perform.
        enum beforeUpdate = 61; // Not 60, only nuke if it kills lix.
        if (_players.length > 1)
            return;
        for (int i = 0; i < _data.length; ++i) {
            if (_data[i].update >= beforeUpdate)
                break;
            else if (_data[i].action == RepAc.NUKE) {
                _data = _data[0 .. i] ~ _data[i+1 .. $];
                --i;
            }
        }
        // doesn't call touch(), because it's housekeeping
    }

    void deleteAfterUpdate(in Update upd)
    {
        assert (upd >= 0);
        _data = _data[0 .. dataSliceBeforeUpdate(Update(upd + 1)).length];
        touch();
    }

    const(ReplayData)[] getDataForUpdate(in Update upd) const
    {
        auto slice = dataSliceBeforeUpdate(Update(upd + 1));
        int firstGood = slice.len;
        while (firstGood > 0 && slice[firstGood - 1].update == upd)
            --firstGood;
        assert (firstGood >= 0);
        assert (firstGood <= slice.length);
        return _data[firstGood .. slice.length];
    }

    bool getOnUpdateLixClicked(in Update upd, in int lix_id, in Ac ac) const
    {
        auto vec = getDataForUpdate(upd);
        foreach (const ref d; vec)
            if (d.isSomeAssignment && d.toWhichLix == lix_id && d.skill == ac)
                return true;
        return false;
    }

    void add(in ReplayData d)
    {
        touch();
        this.addWithoutTouching(d);
    }

    void saveAsAutoReplay(in Filename levelFn, in Level lev, bool solves) const
    {
        this.implSaveAsAutoReplay(levelFn, lev, solves);
    }

    void saveManually(in Filename levelFn, in Level lev) const
    {
        this.implSaveManually(levelFn, lev);
    }

package:
    inout(ReplayData)[] dataSliceBeforeUpdate(in Update upd) inout
    {
        // The binary search algo works also for this case.
        // But we add mostly to the end of the data, so check here for speed.
        if (_data.length == 0 || _data[$-1].update < upd)
            return _data;

        int bot = 0;         // first too-large is at a higher position
        int top = _data.len; // first too-large is here or at a lower position

        while (top != bot) {
            int bisect = (top + bot) / 2;
            assert (bisect >= 0   && bisect < _data.len);
            assert (bisect >= bot && bisect < top);
            if (_data[bisect].update < upd)
                bot = bisect + 1;
            if (_data[bisect].update >= upd)
                top = bisect;
        }
        return _data[0 .. bot];
    }

    void addWithoutTouching(in ReplayData d)
    {
        // Add after the latest record that's smaller than or equal to d
        // Equivalently, add before the earliest record that's greater than d.
        // dataSliceBeforeUpdate doesn't do exactly that, it ignores players.
        // DTODO: I believe the C++ version had a bug in the choice of
        // comparison. I have fixed that here. Test to see if it's good now.
        auto slice = dataSliceBeforeUpdate(Update(d.update + 1));
        while (slice.length && slice[$-1] > d)
            slice = slice[0 .. $-1];
        if (slice.length < _data.length) {
            _data.length += 1;
            memmove(&_data[slice.length + 1], &_data[slice.length],
                    ReplayData.sizeof * (_data.length - slice.length - 1));
            _data[slice.length] = d;
        }
        else {
            _data ~= d;
        }
        assert (_data.isSorted);
    }
}
