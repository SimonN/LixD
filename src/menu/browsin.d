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

    @property bool         gotoGame() const { return _gotoGame;    }
    @property inout(Level) level()    inout { return _levelRecent; }

    this()
    {
        super(Lang.browserSingleTitle.transl,
            basics.globals.dirLevels,
            basics.user.singleLastLevel,
            ListLevel.LevelCheckmarks.yes,
            ListLevel.ReplayToLevelName.no
        );
    }

protected:

    override void onFileHighlight(Filename fn)
    {
        _fileRecent  = fn;
        _levelRecent = fn is null ? null : new Level(_fileRecent);
        previewLevel(_levelRecent);
    }

    override void onFileSelect(Filename fn)
    {
        assert (_fileRecent  !is null);
        assert (_levelRecent !is null);
        // the super class guarantees that on_file_select is only called after
        // onFileHighlight has been called with the same fn immediately before
        if (_levelRecent.good) {
            basics.user.singleLastLevel = _fileRecent;
            _gotoGame = true;
        }
    }

private:

    bool     _gotoGame;
    Filename _fileRecent;
    Level    _levelRecent;

}
// end class
