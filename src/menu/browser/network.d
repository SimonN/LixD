module menu.browser.network;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import gui;
import gui.picker;
import level.level;
import menu.browser.frommain;
import menu.search;

class BrowserNetwork : BrowserCalledFromMainMenu {
private:
    Level _levelRecent;

public:
    this()
    {
        super(Lang.browserNetworkTitle.transl,
            basics.globals.dirLevels, PickerConfig!LevelTiler());
        createSearchButton(new Geom(infoX, 20, infoXl/2, 40, From.BOT_LEF));
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

    override void workSelf()
    {
        super.workSelf();
        workSearchMixin();
    }

private:
    mixin SearchMixin searchMixin;
}
