module file.trophy.trophy;

import file.date;
import file.filename;
import net.phyu;

/*
 * A basename is the directory-independent part of a full filename.
 * Example: "levels/dir/mylevel.txt" has basename "mylevel.txt".
 * fileNoExt is a basename without (the extension including the dot).
 * Example: "levels/dir/mylevel.txt" has fileNoExt "mylevel".
 *
 * Trophy-to-level matching rule:
 * A trophy in the SDLang format matches by fileNoExt + English title + author;
 * all 3 fields must be equal between level and trophy, as long as the trophy's
 * title or author are nonempty.
 * If trophy's title and author are both empty, a trophy matches a level
 * if both have the same fileNoExt.
 *
 * Reasons: A trophy from the 2006-2017 IoLine format matched by exact filename
 * that is lastDir + fileNoExt + ".txt". These trophies were converted to
 * SDLang trophies by adding empty level title and empty author.
 * Matching only by fileNoExt might produce extra matches, but that's fine:
 * Levels should be allowed to move freely in the tree. The 2018-09 level tree
 * has no duplicate basenames in the singleplayer directory, and we shouldn't
 * save trophies for multiplayer levels anyway.
 *
 * It's good to match by fileNoExt first, and only open level files when
 * the trophy might be about several different files with same fileNoExt.
 */

struct TrophyKey {
    string fileNoExt; // "levels/dir/mylevel.txt" has fileNoExt "mylevel"
    string title; // title means always English. Not: translatedTitle
    string author; // level author, in case two authors make unrelated levels
}

struct HalfTrophy { // Only for passing info from Nurse to the menu
    int lixSaved;
    int skillsUsed;
}

struct Trophy {
    int lixSaved;
    int skillsUsed;
    MutableDate built;
    MutFilename lastDir; // including leading "levels/" not written to SDLang

    @disable this(); // always construct with a valid date

    this(Date aDate, Filename aLastDir) // Use this constructor if possible.
    {
        built = aDate;
        lastDir = aLastDir.guaranteedDirOnly;
    }

    this(Date aDate) // Avoid this constructor. Maybe refactor.
    {
        built = aDate;
        lastDir = new VfsFilename("");
    }

    void copyFrom(HalfTrophy ht)
    {
        lixSaved = ht.lixSaved;
        skillsUsed = ht.skillsUsed;
    }

    invariant()
    {
        assert (this == Trophy.init || (built !is null && lastDir !is null));
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
                :  skillsUsed < rhs.skillsUsed; // Equal treated as worse.
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
    }
}
