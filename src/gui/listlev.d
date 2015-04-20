module gui.listlev;

import std.algorithm;
import std.range;
import std.string;
import std.conv;

import glo = basics.globals;
import basics.user;
import file.filename;
import file.language;
import file.io;
import gui;
import level.metadata;

/*  package void -- module-scope function
 *  sort_filenames_by_order_txt_then_alpha(Filename[], Filename dir, bool)
 *
 *      Sorts the array by the ordering file found in in the dir (2nd arg).
 *      Set bool to true if we're sorting directories, not regular files.
 */

class ListLevel : ListFile {

public:

/*  this(from, x, y, xl, yl); -- will set file_sorter to using ordering file
 */
    void write_file_names(bool b) { _write_file_names = b; }
    void replay_style    (bool b) { _replay_style     = b; }
    void checkmark_style (bool b) { _checkmark_style  = b; }

    // why public: this isn't invoked by others, but passable as their crit
    static bool search_crit_level(in Filename fn)
    {
        return fn.file      != glo.file_level_dir_order
         &&    fn.file      != glo.file_level_dir_english
         &&    fn.file      != glo.file_level_dir_german
         && (  fn.extension == glo.ext_level
         ||    fn.extension == glo.ext_level_orig
         ||    fn.extension == glo.ext_level_lemmini);
    }

private:

    bool _write_file_names; // "dateiname: Levelname" anstatt "Levelname"
    bool _replay_style;     // Replay-Infos anfordern statt Levelinfos
    bool _checkmark_style;  // Einzelspieler: Geschaffte Levels abhaken



public:

this(int x, int y, int xl, int yl)
{
    this(Geom.From.TOP_LEFT, x, y, xl, yl);
}

this(Geom.From from, int x, int y, int xl, int yl)
{
    super(from, x, y, xl, yl);

    search_crit = &search_crit_level;
    file_sorter = delegate void(Filename[] arr) {
        sort_filenames_by_order_txt_then_alpha(file_list, current_dir, false);
    };
}



protected override void
add_file_button(in int nr_from_top, in int total_nr, in Filename fn)
{
    string button_text;
    // We're using ' ' to pad spaces before the digits whenever there are
    // numbers with different length to be printed. We should use a space
    // that's the same width as a digit. Maybe look back into this.
    if (! _write_file_names && ! _replay_style) {
        int max = files_total;
        int cur = total_nr + 1; // +1 more pleasing for non-programmers
        int      leading_spaces = 0;
        while (max /= 10) ++leading_spaces;
        while (cur /= 10) --leading_spaces;
        button_text ~= format("%s%d.",
                       ' '.repeat(leading_spaces), total_nr + 1);
        // filename or fetched level name will be written later on.
    }
    else {
        button_text ~= fn.file_no_ext_no_pre ~ ": ";
    }

    LevelMetaData lev;

    if (_replay_style) {
        // DTODOREPLAY
        /*
        Replay r(f);
        lev = new LevelMetaData(r.get_level_filename());
        button_text ~= lev.get_name();
        */
    }
    else {
        lev = new LevelMetaData(fn);
        button_text ~= lev.name;
    }

    TextButton t = new TextButton(0, nr_from_top * 20, xlg.to!int, 20);
    t.text = button_text;
    t.align_left = true;

    if (_checkmark_style) {
        const(Result) result = basics.user.get_level_result(fn);
        if (result) {
            if      (result.built     != lev.built)    t.check_frame = 3;
            else if (result.lix_saved == lev.initial)  t.check_frame = 1;
            else if (result.lix_saved >= lev.required) t.check_frame = 2;
            else                                       t.check_frame = 4;
        }
        else t.check_frame = 0;
    }
    button_push_back(t);
}



protected override void
add_flip_button()
{
    TextButton t = new TextButton(0,
        bottom_button() * 20, xlg.to!int, 20); // both 20 == height of button
    t.text = Lang.common_dir_flip_page.transl;
    button_push_back(t);
}

}
// end class ListLevel



// module scope, not member of class
package void
sort_filenames_by_order_txt_then_alpha(
    Filename[]  files,
    in Filename dir_with_order_file,
    bool we_sort_dirs // this is a little kludge, we add slashes to the
                      // entries in the order file to work with Filename::==
) {
    // Assume that the filenames to be sorted also start with
    // dir_with_oder_file and only have appended the order file's substring.
    string[] orders;
    bool file_exists = fill_vector_from_file_raw(orders, new Filename(
        dir_with_order_file.dir_rootful ~ glo.file_level_dir_order));

    Filename[] unsorted_slice = files;

    if (file_exists) {
        if (we_sort_dirs) {
            // sort the "go up one dir" button always to slot 1
            orders = ".." ~ orders;
            // dirs can be named as "somedir" or "somedir/", both shall work
            foreach (itr; orders)
                if (itr.length && itr[$-1] != '/')
                    itr ~= '/';
        }
        // Sort whatever is encountered in the order file to the beginning of
        // (Filename[] files). What is encountered earliest shall go at the
        // very beginning.
        foreach (orit; orders) {
            Filename fn = new Filename(dir_with_order_file.dir_rootful ~ orit);
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
