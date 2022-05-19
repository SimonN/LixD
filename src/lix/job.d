module lix.job;

/* The Job hierarchy. What does a Lixxie do?
 *
 * Usage:
 * Mix (CloneByCopyFrom!"SubclassName") into every subclass.
 *
 * Only ever create new Jobs by JobUnion.this(Ac). Reason:
 * Jobs will sometimes be copied by value. This is done by assigning JobUnions.
 * That's even deemed okay from within the Job hierarchy, implicitly relying
 * on the extra space in JobUnion after a potentially shorter class.
 */

import std.algorithm;
import std.conv : to;
import std.string;
import physics.tribe; // interface for returnSkills
import lix;

package enum AfterAssignment : ubyte {
    becomeNormally,
    doNotBecome,
    weAlreadyBecame,
}

abstract class Job {
private:
    Ac  _ac;
    byte _frame;
    byte _spriteOffsetX;

public:
    // lixxie: This should be package, but it must be public to be callable
    // from either std.conv.emplace or my workaround basics.emplace.emplace
    // since DMD 2.077.
    // Therefore: Take care! If you're unsure whether the Job is attached to a
    // lix, don't call lixxie(), it would then point into random memory!
    inout(Lixxie) lixxie() inout @system
    in {
        assert (this !is null);
        void* lixVoid = cast (void*) this - Lixxie.jobOffset;
        assert (lixVoid !is null);
        const(Lixxie) lix = cast (const(Lixxie)) lixVoid;
        assert (lix !is null);
        assert (lix.job is this);
    }
    do {
        return cast (inout(Lixxie)) (cast (void*) this - Lixxie.jobOffset);
    }

    @property final ac()            const pure { return _ac;            }
    @property final frame()         const pure { return _frame;         }
    @property final spriteOffsetX() const pure { return _spriteOffsetX; }

    @property PhyuOrder updateOrder() const { return PhyuOrder.peaceful; }
    @property bool      blockable()   const { return true; }

    AfterAssignment onManualAssignment(Job)
    {
        // We have the new job, maybe temporarily. arg = mutable old job.
        return AfterAssignment.becomeNormally;
    }

    void onBecome(in Job) { } // we have definitely new job, arg = old
    void perform()        { } // the main method to override
    void returnSkillsDontCallLixxieInHere(Tribe) { } // see Lixxie.perform why

protected:
    // Private member functions might return this enum to notify caller, who
    // should be be perform() or another private member function, whether
    // we have already become something else, and therefore should not clobber
    // our fields because we're a JobUnion.
    enum BecomeCalled : bool {
        no = false,
        yes = true,
    }

package:
    @property int frame        (in int a) { return _frame        = a.to!byte; }
    @property int spriteOffsetX(in int a) { return _spriteOffsetX= a.to!byte; }
}

mixin template JobChild() {
    static assert (__traits(classInstanceSize, typeof(this))
        <= JobUnion.sizeof, "Child class of Job doesn't fit into JobUnion. "
            ~ "Enlarge JobUnion or pack the bits of child classes.");
    private alias lixxie this;
}

unittest {
    JobUnion job;
    assert (! job.valid);
    job = JobUnion(Ac.floater);
    assert (job.asClass.ac == Ac.floater,
        "JobUnion.init should be Ac.nothing");
}

struct JobUnion {
    ubyte[32] data; // make as small as you can! fit into one cache line

    inout(Job) asClass() inout return pure
    {
        return cast (inout(Job)) data.ptr;
    }

    bool valid() const { return data[0..8].any; /* contains a vtable ptr */ }

    static bool healthy(in Ac ac)
    out (ret) {
        JobUnion job = JobUnion(ac);
        if (! ret)
            assert (ac == Ac.nothing || cast (Leaver) job.asClass,
                format!"healthy(%s) == false, but should be true"(ac));
        else
            assert (null is cast (Leaver) job.asClass,
                format!"healthy(%s) == true, but should be false"(ac));
    }
    do {
        return ac != Ac.nothing && ac != Ac.splatter && ac != Ac.burner
            && ac != Ac.drowner && ac != Ac.imploder && ac != Ac.exploder
            && ac != Ac.exiter  && ac != Ac.cuber;
    }

    this(in Ac ac) {
        import basics.emplace; // work around segfault in Lix on dmd 2.077
        final switch (ac) {
            case Ac.nothing:    emplace!RemovedLix(data[]); break;
            case Ac.faller:     emplace!Faller(data[]);     break;
            case Ac.tumbler:    emplace!Tumbler(data[]);    break;
            case Ac.stunner:    emplace!Stunner(data[]);    break;
            case Ac.lander:     emplace!Lander(data[]);     break;
            case Ac.splatter:   emplace!Splatter(data[]);   break;
            case Ac.burner:     emplace!Burner(data[]);     break;
            case Ac.drowner:    emplace!Drowner(data[]);    break;
            case Ac.exiter:     emplace!Exiter(data[]);     break;
            case Ac.walker:     emplace!Walker(data[]);     break;

            case Ac.runner:     emplace!Runner(data[]);     break;
            case Ac.climber:    emplace!Climber(data[]);    break;
            case Ac.ascender:   emplace!Ascender(data[]);   break;
            case Ac.floater:    emplace!Floater(data[]);    break;
            case Ac.imploder:   emplace!Imploder(data[]);   break;
            case Ac.exploder:   emplace!Exploder(data[]);   break;
            case Ac.blocker:    emplace!Blocker(data[]);    break;
            case Ac.builder:    emplace!Builder(data[]);    break;
            case Ac.shrugger:   emplace!Shrugger(data[]);   break;
            case Ac.platformer: emplace!Platformer(data[]); break;
            case Ac.shrugger2:  emplace!Shrugger(data[]);   break;
            case Ac.basher:     emplace!Basher(data[]);     break;
            case Ac.miner:      emplace!Miner(data[]);      break;
            case Ac.digger:     emplace!Digger(data[]);     break;

            case Ac.jumper:     emplace!Jumper(data[]);     break;
            case Ac.batter:     emplace!Batter(data[]);     break;
            case Ac.cuber:      emplace!Cuber(data[]);      break;
            case Ac.max: assert (false);
        }
        assert (asClass.ac == Ac.nothing);
        asClass._ac = ac;
    }
}
