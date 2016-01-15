module menu.browrep;

static import basics.user;
import file.filename;
import file.language;
import game.replay;
import gui;
import level.level;
import menu.browmain;

class BrowserReplay : BrowserCalledFromMainMenu {

    this()
    {
        T newInfo(T)(float y)
            if (is (T : Element))
        {
            return new T(new Geom(20, y, infoXl, 20, From.TOP_RIGHT));
        }
        _delete = newInfo!TextButton(infoY);
        _delete.text   = "(delete)";// Lang.browserDelete.transl;
        _delete.hotkey = basics.user.keyMenuDelete;
        _extract = newInfo!TextButton(infoY + 20);
        _extract.text   = "(extract)"; // Lang.browserExtract.transl;
        _extract.hotkey = basics.user.keyMenuExport;
        super(Lang.browserReplayTitle.transl,
            basics.globals.dirReplays,
            basics.user.replayLastLevel,
            ListLevel.LevelCheckmarks.no,
            ListLevel.ReplayToLevelName.yes);
        addChildren(_delete, _extract);
    }

protected:

    override void onFileHighlight(Filename fn)
    {
        assert (_delete);
        assert (_extract);
        if (fn is null) {
            replayRecent = null;
            levelRecent  = null;
            _delete.hide();
            _extract.hide();
        }
        else {
            replayRecent   = new Replay(fn);
            levelRecent    = new Level(fn); // open the replay file as level
            _delete.show();
            _extract.hidden = ! levelRecent.nonempty;
            if (! levelRecent.nonempty)
                levelRecent = new Level(replayRecent.levelFilename);
        }
        previewLevel(levelRecent);
    }

    override void onFileSelect(Filename fn)
    {
        assert (replayRecent !is null);
        assert (levelRecent  !is null);
        if (levelRecent.good) {
            basics.user.replayLastLevel = super.fileRecent;
            gotoGame = true;
        }
    }

private:

    TextButton _extract;
    TextButton _delete;

};
