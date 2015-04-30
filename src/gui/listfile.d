module gui.listfile;

/* A file lister.
 * ListLevel and ListBitmap are derived from this.
 */

import std.array;
import std.algorithm;
import std.conv;
import std.typecons;

import basics.user; // custom keys for navigating the file list
import graphic.color;
import gui;
import file.filename;
import file.search;
import hardware.keyboard;

class ListFile : Frame {

public:

    alias FileFinder = Filename[] function(in Filename);
    alias SearchCrit = bool function(in Filename);
    alias FileSorter = void delegate(Filename[]);

/*  static SearchCrit default_file_finder;
 *  static SearchCrit default_search_crit;
 *         FileSorter default_file_sorter;
 *
 *  void load_dir(in Filename, const int which_page = 0);
 *
 *      This is the main function, should be called by the browsers often.
 *
 *  void highlight            (in Filename);
 *  void highlight_file_number(int);
 *  void highlight_move       (int);
 */
    @property void       file_finder(FileFinder ff) { _file_finder = ff; }
    @property void       search_crit(SearchCrit sc) { _search_crit = sc; }
    @property void       file_sorter(FileSorter fs) { _file_sorter = fs; }
    @property FileFinder file_finder() const { return _file_finder; }
    @property SearchCrit search_crit() const { return _search_crit; }
    @property FileSorter file_sorter() const { return _file_sorter; }

    @property bool   clicked()             { return _clicked;             }
    @property Button button_last_clicked() { return _button_last_clicked; }
    @property int    files_total()         { return files.length.to!int;  }
    @property int    page()                { return _page;                }

    deprecated("Do we still need this in the browser?")
    const(Filename) get_file(int i) { return files[i]; }

    @property void            current_dir(in Filename fn) { load_dir(fn);  }
    @property const(Filename) current_dir()  const { return _current_dir;  }
    @property const(Filename) current_file() const { return _current_file; }

    @property int bottom_button()      { return _bottom_button;     }
    @property int bottom_button(int i) { return _bottom_button = i; }

    void set_activate_clicked_button() { _activate_clicked_button = true; }

    @property bool use_hotkeys()       { return _use_hotkeys;     }
    @property bool use_hotkeys(bool b) { return _use_hotkeys = b; }

protected:

/*  final void buttons_clear();
 *  final void button_push_back(Button b);
 */
    abstract void add_file_button (in int from_top, in int total, in Filename);
    abstract void add_flip_button ();

    enum OnDirLoadAction { CONTINUE, RELOAD, ABORT }

    // Alter the listed directory contents if necessary, by overriding
    OnDirLoadAction on_dir_load() { return OnDirLoadAction.CONTINUE; }
    void on_file_highlight() { }
    void put_to_file_list(Filename s) { files ~= s; }

    // retrieve the raw list of files. Useful when overriding on_dir_load()
    // to sort the files before buttons are drawn.
    @property inout(Filename[]) file_list() inout { return files; }

/*  override void calc_self();
 *  override void draw_self();
 */
private:

    int  _page;
    int  _bottom_button;
    int  file_number_at_top;
    bool bottom_button_flips_page;

    bool _use_hotkeys;
    bool _activate_clicked_button;
    bool _clicked;

    Filename[] files;
    Button[]   buttons;
    Button     _button_last_clicked;

    Rebindable!(const Filename) _current_dir;
    Rebindable!(const Filename) _current_file; // need not be in current_dir

    FileFinder _file_finder;
    SearchCrit _search_crit;
    FileSorter _file_sorter;



public:

this(Geom g)
{
    super(g);
    _file_finder   = &default_file_finder;
    _search_crit   = &default_search_crit;
    _file_sorter   = &default_file_sorter;
    _bottom_button = g.yl.to!int / 20 - 1;
    _use_hotkeys   = true;
    undraw_color   = color.gui_m;
}



public static Filename[]
default_file_finder(in Filename where)
{
    return file.search.find_files(where);
}



public static bool
default_search_crit(in Filename fn)
{
    // use everything
    return true;
};



public void
default_file_sorter(Filename[] arr)
{
    // sort by pure filename
    arr.sort();
};



public void
load_dir(in Filename to_load, in int which_page = 0)
{
    assert (to_load, "dirname to load in file list is null");
    if (! _current_dir || _current_dir.dir_rootless != to_load.dir_rootless) {
        _current_dir = new Filename(to_load.dir_rootless);
        _page = which_page;
    }
    load_current_dir();
}



protected final void
buttons_clear()
{
    foreach (b; buttons) {
        rm_child(b);
        destroy(b);
    }
    buttons = null;
    req_draw();
}



protected final void
button_push_back(Button b)
{
    b.undraw_color = color.gui_m;
    buttons ~= b;
    add_child(b);
}



public void
highlight(in Filename fn)
{
    highlight_file_number(files.countUntil(fn).to!int);
}



public void
highlight_file_number(in int pos)
{
    assert (pos >= -1);
    assert (pos < files.length.to!int);

    if (pos == -1) {
        // file to be highlighted is not in the directory
        _current_file = current_dir;
        _button_last_clicked = null;
        return;
    }
    // Main progression of this function: the file was found.
    // If not on the current page, swap the page.
    if (bottom_button_flips_page) {
        if (pos <  file_number_at_top
         || pos >= file_number_at_top + bottom_button) {
            _page = pos / bottom_button;
            load_current_dir();
        }
    }
    _current_file = files[pos];

    // Highlight-Button anklicken und Zeiger darauf setzen
    Button but = buttons[pos - file_number_at_top];
    if (_activate_clicked_button) {
        if (button_last_clicked == but) {
            but.set_on(! but.get_on());
        }
        else if (button_last_clicked) {
            button_last_clicked.set_off();
            but.set_on();
        }
        else {
            but.set_on();
        }
    }
    _button_last_clicked = but;
    on_file_highlight();
}



public void highlight_move(in int by)
{
    if (by == 0) return;
    if (! files.length) return;

    // Do we have a valid highlight right now?
    int pos = files.countUntil(_current_file).to!int;
    immutable int last = (files.length - 1).to!int;

    if (pos != -1) {
        // if first file and by < 0, select last one.
        // if last file  and by > 0, select first one.
        if      (pos == 0    && by < 0) pos = last;
        else if (pos == last && by > 0) pos = 0;
        else {
            // If not first or last file, move by the given number of steps,
            // but stop on the first/last entries. Don't wrap around even
            // with steps left!
            int by_left = by;
            do {
                if (by > 0) { ++pos; --by_left; }
                else        { --pos; ++by_left; }
            } while (by_left != 0 && pos != 0 && pos != last);
        }
    }
    // If none of the files were highlighted before the method call,
    // start on the bottom or top. Do not move yet.
    else {
        if (by < 0) pos = last;
        else        pos = 0;
    }
    highlight_file_number(pos);
}



private void
load_current_dir()
{
    assert (_current_dir, "can't load null dir");
    req_draw();
    bottom_button_flips_page = false;
    buttons_clear();
    _button_last_clicked = null;

    Filename[] files;

    try files = _file_finder(_current_dir)
        .filter!(a => _search_crit(a)).array();
    catch (Exception e) {
        // don't do anything, maybe on_dir_load() will do something
        // on nonexistant dir
    }
    _file_sorter(files);

    // Hook/event function: derived classes may alter file via overriding
    // the empty on_dir_load() and calls to add_to_file_list().
    final switch (on_dir_load()) {
        case OnDirLoadAction.CONTINUE: break;
        case OnDirLoadAction.RELOAD: load_current_dir(); return;
        case OnDirLoadAction.ABORT: return;
    }

    // create one button per file
    if (_page * _bottom_button >= files.length) _page = 0;
    file_number_at_top = _page * _bottom_button;
    // The following (while) doeis: If there is more than one page, fill
    // each page fully with file buttons. Therefore, the last page may get
    // filled with entries from the second-to-last page.
    while (_page > 0 && file_number_at_top + _bottom_button > files.length)
        --file_number_at_top;

    int next_from_file = file_number_at_top;
    for (int i = 0; i < bottom_button
     && next_from_file < files.length; ++i) {
        add_file_button(i, next_from_file, files[next_from_file]);
        ++next_from_file;
    }
    // Add page-flipping button, unless we're filling the first page exactly
    if (next_from_file == files.length - 1 && page == 0) {
        add_file_button(_bottom_button, next_from_file, files[next_from_file]);
        ++next_from_file;
    }
    else if (next_from_file < files.length || page > 0) {
        add_flip_button();
        bottom_button_flips_page = true;
    }

    // Maybe highlight a button
    if (_current_file && _current_dir.dir_rootful == _current_file.dir_rootful)
        for (int i = 0; i < buttons.length; ++i)
            if (i != _bottom_button || ! bottom_button_flips_page)
                if (_current_file == files[file_number_at_top + i]) {
                    _button_last_clicked = buttons[i];
                    _button_last_clicked.set_on();
                }
}



protected override void
calc_self()
{
    _clicked = false;
    foreach (int i, b; buttons) {
        if (b.clicked) {
            // page-switching button has been clicked?
            if (i == _bottom_button && bottom_button_flips_page) {
                ++_page;
                if (_page * _bottom_button >= files.length) _page = 0;
                load_current_dir();
                _clicked = false;
                break;
            }
            // otherwise, a normal file button has been clicked
            else {
                highlight_file_number(file_number_at_top + i);
                _clicked = true;
                break;
            }
        }
    }
    // end foreach Button

    if (_use_hotkeys && _activate_clicked_button && buttons.length) {
        bool any_movement_with_keys = true;
        if      (key_once(basics.user.key_me_up_1))   highlight_move(-1);
        else if (key_once(basics.user.key_me_up_5))   highlight_move(-5);
        else if (key_once(basics.user.key_me_down_1)) highlight_move(1);
        else if (key_once(basics.user.key_me_down_5)) highlight_move(5);
        else any_movement_with_keys = false;
        if (any_movement_with_keys) _clicked = true;
    }
}



protected override void
draw_self()
{
    undraw_self();
    super.draw_self();
}

}
// end class
