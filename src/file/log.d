module file.log;

import std.stdio;
import std.string;
public import std.string : format;

import basics.alleg5;
import basics.globals;
import file.date;

class Log {

public:

    static void initialize();
    static void deinitialize();

    nothrow static void log (int);
    nothrow static void log (string);
    nothrow static void log (string, int);
    nothrow static void log (string, string);

private:

    static Log singl;

    std.stdio.File file;

    this();

    bool something_was_logged_already_this_session;
    static void   log_header_if_necessary();
    nothrow static string format_al_ticks();



public:

static void initialize()
{
    if (! singl) singl = new Log;
}



static void deinitialize()
{
    if (singl) {
        destroy(singl);
        singl = null;
    }
}



private this()
{
    file = std.stdio.File(basics.globals.file_log.get_rootful(), "a");
    something_was_logged_already_this_session = false;
}



private ~this()
{
    file.close();
}



private static void log_header_if_necessary()
{
    assert (singl);
    if (singl.something_was_logged_already_this_session) return;
    else {
        singl.something_was_logged_already_this_session = true;

        // a free line and then the current datetime in its own line
        singl.file.writefln("");
        singl.file.writefln(Date.now().toString);
    }
}



private nothrow static string format_al_ticks()
{
    try return format("%9.2f", al_get_timer_count(basics.alleg5.timer) * 1.0
                      / basics.globals.ticks_per_sec);
    catch (Exception) {
        return "bad time!";
    }
}



nothrow static void log(int i)
{
    try {
        log_header_if_necessary();
        singl.file.writefln("%s %d", format_al_ticks(), i);
        singl.file.flush();
    }
    catch (Exception) { }
}



nothrow static void log(string s)
{
    try {
        log_header_if_necessary();
        singl.file.writefln("%s %s", format_al_ticks(), s);
        singl.file.flush();
    }
    catch (Exception) { }
}



nothrow static void log(string s, int i)
{
    try {
        log_header_if_necessary();
        singl.file.writefln("%s %s %d", format_al_ticks(), s, i);
        singl.file.flush();
    }
    catch (Exception) { }
}



nothrow static void log(string s1, string s2)
{
    try {
        log_header_if_necessary();
        singl.file.writefln("%s %s %s", format_al_ticks(), s1, s2);
        singl.file.flush();
    }
    catch (Exception) { }
}

}
// end class
