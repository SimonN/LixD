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

import basics.alleg5;
import net.versioning;
import file.filename;

enum Runmode {
    INTERACTIVE,
    VERIFY,
    EXPORT_IMAGES,
    PRINT_AND_EXIT
}

private void writeHelp()
{
    write(
        "-h or -? or --help     print this help and exit\n",
        "-v or --version        print version of Lix and exit\n",
        "--allegro-version      print version of Allegro DLLs and exit\n",
        "-w                     run windowed at 640x480\n",
        "--resol=800x600        run windowed at the given resolution\n",
        "--fullscreen           use software fullscreen mode (good Alt+Tab)\n",
        "--hardfull=1600x900    use hardware fullscreen at given resolution\n",
        "--image level.txt      export all given levels as images\n",
        "--verify replay.txt    verify all given replays for solvability\n",
        "--verify replaydir     verify all replays in all given directories\n",
        "--coverage replaydir   like --verify, then print levels without proof\n",
        "level.txt              play the given level\n",
        "replay.txt             load the included level, watch the replay\n",
        "--pointed-to repl.txt  load the pointed-to level, watch the replay\n",
        "level.txt replay.txt   load the given level, watch the given replay\n",
    );
}

class Cmdargs {
public:
    bool forceWindowed;
    bool forceSoftwareFullscreen;
    bool forceHardwareFullscreen;
    bool versionAndExit;
    bool allegroVersionAndExit;
    bool helpAndExit;
    bool preferPointedTo; // interactive mode with exactly 1 replay argument
    bool exportImages; // image-exporting mode with any number of arguments
    bool verifyReplays; // verifying mode with any number of arguments
    bool printCoverage; // verifying mode plus coverage statistics

    int  wantResolutionX;
    int  wantResolutionY;

    private string[] badSwitches;
    Filename[] fileArgs;

    this(string[] args)
    {
        if (args.length < 2) {
            // argument 0 is the program name, loop over the extra ones only
            return;
        }
        bool moreArgsAllowed = true;
        foreach (arg; args[1 .. $]) {
            if (moreArgsAllowed && arg == "--")
                moreArgsAllowed = false;
            else if (moreArgsAllowed && arg.startsWith("--"))
                parseDashDashArgument(arg);
            else if (moreArgsAllowed && arg.startsWith("-"))
                // allow arguments chained like -nw
                foreach (c; arg[1 .. $]) switch (c) {
                    case 'h': helpAndExit    = true; break;
                    case 'v': versionAndExit = true; break;
                    case 'w': forceWindowed  = true; break;
                    case '?': helpAndExit    = true; break;
                    default : badSwitches ~= "-" ~ c; break;
                }
            else
                fileArgs ~= new ArgumentFilename(arg);
        }
    }

    @property Runmode mode() const
    {
        if (! good || versionAndExit || allegroVersionAndExit || helpAndExit)
            return Runmode.PRINT_AND_EXIT;
        else if (verifyReplays)
            return Runmode.VERIFY;
        else if (exportImages)
            return Runmode.EXPORT_IMAGES;
        else
            return Runmode.INTERACTIVE;
    }

    @property bool good() const
    {
        if (! badSwitches.empty)
            return false;
        if (preferPointedTo + verifyReplays + exportImages > 1)
            // Choose at most one mode
            return false;
        if (verifyReplays || exportImages)
            // any number of file arguments are allowed
            return true;
        if (preferPointedTo && fileArgs.length != 1)
            return false;
        // For interactive mode, you may specify you at most 2 files:
        // The first is a level or a replay. If the first is a level,
        // then the second may be a replay to run against the first level.
        return (fileArgs.length <= 2 && fileArgs.all!(fn => fn.fileExists));
    }

    @property bool forceSomeDisplayMode() const pure nothrow @nogc
    {
        return forceWindowed
            || forceSoftwareFullscreen || forceHardwareFullscreen;
    }

    void printNoninteractiveOutput()
    {
        // always print the version; -v is basically used to enter this
        // function without triggering any additional cases. However, if
        // only the version is to be printed, print it without decoration.
        if (versionAndExit && ! helpAndExit && good)
            writeln(gameVersion);
        else
            writeln("Lix version ", gameVersion);

        if (allegroVersionAndExit)
            writeln("Allegro DLL version ", allegroDLLVersion());
        if (helpAndExit)
            writeHelp();
        if (good)
            return;

        if (badSwitches != null) {
            foreach (sw; badSwitches)
                writeln("Error: `", sw, "' is an unknown switch.");
        }
        if (verifyReplays + exportImages + preferPointedTo > 1)
            writeln("Error: Found more than 1 of `--pointed-to', `--image', ",
                    "`--verify', `--coverage'.");
        if (! verifyReplays && ! exportImages) {
            // Interactive mode with bad command-line.
            if (fileArgs.length > 2)
                writeln("Error: Interactive mode takes at most 2 ",
                        "file arguments, not ", fileArgs.length, ".");
            else if (preferPointedTo && fileArgs.length != 1)
                writeln("Error: --pointed-to takes exactly one file argument.");
            else
                foreach (fn; fileArgs.filter!(fn => ! fn.fileExists))
                    if (fn.dirExists)
                        writeln("Error: `", fn.rootless,
                                "' is a directory, not a level or replay.");
                    else
                        writeln("Error: Level or replay file `", fn.rootless,
                                "' not found.");
        }
        writeln("Try -h or -? for help.");
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
        else if (arg == "--allegro-version") {
            allegroVersionAndExit = true;
        }
        else if (arg == "--help") {
            helpAndExit = true;
        }
        else if (arg == "--fullscreen") {
            forceSoftwareFullscreen = true;
        }
        else if (arg == "--pointed-to") {
            preferPointedTo = true;
        }
        else if (arg == "--image") {
            exportImages = true;
        }
        else if (arg == "--coverage") {
            verifyReplays = true;
            printCoverage = true;
        }
        else if (arg == "--verify") {
            verifyReplays = true;
        }
        else if (arg.startsWith(vrf)) {
            verifyReplays = true;
            // backwards compat: support --verify=filename;
            fileArgs ~= new ArgumentFilename(arg[vrf.length .. $]);
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

private bool
startsWith(string large, string small)
{
    return large.length >= small.length
     && large[0 .. small.length] == small;
}
