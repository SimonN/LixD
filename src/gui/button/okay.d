module gui.button.okay;

import basics.user;
import file.language;
import gui;

TextButton newOkay(Geom g)
{
    auto b = new TextButton(g, Lang.commonOk.transl);
    b.hotkey = basics.user.keyMenuOkay;
    return b;
}

TextButton newCancel(Geom g)
{
    auto b = new TextButton(g, Lang.commonCancel.transl);
    b.hotkey = basics.user.keyMenuExit;
    return b;
}
