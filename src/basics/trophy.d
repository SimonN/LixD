module basics.trophy;

import file.date;
import net.phyu;

struct Trophy {
    MutableDate built;
    int lixSaved;
    int skillsUsed;
    Phyu phyusUsed;

    this(Date aDate) { built = aDate; }
    this(string aDate, int aLixSaved, int aSkillsUsed, int aPhyusUsed)
    {
        built = new Date(aDate);
        lixSaved = aLixSaved;
        skillsUsed = aSkillsUsed;
        phyusUsed = Phyu(aPhyusUsed);
    }

    enum Cmp {
        noSameBuildWorsePlay, // same map version, equal/worse play than old
        maybeOlderBuilt, // on older map version, only save during interactive
        yesNewerBuilt, // we played on a newer map version, probably save us
        yesSameBuildBetterPlay, // we improved old trophy on same map version
    }

    bool shouldReplaceDuringUserDataLoad(ref const(Trophy) rhs) const
    {
        return this.shouldReplace(rhs) >= Cmp.yesNewerBuilt;
    }

    bool shouldReplaceAfterPlay(ref const(Trophy) rhs) const
    {
        return this.shouldReplace(rhs) >= Cmp.maybeOlderBuilt;
    }

    Cmp shouldReplace(ref const(Trophy) rhs) const
    {
        Date d1 = built; // workaround opEquals unnaturality in struct wrapper
        Date d2 = rhs.built;
        if (d1 == d2) {
            const b = lixSaved != rhs.lixSaved ? lixSaved > rhs.lixSaved
                :  skillsUsed != rhs.skillsUsed ? skillsUsed < rhs.skillsUsed
                :  phyusUsed < rhs.phyusUsed; // equal treated as worse.
            return b ? Cmp.yesSameBuildBetterPlay : Cmp.noSameBuildWorsePlay;
        }
        else
            return built > rhs.built ? Cmp.yesNewerBuilt : Cmp.maybeOlderBuilt;
    }

    unittest {
        auto a = typeof(this)(Date.now());
        auto b = typeof(this)(a.built);
        a.lixSaved = 4;
        b.lixSaved = 5;
        assert (b.shouldReplaceAfterPlay(a));
        b.lixSaved = 4;
        assert (! b.shouldReplaceAfterPlay(a));
        b.phyusUsed = 1;
        assert (a.shouldReplaceAfterPlay(b));
    }
}
