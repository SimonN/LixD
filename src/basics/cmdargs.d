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
    "-v or --version         print version and exit\n"
    "-w                      run windowed at 640x480\n"
    "--resol=800x600         run windowed at the given resolution\n"
    "--fullscreen            use software fullscreen mode (good Alt+Tab)\n"
    "--hardfull=1600x900     use hardware fullscreen at given resolution\n"
    "--verify=dir/file.txt   verify the replay file `dir/file.txt'\n"
    "--verify=mydir          verify all replays in directory `mydir'\n"
    "--coverage              print unverified levels when you --verify";



class Cmdargs {

    bool forceWindowed;
    bool forceSoftwareFullscreen;
    bool forceHardwareFullscreen;
    bool versionAndExit;
    bool helpAndExit;

    int  wantResolutionX;
    int  wantResolutionY;

    private string[] badSwitches;
    Filename[]       verifyFiles;
    bool             verifyCoverage;

    @property Runmode mode() const
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
            if (arg.startsWith("--"))
                parseDashDashArgument(arg);
            else if (arg.startsWith("-"))
                // allow arguments chained like -nw
                foreach (c; arg[1 .. $]) switch (c) {
                    case 'h': helpAndExit    = true; break;
                    case 'v': versionAndExit = true; break;
                    case 'w': forceWindowed  = true; break;
                    case '?': helpAndExit    = true; break;
                    default : badSwitches ~= "-" ~ c; break;
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

private:
    void parseDashDashArgument(string arg)
    {
        immutable vrf   = "--verify=";
        immutable resol = "--resol=";
        immutable hardf = "--hardfull=";

        if (arg == "--version") {
            versionAndExit = true;
        }
        else if (arg == "--help") {
            helpAndExit = true;
        }
        else if (arg == "--fullscreen") {
            forceSoftwareFullscreen = true;
        }
        else if (arg == "--coverage") {
            verifyCoverage = true;
        }
        else if (arg.startsWith(vrf)) {
            verifyFiles ~= new Filename(arg[vrf.length .. $]);
        }
        else if (arg.startsWith(resol)) {
            parseWantResolution(arg, resol);
            forceWindowed = true;
        }
        else if (arg.startsWith(hardf)) {
            parseWantResolution(arg, hardf);
            forceHardwareFullscreen = true;
        }
        else {
            badSwitches ~= arg;
        }
    }

    void parseWantResolution(string arg, string stripFromBeginning)
    {
        // this string is expected to be of the form "1234x567"
        string want_res = arg[stripFromBeginning.length .. $];
        try {
            string[] numbers = splitter(want_res, 'x').array();
            if (numbers.length == 2) {
                wantResolutionX = numbers[0].to!int;
                wantResolutionY = numbers[1].to!int;
            }
        }
        catch (Exception e) { }

        if (wantResolutionX == 0 || wantResolutionY == 0)
            badSwitches ~= arg;
    }
}
// end class



private bool
startsWith(string large, string small)
{
    return large.length >= small.length
     && large[0 .. small.length] == small;
}
