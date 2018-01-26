module verify.tested;

/*
 * TestedReplay: it's more than a Trophy.
 * This is only concerned with a single replay, not with directory coverage.
 * We get called with a replay filename and perform all the tests.
 */

import std.format;
import enumap;

import file.filename;
import basics.globconf; // add trophy to user's trophy database
import basics.user; // trophy
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

static immutable Enumap!(Status, string) statusDesc = enumap.enumap(
    Status.untested, "bug, this shouldn't ever get printed.",
    Status.multiplayer, "replay ignored, it is multiplayer.",
    Status.noPointer, "replay doesn't name a level file.",
    Status.missingLevel, "replay points to a nonexistant level.",
    Status.badLevel, "replay points to a malformed level.",
    Status.failed, "replay doesn't solve the pointed-to level.",
    Status.mercyKilled, "replay ran over 5 minutes after final skill.",
    Status.solved, "replay solves the pointed-to level.");

class TestedReplay {
private:
    Filename _rpFn; // filename of the replay
    ReplayToLevelMatcher _matcher;
    Level _lv; // may be null, e.g., if noPointer or missingLevel
    Trophy _trophy; // may be null
    Status _status;

public:
    this(Filename fn)
    in { assert (fn); }
    body {
        _rpFn = fn;
        _matcher = new ReplayToLevelMatcher(_rpFn);
        _matcher.forcePointedTo();
        _lv = _matcher.preferredLevel();
        _status = replayFilename == levelFilename ? Status.noPointer
            : _matcher.isMultiplayer              ? Status.multiplayer
            : ! _lv                               ? Status.noPointer
            : ! _lv.good && _lv.nonempty          ? Status.badLevel
            : ! _lv.good                          ? Status.missingLevel
                                                  : Status.untested;
        if (_status != Status.untested)
            return;

        assert (_lv.good);
        // false == disallow saving trophies. If we want trophies, our
        // caller should explicitly tell us maybeAddTrophy() later.
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
        Filename replayFilename() { return _rpFn; }
        Filename levelFilename() { return _matcher.pointedToFilename; }
    }

    override string toString() const
    {
        return format!"%s,%s,%s,%s,%d,%d,%d,%d"(statusWord[_status],
            _rpFn.rootless,
            levelFilename ? levelFilename.rootless : "",
            _matcher.playerLocalOrSmallest.name,
            _trophy ? _trophy.lixSaved : 0, _lv ? _lv.required : 0,
            _trophy ? _trophy.skillsUsed : 0,
            _trophy ? _trophy.phyusUsed : 0);
    }

    // Returns true if we updated the trophy, false if the old was >= ours
    bool maybeAddTrophy()
    {
        if (! solved || userName == ""
                     || userName != _matcher.playerLocalOrSmallest.name)
            return false;
        assert (! _matcher.isMultiplayer);
        return addTrophy(levelFilename, _trophy);
    }
}
