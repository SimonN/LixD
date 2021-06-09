module menu.browser.network;

import basics.globals;
import file.option;
import file.language;
import file.filename;
import gui;
import gui.picker;
import level.level;
import menu.browser.frommain;

class BrowserNetwork : BrowserCalledFromMainMenu {
private:
    Level _levelRecent;

public:
    this()
    {
        super(Lang.browserNetworkTitle.transl,
            basics.globals.dirLevels, super.pickerConfig());
        scope (success)
            super.highlight(file.option.networkLastLevel);
    }

    override @property inout(Level) levelRecent() inout
    {
        return _levelRecent;
    }

protected:
    override void onHighlightNone()
    {
        _levelRecent = null;
        previewNone();
    }

    override void onHighlight(Filename fn)
    in { assert (fn, "call onHighlightNone() instead"); }
    do {
        _levelRecent = new Level(fileRecent);
        previewLevel(_levelRecent);
    }

    override void onPlay(Filename fn)
    {
        assert (fileRecent  !is null);
        assert (_levelRecent !is null);
        // the super class guarantees that on_file_select is only called after
        // onFileHighlight has been called with the same fn immediately before
        if (_levelRecent.playable) {
            file.option.networkLastLevel = fileRecent;
            gotoGame = true;
        }
    }
}
