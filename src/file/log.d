module file.log;

import core.time;
import std.file;
import std.stdio;
import std.string;

import basics.globals;
import net.versioning;
import file.date;

/*
 * Logging: We disable it during unittests, to avoid spam: Tests should be
 * run often, and they might simulate error conditions.
 * If you want important messages printed during tests, print them
 * right to standard output.
 *
 *  nothrow static void initialize();
 *  nothrow static void deinitialize();
 *
 *  nothrow static void log       (string);
 *  nothrow static void logf(T...)(string, T);
 */

private:
    bool _isInitialized = false;
    MonoTime _timeOfInit;
    bool _somethingAlreadyLoggedThisSession;
    std.stdio.File _file;

public:

nothrow static void
initialize()
{
    if (_isInitialized)
        return;
    _somethingAlreadyLoggedThisSession = false;
    _timeOfInit = MonoTime.currTime;

    version (unittest) {
    }
    else {
        try {
            _file = basics.globals.fileLog.openForWriting("a");
            _isInitialized = true;
        }
        catch (Exception) {
            _isInitialized = false;
            try _file = _file.init;
            catch (Exception) { }
        }
    }
}

nothrow static void
deinitialize()
{
    if (! _isInitialized)
        return;
    try {
        _file.close();
        _file = _file.init;
    }
    catch (Exception) { }
    _isInitialized = false;
}

nothrow static void
log(string s)
{
    if (! _isInitialized)
        return;
    try {
        logHeaderIfNecessary();
        _file.writefln("%s %s", formatTimeSinceInit(), s);
        _file.flush();
    }
    catch (Exception) { }
}

nothrow static void
logf(T...)(string formatstr, T formatargs)
{
    if (! _isInitialized)
        return;
    try {
        logHeaderIfNecessary();
        _file.writefln("%s " ~ formatstr, formatTimeSinceInit(), formatargs);
        _file.flush();
    }
    catch (Exception) { }
}

nothrow static void
logfEvenDuringUnittest(Args...)(string formatstr, Args args)
{
    try {
        version (unittest) std.stdio.writefln(formatstr, args);
        else logf(formatstr, args);
    }
    catch (Exception) {}
}

// Throws again its argument (firstThr).
static void
logThenRethrowToTerminate(Throwable firstThr)
{
    // Uncaught exceptions, assert errors, and assert (false) should
    // fly straight out of main() and terminate the program. Since
    // Windows users won't run the game from a shell, they should
    // retrieve the error message from the logfile.
    for (Throwable thr = firstThr; thr !is null; thr = thr.next) {
        logf("%s:%d:", thr.file, thr.line);
        log(thr.msg);
        log(thr.info.toString());
    }
    throw firstThr;
}

///////////////////////////////////////////////////////////////////////////////

private static void
logHeaderIfNecessary()
{
    if (! _isInitialized || _somethingAlreadyLoggedThisSession) {
        return;
    }
    _somethingAlreadyLoggedThisSession = true;
    _file.writefln("");
    _file.writefln("Lix version:  " ~ gameVersion().toString());
    _file.writefln("Session date: " ~ Date.now().toString);
}

private static string
formatTimeSinceInit() nothrow
{
    try {
        return format("%9.2f", secondsSinceInitAsDouble);
    }
    catch (Exception) {
        return "Bad time!";
    }
}

private static double
secondsSinceInitAsDouble() nothrow @nogc
{
    if (_timeOfInit == MonoTime.init) {
        return 0.00;
    }
    return (MonoTime.currTime - _timeOfInit).total!("msecs") / 1000.0;
}
