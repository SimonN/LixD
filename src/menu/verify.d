module menu.verify;

// A window that verifies replays in the given directory, prints to itself
// and to the logfile, and allows interruption.

import core.memory;
import std.algorithm;
import std.string;

import basics.globals;
import basics.user; // hotkeys to cancel the dialog;
import file.filename;
import file.log;
import gui;
import hardware.mouse; // clicks to cancel the dialog
import verify.counter;

class VerifyMenu : Window {
private:
    Console _console;
    VerifyCounter _vc;
    MutFilename[] _queue;

public:
    this(Filename dir)
    in { assert (dir); }
    out { assert (_vc); }
    body {
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg),
            // DTODOLANG
            "Replay Verifier");
        _console = new LobbyConsole(new Geom(20, 40, xlg - 40, ylg - 60));
        addChild(_console);

        _queue = dir.findTree(filenameExtReplay);
        _vc = new VerifyCounter(new class VerifyPrinter {
            override bool printCoverage() { return true; }
            override void log(string s) {
                _console.add(s);
                file.log.log(s);
            }
        });
        _vc.writeCSVHeader();
    }

protected:
    override void calcSelf()
    {
        verifyOneFromQueue();
        if (keyMenuOkay.keyTapped || keyMenuExit.keyTapped
            || keyMenuDelete.keyTapped || mouseClickLeft || mouseClickRight
        ) {
            rmFocus(this);
        }
    }

private:
    void verifyOneFromQueue()
    {
        if (_queue.length == 0)
            return;
        _vc.verifyOneReplay(_queue[0]);
        _queue =_queue[1 .. $];
        if (_queue.length % 10 == 0)
            core.memory.GC.collect();
        if (_queue.length == 0) {
            _vc.writeLevelsNotCovered();
            _vc.writeStatistics();
            _console.addWhite("Output written to `"
                ~ fileLog.rootless ~ "'. Click to return."); // DTODOLANG
        }
    }
}
