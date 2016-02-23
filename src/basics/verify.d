module basics.verify;

import std.algorithm;
import std.file;
import std.stdio;

import basics.cmdargs;
import basics.globals;
import basics.init;
import basics.user; // Result
import file.filename;
import file.search;
import game.core.game;
import game.replay;
import level.level;

public void verifyFiles(Cmdargs cmdargs)
{
    if (! cmdargs.verifyFiles.all!(f => f.rootful.exists)) {
        cmdargs.verifyFiles.map!(f => f.rootful).filter!(str => ! str.exists)
            .each!(str => writefln("Error: File not found: `%s'", str));
        return;
    }
    std.stdio.write("Initializing game...");
    stdout.flush;
    basics.init.initialize(cmdargs);
    writeln(" done. Я твой слуга.");

    auto vc = new VerifyCounter;
    vc.writeCSVHeader();
    cmdargs.verifyFiles.each!(fn => vc.verifyDirOrFile(fn));
    vc.writeStatistics();
}

private class VerifyCounter {

    int total, noPtr, noLev, badLev, fail, ok;

    void verifyDirOrFile(Filename fn)
    {
        if (std.file.isDir(fn.rootful))
            fn.findRegularFilesRecursively(filenameExtReplay)
                .each!(foundFile => verifyAndGC(foundFile));
        else
            verifyAndGC(fn);
    }

    void verifyAndGC(Filename fn)
    {
        verify(fn);
        core.memory.GC.collect();
    }

    void verify(Filename fn)
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
        Game game = new Game(Runmode.VERIFY, lev, rep.levelFilename, rep);
        writeResult(game.evaluateReplay(), fn, rep, lev);
        destroy(game);
    }

    void writeCSVHeader()
    {
        writeln("Result,Replay filename,Level filename,"
                "Player,Saved,Required,Skills,Updates");
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
        writeln("Total results from ", total, " replays:");
        if (noPtr)
            writefln("%4dx (NO-PTR): replay ignored, "
                     "it doesn't name a level file.", noPtr);
        if (noLev)
            writefln("%4dx (NO-LEV): replay ignored, "
                     "it names a level file that doens't exist.", noLev);
        if (badLev)
            writefln("%4dx (BADLEV): replay ignored, "
                     "it names a level file with a bad level.", badLev);
        if (fail)
            writefln("%4dx (FAIL): replay names "
                     "an existing level file, but doesn't solve it.", fail);
        if (ok)
            writefln("%4dx (OK): replay names "
                     "an existing level file and solves that level.", ok);
    }
}
