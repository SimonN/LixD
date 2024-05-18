module game.nurse.verify;

import file.trophy;
import game.nurse.base;

class VerifyingNurse : Nurse {
private:
    bool _maySaveTrophy;
    int _required;

public:
    struct EvalResult {
        HalfTrophy halfTrophy;
        int phyusUsed;
        bool mercyKilled; // replay took too long after last assign before win
    }

    this(in Level lev, Replay rp, in bool maySaveTrophy)
    {
        super(lev, rp, new NullEffectSink);
        _maySaveTrophy = maySaveTrophy;
        _required = lev.required;
    }

    EvalResult evaluateReplay()
    in {
        assert (model);
        assert (replay);
        assert (cs.isPuzzle, "Don't evaluate battle replays.");
    }
    do {
        bool mercyKilled = false;
        while (! everybodyOutOfLix && ! cs.isSolvedPuzzle(_required)) {
            updateOnce();
            // allow 5 minutes after the last replay data before cancelling
            if (now >= replay.latestPhyu + 5 * (60 * 15)) {
                mercyKilled = true;
                break;
            }
        }
        return EvalResult(
            trophyForTribe(cs.tribes.theSingleTribe.style), now, mercyKilled);
    }
}
