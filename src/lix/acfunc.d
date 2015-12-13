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

    @property final Ac  ac()            const { return _ac;            }
    @property final int frame()         const { return _frame;         }
    @property final int spriteOffsetX() const { return _spriteOffsetX; }

    @property UpdateOrder updateOrder() const { return UpdateOrder.peaceful; }
    @property bool        blockable()   const { return true; }

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
            case Ac.nothing:    newPerf = new RemovedLix(); break;
            case Ac.faller:     newPerf = new Faller();     break;
            case Ac.tumbler:    newPerf = new Tumbler();    break;
            case Ac.stunner:    newPerf = new Stunner();    break;
            case Ac.lander:     newPerf = new Lander();     break;
            case Ac.splatter:   newPerf = new Splatter();   break;
            case Ac.burner:     newPerf = new Burner();     break;
            case Ac.drowner:    newPerf = new Drowner();    break;
            case Ac.exiter:     newPerf = new Exiter();     break;
            case Ac.walker:     newPerf = new Walker();     break;

            case Ac.runner:     newPerf = new Runner();     break;
            case Ac.climber:    newPerf = new Climber();    break;
            case Ac.ascender:   newPerf = new Ascender();   break;
            case Ac.floater:    newPerf = new Floater();    break;
            case Ac.exploder:   newPerf = new Imploder();   break;
            case Ac.exploder2:  newPerf = new Exploder();   break;
            case Ac.blocker:    newPerf = new Blocker();    break;
            case Ac.builder:    newPerf = new Builder();    break;
            case Ac.shrugger:   newPerf = new Shrugger();   break;
            case Ac.platformer: newPerf = new Platformer(); break;
            case Ac.shrugger2:  newPerf = new Shrugger();   break;
            case Ac.basher:     newPerf = new Basher();     break;
            case Ac.miner:      newPerf = new Miner();      break;
            case Ac.digger:     newPerf = new Digger();     break;

            case Ac.jumper:     newPerf = new Jumper();     break;
            case Ac.batter:     newPerf = new Batter();     break;
            case Ac.cuber:      newPerf = new Cuber();      break;
            case Ac.max:        assert (false);
        }
        newPerf.lixxie = l;
        newPerf._ac    = newAc;
        return newPerf;
    }

protected:

    void copyFromAndBindToLix(in PerformedActivity rhs, Lixxie bindTo)
    {
        lixxie         = bindTo;
        _ac            = rhs._ac;
        _frame         = rhs._frame;
        _spriteOffsetX = rhs._spriteOffsetX;
    }

package:

    @property int spriteOffsetX(in int a) { return _spriteOffsetX = a; }
    @property int frame        (in int a) { return _frame = a;         }

    Lixxie lixxie;

private:

    Ac  _ac;
    int _frame;
    int _spriteOffsetX;

}
