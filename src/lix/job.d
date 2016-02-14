module lix.job;

import std.string;
import lix;

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

abstract class Job {
package:
    Lixxie lixxie;

private:
    Ac  _ac;
    int _frame;
    int _spriteOffsetX;

public:
    @property final Ac  ac()            const { return _ac;            }
    @property final int frame()         const { return _frame;         }
    @property final int spriteOffsetX() const { return _spriteOffsetX; }

    @property UpdateOrder updateOrder() const { return UpdateOrder.peaceful; }
    @property bool        blockable()   const { return true; }

    @property bool callBecomeAfterAssignment() const { return true; }

    void onManualAssignment()      { } // while Lix has old performed ac!
    void onBecome()                { } // initialization, still while old
    void perform()                 { } // the main method to override
    void onBecomingSomethingElse() { } // tribe to, e.g., return builders

    abstract Job cloneAndBindToLix(Lixxie) const;

    final static typeof(this)
    factory(Lixxie l, Ac newAc)
    {
        assert (l, "can't instantiate for a null lix");
        typeof(this) newJob;
        final switch (newAc) {
            case Ac.nothing:    newJob = new RemovedLix(); break;
            case Ac.faller:     newJob = new Faller();     break;
            case Ac.tumbler:    newJob = new Tumbler();    break;
            case Ac.stunner:    newJob = new Stunner();    break;
            case Ac.lander:     newJob = new Lander();     break;
            case Ac.splatter:   newJob = new Splatter();   break;
            case Ac.burner:     newJob = new Burner();     break;
            case Ac.drowner:    newJob = new Drowner();    break;
            case Ac.exiter:     newJob = new Exiter();     break;
            case Ac.walker:     newJob = new Walker();     break;

            case Ac.runner:     newJob = new Runner();     break;
            case Ac.climber:    newJob = new Climber();    break;
            case Ac.ascender:   newJob = new Ascender();   break;
            case Ac.floater:    newJob = new Floater();    break;
            case Ac.exploder:   newJob = new Imploder();   break;
            case Ac.exploder2:  newJob = new Exploder();   break;
            case Ac.blocker:    newJob = new Blocker();    break;
            case Ac.builder:    newJob = new Builder();    break;
            case Ac.shrugger:   newJob = new Shrugger();   break;
            case Ac.platformer: newJob = new Platformer(); break;
            case Ac.shrugger2:  newJob = new Shrugger();   break;
            case Ac.basher:     newJob = new Basher();     break;
            case Ac.miner:      newJob = new Miner();      break;
            case Ac.digger:     newJob = new Digger();     break;

            case Ac.jumper:     newJob = new Jumper();     break;
            case Ac.batter:     newJob = new Batter();     break;
            case Ac.cuber:      newJob = new Cuber();      break;
            case Ac.max:        assert (false);
        }
        newJob.lixxie = l;
        newJob._ac    = newAc;
        return newJob;
    }

protected:
    void copyFromAndBindToLix(in Job rhs, Lixxie bindTo)
    {
        lixxie         = bindTo;
        _ac            = rhs._ac;
        _frame         = rhs._frame;
        _spriteOffsetX = rhs._spriteOffsetX;
    }

package:
    @property int frame        (in int a) { return _frame = a; }
    @property int spriteOffsetX(in int a)
    {
        _spriteOffsetX = a;
        lixxie.repositionSprite();
        return a;
    }
}
