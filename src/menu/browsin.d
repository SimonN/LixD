module menu.browsin;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import gui;
import level.level;
import menu.browbase;

class BrowserSingle : BrowserBase {

public:

//  this();

    @property bool            goto_game() const { return _goto_game;    }
    @property inout(Level)    level()     inout { return _level_recent; }
    @property inout(Filename) filename()  inout { return _file_recent;  }

private:

    bool     _goto_game;
    Filename _file_recent;
    Level    _level_recent;



public
this()
{
    super(Lang.browser_single_title.transl,
        basics.globals.dir_levels,
        basics.user.single_last_level,
        super.UseCheckmarks.yes,
        super.UseReplayStyle.no
    );
}



protected override void
on_file_highlight(Filename fn)
{
    _file_recent  = fn;
    _level_recent = fn is null ? null : new Level(_file_recent);
    preview_level(_level_recent);
}



protected override void
on_file_select(Filename fn)
{
    assert (_file_recent  !is null);
    assert (_level_recent !is null);
    // the super class guarantees that on_file_select is only called after
    // on_file_highlight has been called with the same fn immediately before
    if (_level_recent.good)
        _goto_game = true;
}

}
// end class
