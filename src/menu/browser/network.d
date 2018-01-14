module menu.browser.network;

import basics.globals;
import basics.user;
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
            super.highlight(basics.user.networkLastLevel);
    }

    override @property inout(Level) levelRecent() inout
    {
        return _levelRecent;
    }

protected:
    override void onFileHighlight(Filename fn)
    {
        _levelRecent = fn is null ? null : new Level(fileRecent);
        previewLevel(_levelRecent);
    }

    override void onFileSelect(Filename fn)
    {
        assert (fileRecent  !is null);
        assert (_levelRecent !is null);
        // the super class guarantees that on_file_select is only called after
        // onFileHighlight has been called with the same fn immediately before
        if (_levelRecent.good) {
            basics.user.networkLastLevel = fileRecent;
            gotoGame = true;
        }
    }
}
