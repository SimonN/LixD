module file.log;

import std.file;
import std.stdio;
import std.string;

import basics.alleg5;
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
    bool _initialized;
    bool _somethingAlreadyLoggedThisSession;
    std.stdio.File _file;

public:

nothrow static void
initialize()
{
    if (_initialized)
        return;
    _somethingAlreadyLoggedThisSession = false;

    version (unittest) {
    }
    else {
        try {
            _file = basics.globals.fileLog.openForWriting("a");
            _initialized = true;
        }
        catch (Exception) {
            try _file = _file.init;
            catch (Exception) { }
        }
    }
}

nothrow static void
deinitialize()
{
    if (! _initialized)
        return;
    try {
        _file.close();
        _file = _file.init;
    }
    catch (Exception) { }
    _initialized = false;
}

nothrow static void
log(string s)
{
    if (! _initialized)
        return;
    try {
        logHeaderIfNecessary();
        _file.writefln("%s %s", formatAlTicks(), s);
        _file.flush();
    }
    catch (Exception) { }
}

nothrow static void
logf(T...)(string formatstr, T formatargs)
{
    if (! _initialized)
        return;
    try {
        logHeaderIfNecessary();
        _file.writefln("%s " ~ formatstr, formatAlTicks(), formatargs);
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

///////////////////////////////////////////////////////////////////////////////

private static void
logHeaderIfNecessary()
{
    if (! _initialized || _somethingAlreadyLoggedThisSession) {
        return;
    }
    else {
        _somethingAlreadyLoggedThisSession = true;

        // a free line and then the current datetime in its own line
        _file.writefln("");
        _file.writefln("Lix version:  " ~ gameVersion().toString());
        _file.writefln("Session date: " ~ Date.now().toString);
    }
}

private nothrow static string
formatAlTicks()
{
    try return format("%9.2f", timerTicks * 1.0 / ticksPerSecond);
    catch (Exception) {
        return "bad time!";
    }
}
