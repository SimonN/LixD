module game.replay.matcher;

/*
 * There are three levels that a replay might run against:
 *
 * 1. The level included in the replay file.
 * 2. The level pointed to by the $LEVEL_FILENAME line in the replay file.
 * 3. An explicitly given filename or level (we only support filename so far).
 *
 * All levels are constructed lazily.
 *
 * ReplayToLevelMatcher takes a replay filename and computes all the other
 * filenames and levels from there, and offers game creation based on that
 * data. If you want an explicitly given filename with a level to run against,
 * first construct an instance and then call forceLevel() on it.
 */

import enumap;
import optional;

import file.filename;
import game.core.game;
import game.nurse.verify;
import game.replay.replay;
import level.level;

class ReplayToLevelMatcher {
private:
    Replay _rp; // never null
    Filename _fnRp; // never null by constructor contract
    Enumap!(Choice, LevelForChoice) _choices;

    enum Choice { included, pointed, explicit }
    struct LevelForChoice {
        bool forcedByCaller; // used even while (! initialized).
        bool lvMatchesFn; // usually true. False if included -> pointedFn
        Optional!Filename fn; // initialized in constructor or forceLevel
        Level level; // loaded only when necessary
    }

public:
    this(Filename aReplayFn)
    in { assert (aReplayFn); }
    body {
        _fnRp = aReplayFn;
        _rp = Replay.loadFromFile(_fnRp);
        _choices.included.fn = some(_rp.levelFilename.or(_fnRp));
        _choices.pointed.fn = _rp.levelFilename;
        _choices.pointed.lvMatchesFn = true;
    }

    void forcePointedTo() nothrow @nogc @safe
    {
        _choices.pointed.forcedByCaller = true;
        _choices.explicit.forcedByCaller = false;
    }

    void forceLevel(Filename aExpli)
    {
        _choices.pointed.forcedByCaller = false;
        _choices.explicit.forcedByCaller = true;
        _choices.explicit.fn = aExpli;
        _choices.explicit.lvMatchesFn = true;
    }

    @property const(Replay) replay() const @nogc nothrow
    {
        return _rp;
    }

    @property Optional!Filename pointedToFilename() const @nogc nothrow
    {
        return _choices.pointed.fn;
    }

    // DTODONULLABLE: Refactor to Optional!Level.
    // Preferred level may be null, e.g., if force pointed and replay no line.
    // preferredLevel() cannot be inout because it affects the cache.
    Level preferredLevel()
    body { return preferredInitializedStruct.level; }

    @property bool includedIsGood()
    {
        initialize(Choice.included);
        return _choices.included.level && _choices.included.level.playable;
    }

    @property bool pointedToIsGood()
    {
        initialize(Choice.pointed);
        return _choices.pointed.level && _choices.pointed.level.playable;
    }

    @property bool mayCreateGame()
    {
        return preferredLevel.playable
            && (! _rp.empty || ! preferredInitializedStruct.fn.empty);
    }

    Game createGame()
    in {
        // It is illegal to call createGame when the preferred level is bad.
        // Callers should do something reasonable instead.
        assert (mayCreateGame);
    }
    out (ret) { assert (ret); }
    body {
        auto pref = preferredInitializedStruct();
        return _rp.empty
            // pref.fn is nonzero because of in contract
            ? new Game(pref.level, *pref.fn.unwrap)
            : new Game(pref.level, _rp, pref.lvMatchesFn);
    }

    VerifyingNurse createVerifyingNurse()
    in { assert (preferredLevel.playable); }
    out (ret) { assert (ret); }
    body {
        auto pref = preferredInitializedStruct();
        return new VerifyingNurse(pref.level, _rp, pref.lvMatchesFn);
    }

    @property bool isMultiplayer() const @nogc nothrow
    {
        return _rp.numPlayers > 1;
    }

    @property string singleplayerName() const @nogc nothrow
    {
        return _rp.players.length == 1 ? _rp.players.byValue.front.name : "";
    }

private:
    LevelForChoice preferredInitializedStruct()
    {
        Choice ch = _choices.explicit.forcedByCaller ? Choice.explicit
            : _choices.pointed.forcedByCaller ? Choice.pointed
            : includedIsGood ? Choice.included
            : pointedToIsGood ? Choice.pointed
            : Choice.included;
        initialize(ch);
        return _choices[ch];
    }

    void initialize(Choice ch)
    {
        if (_choices[ch].level)
            return;
        final switch (ch) {
        case Choice.included:
            _choices.included.level = new Level(_fnRp);
            if (! _choices.included.fn.empty
                && *_choices.included.fn.unwrap == _fnRp
            ) {
                _choices.included.lvMatchesFn = true;
            }
            else {
                initialize(Choice.pointed);
                _choices.included.lvMatchesFn =
                    _choices.included.level == _choices.pointed.level;
            }
            break;
        case Choice.pointed:
            _choices.pointed.level = _rp.levelFilename.empty ? null
                : new Level(*_rp.levelFilename.unwrap);
            break;
        case Choice.explicit:
            _choices.explicit.level = _choices.explicit.fn.empty ? null
                : new Level(*_choices.explicit.fn.unwrap);
            break;
        }
    }
}

unittest {
    /*
     * Create a replay for the frist level, Any Way You Want.
     * Write a modified Any Way You Want (half the terrain) into the replay.
     * Test that the Matcher detects this difference in the levels.
     * Test that the Matcher loads both levels lazily.
     */
    import basics.alleg5;
    import basics.cmdargs;
    import basics.globals;
    import basics.help;
    import basics.init;
    import file.date;
    import game.replay.io;

    al_run_allegro(delegate int() {
        initializeNoninteractive(Runmode.VERIFY);
        scope (exit)
            deinitializeAfterUnittest();

        Filename repFn = new VfsFilename("replays/unittest-matcher.txt");
        assert (! repFn.fileExists, "leftover unittest garbage");
        scope (exit) {
            repFn.deleteFile();
            assert (! repFn.fileExists, "didn't delete properly");
        }

        assert (fileSingleplayerFirstLevel.fileExists, "need first level");
        Level lv = new Level(fileSingleplayerFirstLevel);
        assert (lv.playable, "first level isn't playable");
        immutable int origTerrain = lv.terrain.len;

        // Change the level that will be written into the replay file
        lv.terrain = lv.terrain[0 .. origTerrain/2];
        immutable int shortTerrain = lv.terrain.len;
        assert (shortTerrain < origTerrain, "first level had no terrain");
        Replay rp = Replay.newForLevel(fileSingleplayerFirstLevel, lv.built);
        rp.implSaveToFile(repFn, lv);
        assert (repFn.fileExists, "couldn't create unittest replay");

        with (ReplayToLevelMatcher.Choice) {
            auto ma = new ReplayToLevelMatcher(repFn);
            assert (! ma._choices[included].level, "we aren't lazy");
            assert (! ma._choices[pointed].level, "we aren't lazy");
            assert (ma.pointedToIsGood);
            assert (! ma._choices[included].level, "shouldn't use included");
            assert (ma._choices[pointed].level, "should use pointed");

            ma = new ReplayToLevelMatcher(repFn);
            Level maLv = ma.preferredLevel();
            assert (maLv, "since Any Way You Want existed, this should exist");
            assert (ma._choices[included].level, "should use included");
            assert (ma._choices[pointed].level, "When we initialize included,"
                ~ " we initialize all of it. In particular, we initialize"
                ~ " included.lvMatchesFn, for which we must analyze pointed."
                ~ " Or do we want another layer of laziness for lvMatchesFn?");
            assert (ma._choices[pointed].lvMatchesFn, "must be by definition");
            assert (! ma._choices[included].lvMatchesFn, "This shouldn't"
                ~ " match because we had shortTerrain < origTerrain.");

            ma = new ReplayToLevelMatcher(repFn);
            ma.forcePointedTo();
            maLv = ma.preferredLevel();
            assert (! ma._choices[included].level, "should ignore included");
        }
        return 0;
    });
}
