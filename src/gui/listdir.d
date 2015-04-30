module gui.listdir;

/* In C++-A4-Lix, this was its own class, unrelated to ListFile.
 * It shares so much though, that in D/A5 Lix, it's derived from it.
 * ListFile is slightly beefed up and got hooks to accomodate this.
 */

import std.conv;
import std.typecons;

import basics.user; // hotkey for dir_up button
import graphic.color;
import gui;
import file.filename;
import file.language;
import file.search;

class ListDir : ListFile {

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
    Button dir_up;

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
    if (dir_up) destroy(dir_up);
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
    if (! file.search.dir_exists(current_dir)
     || ! current_dir.is_child_of(_base_dir)) {
        current_dir = base_dir;       // again goes through load_current_dir()
        return OnDirLoadAction.ABORT; // abort the original pass through it
    }
    if (dir_up) {
        rm_child(dir_up);
        destroy(dir_up);
        dir_up = null;
    }
    if (super.current_dir == _base_dir) {
        bottom_button = ylg.to!int / 20 - 1;
    }
    else {
        bottom_button = ylg.to!int / 20 - 2;
        TextButton dir_up = new TextButton(new Geom(0, 0, xlg, 20, From.TOP));
        dir_up.text = Lang.common_dir_parent.transl;
        dir_up.undraw_color = color.gui_m;
        dir_up.set_hotkey(basics.user.key_me_up_dir);
        dir_up.on_click = &set_current_dir_to_parent_dir;
        add_child(dir_up);
    }
    return OnDirLoadAction.CONTINUE;
}



private void make_textbutton(int y, string str)
{
    TextButton b = new TextButton(new Geom(0, y, xlg, 20, Geom.From.TOP));
    b.text = str;
    button_push_back(b);
}



protected override void
add_file_button(in int from_top, in int total, in Filename fn)
{
    // the first slot may have been taken by the dir_up button.
    immutable plus_y = dir_up ? 20 : 0;
    make_textbutton(20 * from_top + plus_y, fn.dir_innermost);
}



protected override void
add_flip_button()
{
    make_textbutton(ylg.to!int - 20, Lang.common_dir_flip_page.transl);
}



protected override void
on_file_highlight()
{
    // the file buttons represent dirs that can be switched into
    string str = current_dir.rootless;
    if (! str.length) return;
    if (str[$-1] != '/') str ~= '/';

    current_dir = new Filename(str);
    if (_list_file) _list_file.current_dir = current_dir;
}

}
// end class ListDir
