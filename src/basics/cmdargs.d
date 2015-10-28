module basics.cmdargs;

/* Parsing command-line arguments: These act like global config options in
 * basics.globconf, but command-line switches are not written to that module
 * and therefore not saved to the config file.
 *
 * Right now, all the using code throughout the program must look up the
 * parsed command-line switches in addition to the global/user config.
 */

import std.array; // array()
import std.algorithm; // splitter
import std.conv;
import std.stdio;

import basics.versioning;
import file.filename;

enum Runmode {
    INTERACTIVE,
    VERIFY,
    PRINT_AND_EXIT
}

private string _helpAndExitOutput =
    "-h or -? or --help      print this help and exit\n"
    "-n                      ask for player's name on startup\n"
    "-v or --version         print version and exit\n"
    "-w                      run in windowed mode at 640x480\n"
    "--resol=800x600         run in windowed mode at the given resolution\n"
    "--verify=dir/file.txt   verify the replay file `dir/file.txt'\n"
    "--verify=mydir          verify all replays in directory `mydir'";



class Cmdargs {

    bool usernameAsk;
    bool windowed;
    bool versionAndExit;
    bool helpAndExit;

    int  wantResolutionX;
    int  wantResolutionY;

    private string[] badSwitches;
    Filename[]       verifyFiles;

    @property Runmode mode()
    {
        if (badSwitches != null || versionAndExit || helpAndExit)
            return Runmode.PRINT_AND_EXIT;
        else if (verifyFiles != null)
            return Runmode.VERIFY;
        else
            return Runmode.INTERACTIVE;
    }



    this(string[] args)
    {
        // argument 0 is the program name, loop over the extra ones only
        foreach (arg; args[1 .. $]) {
            if (arg.starts_with("--")) {
                immutable vrf   = "--verify=";
                immutable resol = "--resol=";

                if (arg == "--version") {
                    versionAndExit = true;
                }
                else if (arg == "--help") {
                    helpAndExit = true;
                }
                else if (arg.starts_with(vrf)) {
                    verifyFiles ~= new Filename(arg[vrf.length .. $]);
                }
                else if (arg.starts_with(resol)) {
                    // this string is expected to be of the form "1234x567"
                    string want_res = arg[resol.length .. $];
                    try {
                        string[] numbers = splitter(want_res, 'x').array();
                        if (numbers.length != 2)
                            // leave wanted resolution at 0
                            throw new Exception("caught in 5 lines anyway");
                        // these can throw too on bad chars in the string
                        wantResolutionX = numbers[0].to!int;
                        wantResolutionY = numbers[1].to!int;
                    }
                    catch (Exception e) { }

                    if (wantResolutionX == 0 || wantResolutionY == 0)
                        badSwitches ~= arg;
                    else
                        windowed = true;
                }
                else {
                    badSwitches ~= arg;
                }
            }
            else if (arg.starts_with("-")) {
                // allow arguments chained like -nw
                foreach (c; arg[1 .. $]) switch (c) {
                case 'h': helpAndExit    = true; break;
                case 'n': usernameAsk    = true; break;
                case 'v': versionAndExit = true; break;
                case 'w': windowed       = true; break;
                case '?': helpAndExit    = true; break;
                default : badSwitches ~= "-" ~ c; break;
                }
            }
            else badSwitches ~= arg;
        }
    }



    void printNoninteractiveOutput()
    {
        // always print the version; -v is basically used to enter this
        // function without triggering any additional cases. However, if
        // only the version is to be printed, print it without decoration.
        if (versionAndExit && ! helpAndExit && badSwitches == null)
            writeln(gameVersion);
        else
            writeln("Lix version ", gameVersion);

        if (badSwitches != null) {
            foreach (sw; badSwitches)
                writeln("Bad command-line argument: `" ~ sw ~ "'");
            if (! helpAndExit)
                writeln("Try -h or -? for help.");
        }
        if (helpAndExit)
            writeln(_helpAndExitOutput);
    }

}
// end class



private bool
starts_with(string large, string small)
{
    return large.length >= small.length
     && large[0 .. small.length] == small;
}
