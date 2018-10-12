module file.trophy.trophy;

import std.string;

import basics.globals : dirLevels;
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
 * that is directory + fileNoExt + ".txt". These trophies were converted to
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
private:
    /*
     * lastDirWithinLevels: E.g., "single/lemforum/Lovely/" in the case
     * of Any Way You Want. Without the preceding dirLevels, without preceding
     * slash. Not a MutFilename because it's only for trophy I/O at the moment.
     * - If empty, it means that the level was found in the root dir
     *   of dirLevels (although nobody should put levels there).
     * - If nonempty, this always is terminated with a slash.
     */
    string _lastDirWithinLevels;

public:
    int lixSaved;
    int skillsUsed;
    MutableDate built;

    @disable this(); // always construct with a valid date

    this(Date aDate, string aDirWithinLevels)
    {
        _lastDirWithinLevels = aDirWithinLevels.sanitizeForLastDir;
        built = aDate;
    }

    this(Date aDate, Filename aLastDir) // Use this constructor if possible.
    {
        _lastDirWithinLevels = aLastDir.rootless
            .chompPrefix(dirLevels.rootless).sanitizeForLastDir;
        built = aDate;
    }

    @property string lastDirWithinLevels() const pure @nogc nothrow
    {
        return _lastDirWithinLevels;
    }

    void copyFrom(HalfTrophy ht)
    {
        lixSaved = ht.lixSaved;
        skillsUsed = ht.skillsUsed;
    }

    invariant()
    {
        if (this == Trophy.init)
            return;
        assert (built !is null);
        assert (_lastDirWithinLevels
            == _lastDirWithinLevels.sanitizeForLastDir);
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
        auto a = typeof(this)(Date.now(), "single/somedir/");
        auto b = typeof(this)(a.built, "single/somedir/");
        a.lixSaved = 4;
        b.lixSaved = 5;
        assert (b.shouldReplaceAfterPlay(a));
        b.lixSaved = 4;
        assert (! b.shouldReplaceAfterPlay(a));
    }
}

///////////////////////////////////////////////////////////////////////////////

private:

string sanitizeForLastDir(string ret)
{
    while (ret.length > 0 && ret[$-1] != '/') {
        ret = ret[0 .. $-1];
    }
    return ret;
}
