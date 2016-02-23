module gui.listlev;

/*  class ListLevel : Listfile
 *
 *      This reads only LevelMetaData, not entire Level objects.
 */

import std.algorithm;
import std.range;
import std.string;
import std.conv;

import glo = basics.globals;
import basics.user;
import file.filename;
import file.io;
import game.replay; // ReplayToLevelName; possibly to be moved into a subclass
import gui;
import level.metadata;

/*  package void -- module-scope function
 *  sortFilenamesByOrderTxtThenAlpha(Filename[], Filename dir, bool)
 *
 *      Sorts the array by the ordering file found in in the dir (2nd arg).
 *      Set bool to true if we're sorting directories, not regular files.
 */

class ListLevel : ListFile {

public:

    // DTODO: turn these into polymorphic subclasses maybe
    enum WriteFilenames    { yes = true, no = false }
    enum LevelCheckmarks   { yes = true, no = false }
    enum ReplayToLevelName { yes = true, no = false }

    // why public: this isn't invoked by others, but passable as their crit
    static bool searchCrit_level(in Filename fn)
    {
        return fn.file      != glo.fileLevelDirOrder
         &&    fn.file      != glo.fileLevelDirEnglish
         &&    fn.file      != glo.fileLevelDirGerman
         && (  fn.extension == glo.filenameExtLevel
         ||    fn.extension == glo.filenameExtLevelOrig
         ||    fn.extension == glo.filenameExtLevelLemmini);
    }

private:

    WriteFilenames    _writeFileNames;
    LevelCheckmarks   _levelCheckmarks;
    ReplayToLevelName _replayToLevelName;

public:

this(Geom g,
    WriteFilenames    wfn = WriteFilenames.no,
    LevelCheckmarks   lcm = LevelCheckmarks.no,
    ReplayToLevelName rtl = ReplayToLevelName.no)
{
    super(g);
    searchCrit = &searchCrit_level;
    fileSorter = delegate void(Filename[] arr) {
        sortFilenamesByOrderTxtThenAlpha(arr, currentDir, false);
    };
    _writeFileNames = wfn;
    _levelCheckmarks = lcm;
    _replayToLevelName = rtl;
}



protected override Button
newFileButton(int nr_from_top, int total_nr, Filename fn)
{
    string buttonText;
    // We're using ' ' to pad spaces before the digits whenever there are
    // numbers with different length to be printed. We should use a space
    // that's the same width as a digit. Maybe look back into this.
    if (_writeFileNames)
        buttonText ~= fn.fileNoExtNoPre ~ ": ";
    else if (_levelCheckmarks) {
        int max = filesTotal;
        int cur = total_nr + 1; // +1 more pleasing for non-programmers
        int      leadingSpaces = 0;
        while (max /= 10) ++leadingSpaces;
        while (cur /= 10) --leadingSpaces;
        buttonText ~= format("%s%d. ",
                       ' '.repeat(leadingSpaces), total_nr + 1);
        // filename or fetched level name will be written later on.
    }
    LevelMetaData lev;
    if (_replayToLevelName) {
        auto r = Replay.loadFromFile(fn);
        lev = new LevelMetaData(r.levelFilename); // use pointed-to level
        if (! lev.fileExists)
        lev = new LevelMetaData(fn); // use included level
        // DTODO: There is a bug remaining here.
        // If the file exists on disk, LevelMetaData.fileExists is true.
        // But we aren't interested in whether the file exists, but whether
        // the level is nonempty. We'd normally test the included level first.
        // But that test (LevelMetaData(fn).fileExists) would always return
        // true right now, even when only a replay is inside, and no level.
        // Therefore, as a workaround, we test the pointed-to level first,
        // even though that's not preferred when playing back the replay.
        buttonText ~= format("%s (%s)", lev.name, r.playerLocalName);
    }
    else {
        lev = new LevelMetaData(fn);
        buttonText ~= lev.name;
    }
    TextButton t = new TextButton(new Geom(0, nr_from_top * 20, xlg, 20));
    t.text = buttonText;
    t.alignLeft = true;

    if (_levelCheckmarks) {
        const(Result) result = basics.user.getLevelResult(fn);
        t.checkFrame = result is null         ? 0
            : result.built    != lev.built    ? 3
            : result.lixSaved >= lev.required ? 2
            : 0; // 0, and not 4, here. We don't want to display the little
                 // ring for looked-at-but-didn't-solve. It makes people sad!
    }
    return t;
}

}
// end class ListLevel



// module scope, not member of class
package void
sortFilenamesByOrderTxtThenAlpha(
    Filename[]  files,
    in Filename dir_with_order_file,
    bool we_sort_dirs // this is a little kludge, we add slashes to the
                      // entries in the order file to work with Filename::==
) {
    // Assume that the filenames to be sorted also start with
    // dir_with_oder_file and only have appended the order file's substring.
    string[] orders;
    try
        orders = fillVectorFromFileRaw(new Filename(
            dir_with_order_file.dirRootful ~ glo.fileLevelDirOrder));
    catch (Exception e) {
        // do nothing, missing ordering file is not an error at all
    }

    Filename[] unsorted_slice = files;

    if (orders.length) {
        if (we_sort_dirs) {
            // sort the "go up one dir" button always to slot 1
            orders = ".." ~ orders;
            // dirs can be named as "somedir" or "somedir/", both shall work
            foreach (ref itr; orders)
                if (itr.length && itr[$-1] != '/')
                    itr ~= '/';
        }
        // Sort whatever is encountered in the order file to the beginning of
        // (Filename[] files). What is encountered earliest shall go at the
        // very beginning.
        foreach (orit; orders) {
            Filename fn = new Filename(dir_with_order_file.dirRootful ~ orit);
            Filename[] found = unsorted_slice.find(fn);
            if (found.length) {
                swap(found[0], unsorted_slice[0]);
                unsorted_slice = unsorted_slice[1 .. $];
                if (! unsorted_slice.length) break;
            }
        }
    }
    // done processing the ordering file

    // sort the remaining items alphabetically
    unsorted_slice.sort();
}
