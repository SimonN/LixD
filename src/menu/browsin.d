module menu.browsin;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import gui;
import level.level;
import menu.browbase;

class BrowserSingle : BrowserBase {

    // stuff here



public this()
{
    super(Lang.browser_single_title.transl,
        basics.globals.dir_levels,
        basics.user.single_last_level,
        super.UseCheckmarks.yes,
        super.UseReplayStyle.no
    );
}



protected override void
on_file_highlight(in Filename fn)
{
    preview_level(new Level(fn));
}

}
// end class
