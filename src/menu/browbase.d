module menu.browbase;

import std.conv;

import file.filename;
import file.language;
import gui;
import level.level;
import menu.preview;

class BrowserBase : Window {

    enum UseCheckmarks  { yes, no };
    enum UseReplayStyle { yes, no };

/*  this(string window_title,
 *      in Filename base_dir,
 *      in Filename current_file,
 *      bool use_checkmarks = false,
 *      bool replay_style   = false); -- see below for implementation
 */
    void set_button_play_text(in string s) { button_play.text = s; }

    @property bool goto_play()      const { return _goto_play;      }
    @property bool goto_main_menu() const { return _goto_main_menu; }

    @property auto base_dir()     const { return dir_list.base_dir;     }
    @property auto current_file() const { return lev_list.current_file; }

/*  void set_current_dir_to_parent_dir()
 *
 *  void load_dir(in Filename, bool call_on_file_highlight = true);
 *  void highlight_nothing();
 *
 *  void set_preview_y_and_yl(in int y, in int yl);
 */
    void preview_level(Level l) { preview.level = l;    }
    void clear_preview()        { preview.level = null; }

    @property int  info_y() const   { return _info_y; }
    @property void info_y(in int i) { _info_y = i;    }

    void on_file_highlight(in Filename) {}
    void on_file_select   (in Filename) {}

private:

    bool _goto_play;
    bool _goto_main_menu;

    int        _info_y;
    Filename   file_recent; // only used for highlighting, not selecting

    ListDir    dir_list;
    ListLevel  lev_list;

    Frame      cover_frame; // looks like the lev_list's outer frame
    Label[]    cover_desc;  // the cover text in file-empty dirs

    TextButton button_play;
    TextButton button_exit;
    Preview    preview;



public:

this(
       string      window_title,
    in Filename    base_dir,
       Filename    current_file,
    UseCheckmarks  use_checkmarks = UseCheckmarks.no,
    UseReplayStyle replay_style   = UseReplayStyle.no
) {
    super(0, 0, Geom.screen_xlg.to!int, Geom.screen_ylg.to!int, title);

    immutable int lxlg = to!int(Geom.screen_xlg - 100 - 140 - 4*20);

    dir_list = new ListDir  (20,  40, 100,  420);
    lev_list = new ListLevel(140, 40, lxlg, 420);

    button_play = new TextButton(Geom.From.TOP_RIGHT,    20,  40, 140,  40);
    preview     = new Preview   (Geom.From.TOP_RIGHT,    20, 100, 140, 100);
    button_exit = new TextButton(Geom.From.BOTTOM_RIGHT, 20,  20, 140,  40);

    // preview_yl = 100 or 93 doesn't fit exactly for the 640x480 resolution,
    // the correct value there would have been 92. But it'll make the image
    // longer by 1, without costing quality, and it fits the strange constants
    // in C++-A4 Lix's level.cpp.

    dir_list.base_dir    = base_dir;
    dir_list.current_dir = current_file;
    lev_list.highlight(current_file);

    button_play.text = Lang.browser_play.transl;
    button_exit.text = Lang.common_back.transl;
    button_exit.on_click = () { _goto_main_menu = true; };

    add_children(preview, dir_list, lev_list, button_play, button_exit);
}



public void set_preview_y_and_yl(in int y, in int yl)
{
    preview.geom = new Geom(preview.geom.from,
        preview.xg, y, preview.xlg, preview.ylg);
    req_draw();
}

protected override void
calc_self()
{
}

}
// end class
