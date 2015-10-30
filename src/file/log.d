module file.log;

import std.file : mkdirRecurse;
import std.stdio;
import std.string;
public import std.string : format;

import basics.alleg5;
import basics.globals;
import basics.versioning;
import file.date;

/*  nothrow static void initialize();
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
    try {
        std.file.mkdirRecurse(basics.globals.fileLog.dirRootful);
        _file = std.stdio.File(basics.globals.fileLog.rootful, "a");
        _initialized = true;
    }
    catch (Exception) {
        try _file = _file.init;
        catch (Exception) { }
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
    try return format("%9.2f", al_get_timer_count(basics.alleg5.timer) * 1.0
                      / basics.globals.ticksPerSecond);
    catch (Exception) {
        return "bad time!";
    }
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
