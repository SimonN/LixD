module gui.button.okay;

import file.option;
import file.language;
import gui;

TextButton newOkay(Geom g)
{
    auto b = new TextButton(g, Lang.commonOk.transl);
    b.hotkey = file.option.keyMenuOkay;
    return b;
}

TextButton newCancel(Geom g)
{
    auto b = new TextButton(g, Lang.commonCancel.transl);
    b.hotkey = file.option.keyMenuExit;
    return b;
}
