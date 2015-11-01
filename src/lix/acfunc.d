module lix.acfunc;

import game;
import lix;

// Mimic behavior of A4/C++ Lix as precisely as possible? Might help testing
// old replays. This flag can be removed after the D port got widespread.
enum cPlusPlusPhysicsBugs = false;

struct UpdateArgs {
    GameState st;
    int       id; // the lix's id, to pass to the effect manager

    this(GameState _st, in int _id = 0) { st = _st; id = _id; }
}

/+
static this()
{
    acFunc[Ac.EXPLODER]  .leaving =
    acFunc[Ac.CUBER]     .leaving = true;
}
+/

// DTODO: Remove these as they get implemented in other files
class Stunner    : PerformedActivity { mixin(CloneByCopyFrom); }
class Lander     : PerformedActivity { mixin(CloneByCopyFrom); }
class Runner     : PerformedActivity { mixin(CloneByCopyFrom); }
class Climber    : PerformedActivity { mixin(CloneByCopyFrom); }
class Ascender   : PerformedActivity { mixin(CloneByCopyFrom); }
class Exploder   : PerformedActivity { mixin(CloneByCopyFrom); }
class Blocker    : PerformedActivity { mixin(CloneByCopyFrom); }
class Builder    : PerformedActivity { mixin(CloneByCopyFrom); }
class Shrugger   : PerformedActivity { mixin(CloneByCopyFrom); }
class Platformer : PerformedActivity { mixin(CloneByCopyFrom); }
class Basher     : PerformedActivity { mixin(CloneByCopyFrom); }
class Miner      : PerformedActivity { mixin(CloneByCopyFrom); }
class Digger     : PerformedActivity { mixin(CloneByCopyFrom); }
class Jumper     : PerformedActivity { mixin(CloneByCopyFrom); }
class Batter     : PerformedActivity { mixin(CloneByCopyFrom); }
class Cuber      : PerformedActivity { mixin(CloneByCopyFrom); }



immutable string CloneByCopyFrom = "
    override typeof(this) clone()
    {
        auto a = new typeof(this)();
        a.copyFrom(this);
        return a;
    }
    alias copyFrom = super.copyFrom;
    private alias lixxie this;
";



abstract class PerformedActivity {

public:

    @property final Ac  ac()      const { return _ac;    }
    @property final int frame()   const { return _frame; }

    @property bool  canPassTop()  const { return false; }
    @property bool  isBlockable() const { return true;  }
    @property bool  isLeaving()   const { return false; }

    @property bool  callBecomeAfterAssignment() const { return true; }

    void onManualAssignment()        { } // while Lix has old performed ac!
    void onBecome()                  { } // after manual ass., still while old
    void performActivity(UpdateArgs) { } // the main method to override
    void onBecomingSomethingElse()   { } // e.g. return leftover builders

    abstract PerformedActivity clone();

    final static typeof(this)
    factory(Lixxie l, Ac newAc)
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

protected:

    void copyFrom(PerformedActivity rhs)
    {
        lixxie = rhs.lixxie;
        _ac    = rhs._ac;
        _frame = rhs._frame;
    }

package:

    @property int frame(in int a)  { return _frame = a; }

    Lixxie lixxie;

private:

    Ac  _ac;
    int _frame;

}



class RemovedLix : PerformedActivity {
    mixin(CloneByCopyFrom);
    override @property bool isLeaving() const { return true; }
}
