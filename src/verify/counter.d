module verify.counter;

// Called from verify.cmdargs noninteractively, or from the GUI VerifyMenu.

import std.algorithm;
import std.array;
import std.format;
import enumap;

import file.option; // remember results if playername == username
import file.option; // Result, update results if our own replay solves
import file.filename;
import file.language;
import verify.tested;

// Pass such an object to VerifyCounter.
interface VerifyPrinter {
    // If true: When we verify a single replay filename (either directly
    // because you've asked on the commandline, or recursively), and the
    // replay's level exists and is good (playable), we look at
    // the level's directory, and add all levels from this directory to the
    // coverage requirement. With writeLevelsNotCovered, we can
    // later output the difference between the requirement and covered levels.
    abstract bool printCoverage();

    // Print lines from the verifier somewhere.
    // Refactoring idea: Make this into an output range, so that VerifyCounter
    // doesn't have to allocate the string, but merely passes the results of
    // formattedWrite to us. I haven't defined my own output ranges yet.
    abstract void log(string);
}

class VerifyCounter {
private:
    VerifyPrinter vp;

    Enumap!(verify.tested.Status, int) _stats; // number of replays per stat
    int _trophiesUpdated; // number of checkmarks updated with better results

    string[] levelDirsToCover;
    MutFilename[] levelsCovered; // this may contain duplicates until output

public:
    this(VerifyPrinter aVp)
    {
        assert (aVp);
        vp = aVp;
    }

    void writeCSVHeader()
    {
        vp.log(Lang.verifyHeader.transl);
    }

    void verifyOneReplay(Filename fn)
    {
        verifyImpl(fn);
    }

    void writeStatistics()
    {
        vp.log("");
        vp.log(Lang.verifyStatisticsFrom.translf(_stats.byValue.sum));
        foreach (Status st, int nr; _stats) {
            if (nr <= 0)
                continue;
            vp.log(format!"%5dx %s: %s"(nr, statusWord[st], statusDesc(st)));
        }
        if (_trophiesUpdated)
            vp.log(Lang.verifyTrophiesUpdated.translf(
                _trophiesUpdated, userName));
    }

    void writeLevelsNotCovered()
    {
        if (! vp.printCoverage)
            return;
        // levelsCovered may contain duplicates. Remove duplicates.
        levelsCovered = levelsCovered.sort!fnLessThan.uniq.array;
        MutFilename[] levelsToCover = levelDirsToCover.sort().uniq
            .map!(dirString => new VfsFilename(dirString))
            .map!(fn => fn.findFiles)
            .joiner
            .filter!(fn => fn.preExtension == 0) // no _order.X.txt
            .array;
        levelsToCover.sort!fnLessThan;
        immutable totalLevelsToCover = levelsToCover.length;
        // We assume that every level that (we have tested positive)
        // has also (been found with the directory search).
        // Under this assumption, levelsCovered is a subset of levelsToCover.
        // Because both levelsCovered and levelsToCover are sort.uniq.array,
        // we can generate list of not-covered levels with the following algo.
        MutFilename[] levelsNotCovered = [];
        while (levelsToCover.length) {
            if (levelsCovered.empty) {
                levelsNotCovered ~= levelsToCover;
                levelsToCover = [];
                break;
            }
            else if (levelsCovered[0] == levelsToCover[0])
                levelsCovered = levelsCovered[1 .. $];
            else
                levelsNotCovered ~= levelsToCover[0];
            levelsToCover = levelsToCover[1 .. $];
        }
        // Done algo. levelsToCover and levelsCovered are clobbered.
        if (levelsNotCovered.length > 0) {
            vp.log("");
            vp.log(Lang.verifyLevelsNoProof.translf(levelsNotCovered.length));
            levelsNotCovered.each!(fn => vp.log(fn.rootless));
        }
        vp.log("");
        vp.log(Lang.verifyDirectoryCoverage.transl);
        if (levelsNotCovered.empty)
            vp.log(Lang.verifyAllLevelsCovered.translf(totalLevelsToCover));
        else
            vp.log(Lang.verifySomeLevelsCovered.translf(
                totalLevelsToCover - levelsNotCovered.length,
                totalLevelsToCover,  levelsNotCovered.length));
    }

private:
    void verifyImpl(Filename fn)
    in { assert(fn, "Filename shouldn't be null, Optional!Filename might be");}
    do {
        auto tested = new TestedReplay(fn);
        vp.log(tested.toString);
        _stats[tested.status] += 1;
        _trophiesUpdated += tested.maybeAddTrophy();
        rememberCoverage(tested);
    }

    void rememberCoverage(in TestedReplay tested)
    {
        if (! vp.printCoverage || tested.levelFilename.empty)
            return;
        Filename tlfn = tested.levelFilename.front;
        if (! levelDirsToCover.canFind(tlfn.dirRootless)) {
            levelDirsToCover ~= tlfn.dirRootless;
            levelDirsToCover = levelDirsToCover.sort().uniq.array;
            // This sorting-arraying is expensive, but usually, we have very
            // few different level dirs per run. Therefore, we rarely enter
            // this branch.
        }
        if (tested.solved) {
            // This is more expensive, but maybe still not enough to opitmize
            // away the sort-arraying.
            levelsCovered = (levelsCovered ~ MutFilename(tlfn))
                .sort!fnLessThan.uniq.array;
        }
    }

    static string statusDesc(Status st)
    {
        Lang la = void;
        final switch (st) {
            case Status.untested: assert (false, "Replay wasn't tested.");
            case Status.multiplayer: la = Lang.verifyStatusMultiplayer; break;
            case Status.noPointer: la = Lang.verifyStatusNoPointer; break;
            case Status.missingLevel: la = Lang.verifyStatusMissingLevel;break;
            case Status.badLevel: la = Lang.verifyStatusBadLevel; break;
            case Status.failed: la = Lang.verifyStatusFailed; break;
            case Status.mercyKilled: la = Lang.verifyStatusMercyKilled; break;
            case Status.solved: la = Lang.verifyStatusSolved; break;
        }
        if (la == Lang.verifyStatusMercyKilled)
            return la.translf(5);
        else return la.transl;
    }
}
