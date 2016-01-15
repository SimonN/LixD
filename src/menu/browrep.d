module menu.browrep;

static import basics.user;
import file.filename;
import file.language;
import game.replay;
import gui;
import level.level;
import menu.browbase;

class BrowserReplay : BrowserBase {

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

    @property bool            gotoGame() const { return _gotoGame;     }
    @property inout(Replay)   replay()   inout { return _replayRecent; }
    @property inout(Level)    level()    inout { return _levelRecent;  }

protected:

    override void onFileHighlight(Filename fn)
    {
        assert (_delete);
        assert (_extract);
        if (fn is null) {
            _delete.hide();
            _extract.hide();
            _replayRecent = null;
            _levelRecent  = null;
        }
        else {
            _replayRecent   = new Replay(fn);
            _levelRecent    = new Level(_replayRecent.levelFilename);
            _extract.hidden = ! _replayRecent.containsLevel;
            _delete.show();
        }
        previewLevel(_levelRecent);
    }

    override void onFileSelect(Filename fn)
    {
        assert (_replayRecent !is null);
        assert (_levelRecent  !is null);
        if (_levelRecent.good) {
            basics.user.replayLastLevel = super.fileRecent;
            _gotoGame = true;
        }
    }

private:

    bool     _gotoGame;
    Replay   _replayRecent;
    Level    _levelRecent;

    TextButton _extract;
    TextButton _delete;

};
