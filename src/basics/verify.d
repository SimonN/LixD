module basics.verify;

import std.algorithm;
import std.array;
import std.file;
import std.stdio;
import core.memory;

import basics.cmdargs;
import basics.globals;
import basics.init;
import basics.user; // Result
import file.filename;
import game.core.game;
import game.replay;
import level.level;

public void processFileArgsForRunmode(Cmdargs cmdargs)
{
    if (! cmdargs.fileArgs.all!(f => f.fileExists || f.dirExists)) {
        cmdargs.fileArgs.filter!(f => ! (f.fileExists || f.dirExists))
            .each!(f => writefln("Error: File not found: `%s'", f.rootless));
        return;
    }
    basics.init.initialize(cmdargs);
    if (cmdargs.verifyReplays) {
        auto vc = new VerifyCounter(cmdargs.printCoverage);
        vc.writeCSVHeader();
        cmdargs.dispatch(fn => vc.verify(fn));
        vc.writeLevelsNotCovered();
        vc.writeStatistics();
    }
    else if (cmdargs.exportImages) {
        cmdargs.dispatch((Filename fn) {
            auto l = new Level(fn);
            l.exportImage(fn);
            core.memory.GC.collect();
        });
    }
    else
        assert (false);
}

private void dispatch(Cmdargs cmdargs, void delegate(Filename) func)
{
    foreach (fn; cmdargs.fileArgs) {
        if (fn.dirExists)
            fn.findTree(filenameExtReplay).each!func;
        else
            func(fn);
    }
}

private class VerifyCounter {

    // If true: When we verify a single replay filename (either directly
    // because you've asked on the commandline, or recursively), and the
    // replay's level exists and is good (playable), we look at
    // the level's directory, and add all levels from this directory to the
    // coverage requirement. With writeLevelsNotCovered, we can
    // later output the difference between the requirement and covered levels.
    immutable bool verifyCoverage;

    int total, noPtr, noLev, badLev, fail, ok;

    string[] levelDirsToCover;
    MutFilename[] levelsCovered; // this may contain duplicates until output

    this(bool cov) { verifyCoverage = cov; }

    void writeCSVHeader()
    {
        writeln("Result,Replay filename,Level filename,"
                "Player,Saved,Required,Skills,Updates");
    }

    void verify(Filename fn)
    {
        verifyImpl(fn);
        core.memory.GC.collect();
    }

    void writeResult(in Result res, Filename fn, in Replay rep, in Level lev)
    {
        string key;
        if      (fn == rep.levelFilename)     { key = "(NO-PTR)"; ++noPtr;  }
        else if (! lev.nonempty)              { key = "(NO-LEV)"; ++noLev;  }
        else if (! lev.good)                  { key = "(BADLEV)"; ++badLev; }
        else if (res.lixSaved < lev.required) { key = "(FAIL)";   ++fail;   }
        else                                  { key = "(OK)";     ++ok;     }
        writeln(key, ",", fn.rootless, ",", rep.levelFilename.rootless, ",",
            rep.playerLocalName, ",", res.lixSaved, ",", lev.required, ",",
            res.skillsUsed, ",", res.updatesUsed);
    }

    void writeStatistics()
    {
        writeln();
        writeln("Statistics from ", total, " replays:");
        if (noPtr)
            writefln("%5dx (NO-PTR): replay ignored, "
                     "it doesn't name a level file.", noPtr);
        if (noLev)
            writefln("%5dx (NO-LEV): replay ignored, "
                     "it names a level file that doens't exist.", noLev);
        if (badLev)
            writefln("%5dx (BADLEV): replay ignored, "
                     "it names a level file with a bad level.", badLev);
        if (fail)
            writefln("%5dx (FAIL): replay names "
                     "an existing level file, but doesn't solve it.", fail);
        if (ok)
            writefln("%5dx (OK): replay names "
                     "an existing level file and solves that level.", ok);
    }

    void writeLevelsNotCovered()
    {
        if (! verifyCoverage)
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
            writeln();
            writeln("These ", levelsNotCovered.length,
                " levels have no proof:");
            levelsNotCovered.each!(fn => writeln(fn.rootless));
        }
        writeln();
        write("Directory coverage: ");
        if (levelsNotCovered.empty)
            writeln("All ", totalLevelsToCover, " levels are solvable.");
        else
            writeln(totalLevelsToCover - levelsNotCovered.length,
                " of ", totalLevelsToCover, " levels are solvable, ",
                levelsNotCovered.length, " may be unsolvable.");
    }

private:
    void verifyImpl(Filename fn)
    {
        ++total;
        Replay rep = Replay.loadFromFile(fn);
        Level  lev = new Level(rep.levelFilename);
        // We never look at the included level
        if (fn == rep.levelFilename || ! lev.good) {
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
        if (! verifyCoverage)
            return;
        levelDirsToCover = (levelDirsToCover ~ levelFn.dirRootless)
            .sort().uniq.array;
        if (solved)
            levelsCovered = (levelsCovered ~ MutFilename(levelFn))
                .sort!fnLessThan.uniq.array;
    }
}
