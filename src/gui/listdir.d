module gui.listdir;

/* In C++-A4-Lix, this was its own class, unrelated to ListFile.
 * It shares so much though, that in D/A5 Lix, it's derived from it.
 * ListFile is slightly beefed up and got hooks to accomodate this.
 */

import std.string; // formatting an assert message
import std.conv;
import std.typecons;

import basics.user; // hotkey for dir_up button
import graphic.color;
import gui;
import file.filename;
import file.language;
import file.log;
import file.search;

// see the comment in override on_dir_load() for why this is a final class
final class ListDir : ListFile {

public:

/*  this(      x, y, xl, yl);
 *  this(from, x, y, xl, yl);
 */
    @property const(Filename) base_dir() const {
        return _base_dir; }
    @property override const(Filename) current_dir() const {
        return super.current_dir; }
/*  @property void current_dir(in Filename);
 *  @property void base_dir   (in Filename);
 *  void set_current_dir_to_parent_dir();
 */
    @property auto list_file_to_control(ListFile l) { return _list_file = l; }
    @property auto list_file_to_control() const     { return _list_file;     }

private:

    @disable @property const(Filename) current_file();

    Rebindable!(const Filename) _base_dir;
    TextButton dir_up;

    ListFile _list_file; // this is reloaded when our dir changes



public this(Geom g)
{
    super(g);

    file_finder = &(file.search.find_dirs);
    search_crit = function bool(in Filename fn) {
        return fn.file != "." && fn.file != "..";
    };
    file_sorter = delegate void(Filename[] arr) {
        sort_filenames_by_order_txt_then_alpha(arr, current_dir, true);
    };
    super.use_hotkeys = false;
    // but the (this) class shall still check for the dir-up-change key
}



public ~this()
{
    if (dir_up) {
        rm_child(dir_up);
        destroy(dir_up);
    }
}


public @property void
base_dir(in Filename fn)
{
    assert (fn, "base directory can't be set to null");
    _base_dir = new Filename(fn.dir_rootless);
}



public void
set_current_dir_to_parent_dir()
{
    string str = current_dir.dir_rootless;
    if (str.length && str[$-1] == '/')
        str = str[0 .. $-1];
    while (str.length && str[$-1] != '/')
        str = str[0 .. $-1];

   current_dir = new Filename(str);
   if (_list_file) _list_file.current_dir = current_dir;
}



public override @property void
current_dir(in Filename fn)
{
    assert (_base_dir, "base directory not set, can't load a dir without it");
    assert (fn, "dirname to load in dir list is null");

    bool good_dir     = dir_exists(fn) && fn.is_child_of(_base_dir);
    const Filename f  = good_dir ? fn : _base_dir;
    super.current_dir = f;
    if (_list_file)
        _list_file.current_dir = f;
}



// This gets run after the file search in (super), but before it adds
// its own buttons. This is exactly where we should add our own button,
// and tweak the number of buttons (super) shall add.
protected override super.OnDirLoadAction
on_dir_load()
{
    assert (_base_dir, "base directory not set, can't load a dir without it");
    // this must happen even on a non-existing dir
    if (dir_up) {
        rm_child(dir_up);
        destroy(dir_up);
        dir_up = null;
    }
    // this assert is the reason for finality of this class
    assert (children.length == 0,
        format("there should be 0 children, not %d, before any adding buttons",
        children.length));

    // sanity checks
    immutable bool bad_exists  = ! file.search.dir_exists(current_dir);
    immutable bool bad_child   = ! current_dir.is_child_of(_base_dir);

    if (bad_exists || bad_child) {
        if (! file.search.dir_exists(base_dir)) {
            // this is extremely bad, abort immediately
            Log.logf("Base dir `%s' is missing. Broken installation?",
                base_dir.rootful);
            return OnDirLoadAction.ABORT;
        }
        else if (bad_exists)
            Log.logf("`%s' doesn't exist. Falling back to `%s'.",
            current_dir.rootful, base_dir.rootful);
        else if (bad_child)
            Log.logf("`%s' is not a subdir of `%s'. Falling back to that.",
            current_dir.rootful, base_dir.rootful);

        current_dir = base_dir;       // again goes through load_current_dir()
        return OnDirLoadAction.ABORT; // abort the original pass through it
    }

    if (super.current_dir == _base_dir) {
        bottom_button = ylg.to!int / 20 - 1;
    }
    else {
        bottom_button = ylg.to!int / 20 - 2;
        assert (dir_up is null);
        dir_up = new TextButton(new Geom(0, 0, xlg, 20, From.TOP));
        dir_up.text = Lang.common_dir_parent.transl;
        dir_up.undraw_color = color.gui_m;
        dir_up.hotkey = basics.user.key_me_up_dir;
        add_child(dir_up);
        // We don't put the children-deleting function onto dir_up.on_click,
        // because I fear bugs from removing array elements during foreach.
        // Instead, I check for this in calc_self.
    }
    return OnDirLoadAction.CONTINUE;
}



private final TextButton make_textbutton(int y, string str)
{
    TextButton b = new TextButton(new Geom(0, y, xlg, 20, Geom.From.TOP));
    b.text = str;
    return b;
}



protected override Button
new_file_button(int from_top, int total, in Filename fn)
{
    // the first slot may have been taken by the dir_up button.
    immutable plus_y = dir_up ? 20 : 0;
    return make_textbutton(20 * from_top + plus_y, fn.dir_innermost);
}



protected override Button
new_flip_button()
{
    return make_textbutton(ylg.to!int - 20, Lang.common_dir_flip_page.transl);
}



protected override void
on_file_highlight()
{
    // the file buttons represent dirs that can be switched into
    string str = super.current_file.rootless;
    if (! str.length) return;
    if (str[$-1] != '/') str ~= '/';

    current_dir = new Filename(str);
    if (_list_file)
        _list_file.current_dir = current_dir;
}



protected override void
calc_self()
{
    super.calc_self();
    if (dir_up && dir_up.clicked) {
        set_current_dir_to_parent_dir();
        this.clicked = true;
    }
}

}
// end class ListDir
