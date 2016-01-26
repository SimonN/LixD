module menu.browsin;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import gui;
import level.level;
import menu.browmain;

class BrowserSingle : BrowserCalledFromMainMenu {

public:

    this()
    {
        super(Lang.browserSingleTitle.transl,
            basics.globals.dirLevels,
            ListLevel.LevelCheckmarks.yes,
            ListLevel.ReplayToLevelName.no
        );
        super.highlight(basics.user.singleLastLevel);
    }

protected:

    override void onFileHighlight(Filename fn)
    {
        levelRecent = fn is null ? null : new Level(fileRecent);
        previewLevel(levelRecent);
    }

    override void onFileSelect(Filename fn)
    {
        assert (fileRecent  !is null);
        assert (levelRecent !is null);
        // the super class guarantees that on_file_select is only called after
        // onFileHighlight has been called with the same fn immediately before
        if (levelRecent.good) {
            basics.user.singleLastLevel = fileRecent;
            gotoGame = true;
        }
    }

}
// end class
