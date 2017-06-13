module verify.cmdargs;

import std.algorithm;
import std.stdio;
import core.memory;

import basics.cmdargs;
import basics.globals;
import basics.init;
import file.filename;
import level.level; // for image export
import verify.counter;

// basics.cmdargs parses the command line, then gives us the results.
// We decide whether to load a VerifyCounter.

public void processFileArgsForRunmode(Cmdargs cmdargs)
{
    if (! cmdargs.fileArgs.all!(f => f.fileExists || f.dirExists)) {
        cmdargs.fileArgs.filter!(f => ! (f.fileExists || f.dirExists))
            .each!(f => writefln("Error: File not found: `%s'", f.rootless));
        return;
    }
    basics.init.initialize(cmdargs);
    if (cmdargs.verifyReplays) {
        auto vc = new VerifyCounter(new class VerifyPrinter {
            override bool printCoverage() { return cmdargs.printCoverage; }
            override void log(string s) { writeln(s); }
        });
        vc.writeCSVHeader();
        cmdargs.dispatch((fn) {
            vc.verifyOneReplay(fn);
            maybeGC();
        });
        vc.writeLevelsNotCovered();
        vc.writeStatistics();
    }
    else if (cmdargs.exportImages) {
        cmdargs.dispatch((Filename fn) {
            auto l = new Level(fn);
            l.exportImage(fn);
            maybeGC();
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

private void maybeGC()
{
    static int n = 0;
    ++n;
    if (n == 3) {
        n = 0;
        import core.memory;
        core.memory.GC.collect();
    }
}
