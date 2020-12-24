module verify.tested;

/*
 * TestedReplay: it's more than a Trophy.
 * This is only concerned with a single replay, not with directory coverage.
 * We get called with a replay filename and perform all the tests.
 */

public import optional;

import std.algorithm;
import std.format;
import enumap;

import file.option;
import file.option : userName;
import file.date;
import file.filename;
import file.trophy;
import level.level;
import game.nurse.verify;
import menu.repmatch;

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
    Optional!Level _lv; // may be none, e.g., if noPointer or missingLevel
    Trophy _trophy; // Always has _lv's built. If _lv is none: random built.
    Status _status;
    int _phyusUsed;

public:
    this(Filename fn)
    in { assert (fn); }
    do {
        _rpFn = fn;
        _matcher = new ReplayToLevelMatcher(_rpFn);
        _matcher.forcePointedTo();
        _lv = _matcher.preferredLevel();
        _trophy = levelFilename.match!(
            () => Trophy(_lv.oc.built.frontOr(Date.now), ""),
            (lfn) => Trophy(_lv.oc.built.frontOr(Date.now), lfn));
        _status = pointsToItself ? Status.noPointer
            : _matcher.isMultiplayer ? Status.multiplayer
            : _lv.empty ? Status.noPointer
            : _lv.front.errorFileNotFound ? Status.missingLevel
            : ! _lv.front.playable ? Status.badLevel
            : Status.untested;
        if (_status != Status.untested) {
            return;
        }
        assert (_lv.any!(l => l.playable));
        // If we want trophies, caller should tell us maybeAddTrophy() later.
        VerifyingNurse nurse = _matcher.createVerifyingNurse();
        auto eval = nurse.evaluateReplay();
        destroy(nurse);

        _trophy.copyFrom(eval.halfTrophy);
        _phyusUsed = eval.phyusUsed;
        _status = _trophy.lixSaved >= _lv.front.required ? Status.solved
            : eval.mercyKilled ? Status.mercyKilled : Status.failed;
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
            levelFilename.oc.rootless.frontOr(""),
            _matcher.singleplayerName, _trophy.lixSaved,
            _lv.empty ? 0 : _lv.front.required,
            _trophy.skillsUsed, _phyusUsed);
    }

    // Returns true if we updated the trophy, false if the old was >= ours
    bool maybeAddTrophy()
    {
        if (! solved || userName == ""
                     || userName != _matcher.singleplayerName
                     || levelFilename.empty)
            return false;
        assert (! _lv.empty);
        assert (! _matcher.isMultiplayer);
        TrophyKey key;
        key.fileNoExt = _matcher.pointedToFilename.oc
            .fileNoExtNoPre.frontOr("");
        key.title = _lv.oc.name.frontOr("");
        key.author = _lv.oc.author.frontOr("");
        return maybeImprove(key, _trophy);
    }

private:
    @property bool pointsToItself() const
    {
        return levelFilename.all!(fn => fn == replayFilename);
    }
}
