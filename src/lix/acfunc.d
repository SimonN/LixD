module lix.acfunc;

import game;
import lix;
import hardware.sound;

struct UpdateArgs {
    GameState st;
    int       id; // the lix's id, to pass to the effect manager

    this(GameState _st, in int _id = 0) { st = _st; id = _id; }
}


/+
static this()
{
    acFunc[Ac.CLIMBER]   .blockable =
    acFunc[Ac.ASCENDER]  .blockable =
    acFunc[Ac.BLOCKER]   .blockable =
    acFunc[Ac.EXPLODER]  .blockable =
    acFunc[Ac.BATTER]    .blockable =
    acFunc[Ac.CUBER]     .blockable = false;

    acFunc[Ac.NOTHING]   .leaving =
    acFunc[Ac.SPLATTER]  .leaving =
    acFunc[Ac.BURNER]    .leaving =
    acFunc[Ac.DROWNER]   .leaving =
    acFunc[Ac.EXITER]    .leaving =
    acFunc[Ac.EXPLODER]  .leaving =
    acFunc[Ac.CUBER]     .leaving = true;

    acFunc[Ac.SPLATTER]  .soundBecome = Sound.SPLAT;
    acFunc[Ac.BURNER]    .soundBecome = Sound.FIRE;
    acFunc[Ac.DROWNER]   .soundBecome = Sound.WATER;
}
+/

// DTODO: Remove these as they get implemented in other files
class RemovedLix : PerformedActivity { }
class Stunner : PerformedActivity { }
class Lander : PerformedActivity { }
class Splatter : PerformedActivity { }
class Burner : PerformedActivity { }
class Drowner : PerformedActivity { }
class Exiter : PerformedActivity { }

class Walker : PerformedActivity { }
class Runner : PerformedActivity { }
class Climber : PerformedActivity { }
class Ascender : PerformedActivity { }
class Exploder : PerformedActivity { }
class Blocker : PerformedActivity { }
class Builder : PerformedActivity { }
class Shrugger : PerformedActivity { }
class Platformer : PerformedActivity { }
class Basher : PerformedActivity { }
class Miner : PerformedActivity { }
class Digger : PerformedActivity { }

class Jumper : PerformedActivity { }
class Batter : PerformedActivity { }
class Cuber : PerformedActivity { }



abstract class PerformedActivity {

    @property Ac    ac()          const { return _ac; }
    @property bool  canPassTop()  const { return false; }
    @property bool  isBlockable() const { return true;  }
    @property bool  isLeaving()   const { return false; }
    @property Sound soundBecome() const { return Sound.ASSIGN; }

    void onManualAssignment()        { } // while Lix has old performed ac!
    void performActivity(UpdateArgs) { } // the main method to override
    void onBecomingSomethingElse()   { } // e.g. return leftover builders

    package Lixxie lixxie;
    private Ac     _ac;

    final static typeof(this) factory(Lixxie l, Ac newAc)
    {
        assert (l, "can't instantiate for a null lix");
        typeof(this) newPerf;
        final switch (newAc) {
            case Ac.NOTHING:    newPerf = new RemovedLix(); break;
            case Ac.FALLER:     newPerf = new Faller();     break;
            case Ac.TUMBLER:    newPerf = new Tumbler();    break;
            case Ac.STUNNER:    newPerf = new Stunner();    break;
            case Ac.LANDER:     newPerf = new Lander();     break;
            case Ac.SPLATTER:   newPerf = new Splatter();   break;
            case Ac.BURNER:     newPerf = new Burner();     break;
            case Ac.DROWNER:    newPerf = new Drowner();    break;
            case Ac.EXITER:     newPerf = new Exiter();     break;
            case Ac.WALKER:     newPerf = new Walker();     break;

            case Ac.RUNNER:     newPerf = new Runner();     break;
            case Ac.CLIMBER:    newPerf = new Climber();    break;
            case Ac.ASCENDER:   newPerf = new Ascender();   break;
            case Ac.FLOATER:    newPerf = new Floater();    break;
            case Ac.EXPLODER:   newPerf = new Exploder();   break;
            case Ac.EXPLODER2:  newPerf = new Exploder();   break;
            case Ac.BLOCKER:    newPerf = new Blocker();    break;
            case Ac.BUILDER:    newPerf = new Builder();    break;
            case Ac.SHRUGGER:   newPerf = new Shrugger();   break;
            case Ac.PLATFORMER: newPerf = new Platformer(); break;
            case Ac.SHRUGGER2:  newPerf = new Shrugger();   break;
            case Ac.BASHER:     newPerf = new Basher();     break;
            case Ac.MINER:      newPerf = new Miner();      break;
            case Ac.DIGGER:     newPerf = new Digger();     break;

            case Ac.JUMPER:     newPerf = new Jumper();     break;
            case Ac.BATTER:     newPerf = new Batter();     break;
            case Ac.CUBER:      newPerf = new Cuber();      break;
            case Ac.MAX:        assert (false);
        }
        newPerf.lixxie = l;
        newPerf._ac    = newAc;
        return newPerf;
    }
}
