module lix.acfunc;

import std.string;
import lix;

// Mimic behavior of A4/C++ Lix as precisely as possible? Might help testing
// old replays. This flag can be removed after the D port got widespread.
enum cPlusPlusPhysicsBugs = false;

template CloneByCopyFrom(string derivedClass) {
    immutable string CloneByCopyFrom = format(
        q{
            override %s
            cloneAndBindToLix(Lixxie lixToBindTo) const
            {
                auto a = new %s();
                a.copyFromAndBindToLix(this, lixToBindTo);
                return a;
            }
            alias copyFromAndBindToLix = super.copyFromAndBindToLix;
            private alias lixxie this;
        },
        derivedClass, derivedClass);
}



abstract class PerformedActivity {

public:

    @property final Ac  ac()    const { return _ac;    }
    @property final int frame() const { return _frame; }

    @property bool canPassTop() const { return false; }
    @property bool blockable()  const { return true;  }
    @property bool leaving()    const { return false; }

    @property bool callBecomeAfterAssignment() const { return true; }

    void onManualAssignment()      { } // while Lix has old performed ac!
    void onBecome()                { } // initialization, still while old
    void performActivity()         { } // the main method to override
    void onBecomingSomethingElse() { } // tribe to, e.g., return builders

    abstract PerformedActivity cloneAndBindToLix(Lixxie) const;

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

    void copyFromAndBindToLix(in PerformedActivity rhs, Lixxie bindTo)
    {
        lixxie = bindTo;
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
