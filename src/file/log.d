module file.log;

import core.time;
import std.file;
import std.stdio;
import std.string;

static import basics.globals;
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

nothrow static @safe void
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

nothrow static @safe void
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

nothrow static @safe void
logfEvenDuringUnittest(Args...)(string formatstr, Args args)
{
    try {
        version (unittest) std.stdio.writefln(formatstr, args);
        else logf(formatstr, args);
    }
    catch (Exception) {}
}

static void
showMessageBoxOnWindows(in Throwable thr)
{
    showOsSpecificMessageBox(thr);
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
logHeaderIfNecessary() @safe
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
formatTimeSinceInit() nothrow @safe
{
    try {
        return format("%9.2f", secondsSinceInitAsDouble);
    }
    catch (Exception) {
        return "Bad time!";
    }
}

private static double
secondsSinceInitAsDouble() nothrow @safe @nogc
{
    if (_timeOfInit == MonoTime.init) {
        return 0.00;
    }
    return (MonoTime.currTime - _timeOfInit).total!("msecs") / 1000.0;
}

///////////////////////////////////////////////////////////////////////////////

version (Windows) {
    import core.sys.windows.windows;
    import std.conv : wtext;

    import basics.alleg5;
    import hardware.display;

    // 2024-05: This declaration belongs into DAllegro5. I'll submit a PR.
    nothrow @nogc extern (C) {
        HWND al_get_win_window_handle(ALLEGRO_DISPLAY *display);
    }

    private void showOsSpecificMessageBox(in Throwable thr)
    {
        al_show_mouse_cursor(theA5display);
        const messageBody = _isInitialized
            ? wtext(thr.msg,
                "\n\n", "Lix has crashed at:",
                "\n", thr.file, ":", thr.line,
                "\n\n", "Details are in the logfile:",
                "\n", basics.globals.fileLog.rootless,
                "\0")
            : wtext(thr.msg,
                "\n\n", "Lix has stopped early at:",
                "\n", thr.file, ":", thr.line,
                "\0");
        MessageBoxW(al_get_win_window_handle(theA5display),
            messageBody.ptr, null, MB_ICONERROR);
    }
}
else {
    private void showOsSpecificMessageBox(in Throwable) {}
}
