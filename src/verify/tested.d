module verify.tested;

/*
 * TestedReplay: it's more than a Trophy.
 * This is only concerned with a single replay, not with directory coverage.
 * We get called with a replay filename and perform all the tests.
 */

import std.format;
import enumap;

import basics.user;
import basics.globconf : userName;
import basics.trophy;
import file.filename;
import level.level;
import game.nurse.verify;
import game.replay;

enum Status {
    untested,
    multiplayer,
    noPointer,
    missingLevel,
    badLevel,
    failed,
    mercyKilled,
    solved
}

static immutable Enumap!(Status, string) statusWord = enumap.enumap(
    Status.untested, "(BUG)",
    Status.multiplayer, "(MULTI)",
    Status.noPointer, "(NO-PTR)",
    Status.missingLevel, "(NO-LEV)",
    Status.badLevel, "(BADLEV)",
    Status.failed, "(FAIL)",
    Status.mercyKilled, "(FAIL-T)",
    Status.solved, "(OK)");

class TestedReplay {
private:
    Filename _rpFn; // filename of the replay
    ReplayToLevelMatcher _matcher;
    Level _lv; // may be null, e.g., if noPointer or missingLevel
    Trophy _trophy; // never null since it's a struct, but may be default-ctord
    Status _status;

public:
    this(Filename fn)
    in { assert (fn); }
    body {
        _rpFn = fn;
        _matcher = new ReplayToLevelMatcher(_rpFn);
        _matcher.forcePointedTo();
        _lv = _matcher.preferredLevel();
        _status = pointsToItself                  ? Status.noPointer
            : _matcher.isMultiplayer              ? Status.multiplayer
            : ! _lv                               ? Status.noPointer
            : _lv.errorFileNotFound               ? Status.missingLevel
            : ! _lv.playable                      ? Status.badLevel
                                                  : Status.untested;
        if (_status != Status.untested)
            return;

        assert (_lv.playable);
        // If we want trophies, caller should tell us maybeAddTrophy() later.
        VerifyingNurse nurse = _matcher.createVerifyingNurse();
        auto eval = nurse.evaluateReplay();
        destroy(nurse);
        _trophy = eval.trophy;
        _status = _trophy.lixSaved >= _lv.required ? Status.solved
                                : eval.mercyKilled ? Status.mercyKilled
                                                   : Status.failed;
    }

    @property const @nogc {
        Status status() { return _status; }
        bool solved() { return _status == Status.solved; }
        auto replayFilename() { return _rpFn; }
        auto levelFilename() { return _matcher.pointedToFilename; }
    }

    override string toString() const
    {
        return format!"%s,%s,%s,%s,%d,%d,%d,%d"(statusWord[_status],
            _rpFn.rootless,
            levelFilename.empty ? "" : levelFilename.unwrap.rootless,
            _matcher.singleplayerName, _trophy.lixSaved,
            _lv ? _lv.required : 0,
            _trophy.skillsUsed, _trophy.phyusUsed);
    }

    // Returns true if we updated the trophy, false if the old was >= ours
    bool maybeAddTrophy()
    {
        if (! solved || userName == ""
                     || userName != _matcher.singleplayerName
                     || levelFilename.empty)
            return false;
        assert (! _matcher.isMultiplayer);
        return _trophy.addToUser(*levelFilename.unwrap);
    }

private:
    @property bool pointsToItself() const
    {
        return levelFilename.empty
            || *levelFilename.unwrap == replayFilename;
    }
}
