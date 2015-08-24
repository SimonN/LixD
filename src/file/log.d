module file.log;

import std.stdio;
import std.string;
public import std.string : format;

import basics.alleg5;
import basics.globals;
import basics.versioning;
import file.date;

class Log {

/*  static void initialize();
 *  static void deinitialize();
 *
 *  nothrow static void log       (string);
 *  nothrow static void logf(T...)(string, T);
 */

private:

    static Log singl;

    std.stdio.File file;

    this();

    bool something_was_logged_already_this_session;
    static void   log_header_if_necessary();
    nothrow static string format_al_ticks();



public:

static void
initialize()
{
    if (! singl) singl = new Log;
}



static void
deinitialize()
{
    if (singl) {
        destroy(singl);
        singl = null;
    }
}



private
this()
{
    file = std.stdio.File(basics.globals.file_log.rootful, "a");
    something_was_logged_already_this_session = false;
}



private
~this()
{
    file.close();
}



private static void
log_header_if_necessary()
{
    assert (singl);
    if (singl.something_was_logged_already_this_session) return;
    else {
        singl.something_was_logged_already_this_session = true;

        // a free line and then the current datetime in its own line
        singl.file.writefln("");
        singl.file.writefln("Lix version:  " ~ get_version_string());
        singl.file.writefln("Session date: " ~ Date.now().toString);
    }
}



private nothrow static string
format_al_ticks()
{
    try return format("%9.2f", al_get_timer_count(basics.alleg5.timer) * 1.0
                      / basics.globals.ticks_per_sec);
    catch (Exception) {
        return "bad time!";
    }
}



nothrow static void
log(string s)
{
    try {
        log_header_if_necessary();
        singl.file.writefln("%s %s", format_al_ticks(), s);
        singl.file.flush();
    }
    catch (Exception) { }
}



nothrow static void
logf(T...)(string formatstr, T formatargs)
{
    try {
        log_header_if_necessary();
        singl.file.writefln("%s " ~ formatstr, format_al_ticks(), formatargs);
        singl.file.flush();
    }
    catch (Exception) { }
}

}
// end class
