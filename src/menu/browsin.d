module menu.browsin;

import basics.globals;
import basics.user;
import file.language;
import gui;
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

}
// end class
