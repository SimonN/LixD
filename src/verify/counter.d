module verify.counter;

// Called from verify.cmdargs noninteractively, or from the GUI VerifyMenu.

import std.algorithm;
import std.array;
import std.format;

import basics.user; // Result
import file.filename;
import game.core.game;
import game.replay;
import level.level;

// Implement this class, then pass one to VerifyCounter.
abstract class VerifyPrinter {
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

    int total, noPtr, noLev, badLev, multi, fail, ok;

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
        vp.log("Result,Replay filename,Level filename,"
            ~  "Player,Saved,Required,Skills,Phyus");
    }

    void verifyOneReplay(Filename fn)
    {
        verifyImpl(fn);
    }

    void writeStatistics()
    {
        vp.log("");
        vp.log(format!"%s%d%s"("Statistics from ", total, " replays:"));
        if (multi)
            vp.log(multi.format!"%5dx (MULTI): replay ignored, it is multiplayer.");
        if (noPtr)
            vp.log(noPtr.format!"%5dx (NO-PTR): replay ignored, it doesn't name a level file.");
        if (noLev)
            vp.log(noLev.format!"%5dx (NO-LEV): replay ignored, it names a level file that doens't exist.");
        if (badLev)
            vp.log(badLev.format!"%5dx (BADLEV): replay ignored, it names a level file with a bad level.");
        if (fail)
            vp.log(fail.format!"%5dx (FAIL): replay names an existing level file, but doesn't solve it.");
        if (ok)
            vp.log(ok.format!"%5dx (OK): replay names an existing level file and solves that level.");
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
            vp.log(format!"These %d levels have no proof:"(
                levelsNotCovered.length));
            levelsNotCovered.each!(fn => vp.log(fn.rootless));
        }
        vp.log("");
        vp.log("Directory coverage: ");
        if (levelsNotCovered.empty)
            vp.log(totalLevelsToCover.format!"All %d levels are solvable.");
        else
            vp.log(format!"%d of %d levels are solvable, %d may be unsolvable."
                (totalLevelsToCover - levelsNotCovered.length,
                 totalLevelsToCover,  levelsNotCovered.length));
    }

private:
    void verifyImpl(Filename fn)
    {
        ++total;
        Replay rep = Replay.loadFromFile(fn);
        Level  lev = new Level(rep.levelFilename);
        // We never look at the included level
        if (fn == rep.levelFilename || ! lev.good || rep.numPlayers > 1) {
            // give a result with all zeroes to pad the fields
            writeResult(new Result(lev.built), fn, rep, lev);
            return;
        }
        // The pointed-to level is good.
        Game game = new Game(Runmode.VERIFY, lev, rep.levelFilename, rep);
        auto result = game.evaluateReplay();
        destroy(game);
        rememberCoverage(rep.levelFilename, result.lixSaved >= lev.required);
        writeResult(result, fn, rep, lev);
    }

    void rememberCoverage(in Filename levelFn, bool solved)
    {
        if (! vp.printCoverage)
            return;
        if (! levelDirsToCover.canFind(levelFn.dirRootless)) {
            levelDirsToCover ~= levelFn.dirRootless;
            levelDirsToCover = levelDirsToCover.sort().uniq.array;
        }
        if (solved)
            levelsCovered = (levelsCovered ~ MutFilename(levelFn))
                .sort!fnLessThan.uniq.array;
    }

    void writeResult(in Result res, Filename fn, in Replay rep, in Level lev)
    in {
        assert (res);
        assert (fn);
        assert (rep);
    }
    body {
        string key;
        if      (rep.numPlayers > 1)          { key = "(MULTI)";  ++multi;  }
        else if (fn == rep.levelFilename)     { key = "(NO-PTR)"; ++noPtr;  }
        else if (! lev.nonempty)              { key = "(NO-LEV)"; ++noLev;  }
        else if (! lev.good)                  { key = "(BADLEV)"; ++badLev; }
        else if (res.lixSaved < lev.required) { key = "(FAIL)";   ++fail;   }
        else                                  { key = "(OK)";     ++ok;     }
        vp.log(format!"%s,%s,%s,%s,%d,%d,%d,%d"(key, fn.rootless,
            rep.levelFilename ? rep.levelFilename.rootless : "",
            rep.playerLocalOrSmallest.name, res.lixSaved,
            lev ? lev.required : 0, res.skillsUsed, res.phyusUsed));
    }
}
