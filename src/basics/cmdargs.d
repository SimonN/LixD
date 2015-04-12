module basics.cmdargs;

/* Parsing command-line arguments: These act like global config options in
 * basics.globconf, but command-line switches are not written to that module
 * and therefore not saved to the config file.
 *
 * Right now, all the using code throughout the program must look up the
 * parsed command-line switches in addition to the global/user config.
 */

import std.stdio;

import basics.versioning;
import file.filename;

enum Runmode {
    INTERACTIVE,
    VERIFY,
    PRINT_AND_EXIT
}



class Cmdargs {

    bool username_ask;
    bool windowed;
    bool sound_disabled;
    bool version_and_exit;
    bool help_and_exit;

    private string[] bad_switches;
    Filename[]       verify_files;

    @property Runmode mode()
    {
        if (bad_switches != null || version_and_exit || help_and_exit)
            return Runmode.PRINT_AND_EXIT;
        else if (verify_files != null)
            return Runmode.VERIFY;
        else
            return Runmode.INTERACTIVE;
    }



    this(string[] args)
    {
        // argument 0 is the program name, loop over the extra ones only
        foreach (arg; args[1 .. $]) {
            if (arg.starts_with("--")) {
                immutable vrf = "--verify=";
                if (arg.starts_with(vrf))
                    verify_files ~= new Filename(arg[vrf.length .. $]);
                else
                    bad_switches ~= arg;
            }
            else if (arg.starts_with("-")) {
                // allow arguments chained like -nw
                foreach (c; arg[1 .. $]) switch (c) {
                case 'h': help_and_exit    = true; break;
                case 'n': username_ask     = true; break;
                case 'o': sound_disabled   = true; break;
                case 'v': version_and_exit = true; break;
                case 'w': windowed         = true; break;
                case '?': help_and_exit    = true; break;
                default : bad_switches ~= "-" ~ c; break;
                }
            }
            else bad_switches ~= arg;
        }
    }



    void print_noninteractive_output()
    {
        // always print the version; -v is basically used to enter this
        // function without triggering any additional cases
        writeln("Lix version " ~ get_version_string());
        if (bad_switches != null) {
            foreach (sw; bad_switches)
                writeln("Bad command-line argument: " ~ sw);
            if (! help_and_exit) writeln("Try -h or -? for help.");
        }
        if (help_and_exit) writeln(
            "-h or -?           print this help and exit\n"
            "-n                 ask for player's name on startup\n"
            "-o                 disable all sound\n"
            "-v                 print version and exit\n"
            "-w                 run in windowed mode\n"
            "--verify=file.txt  verify the replay file `a/b.txt'\n"
            "--verify=mydir     verify all replays in directory `mydir'");
    }

}
// end class



private bool
starts_with(string large, string small)
{
    return large.length >= small.length
     && large[0 .. small.length] == small;
}
