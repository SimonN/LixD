module menu.browrep;

import basics.user;
import file.filename;
import file.language;
import game.replay;
import gui;
import level.level;
import menu.browmain;

class BrowserReplay : BrowserCalledFromMainMenu {

    this()
    {
        super(Lang.browserReplayTitle.transl,
            basics.globals.dirReplays,
            ListLevel.LevelCheckmarks.no,
            ListLevel.ReplayToLevelName.yes);
        scope (success)
            super.highlight(basics.user.replayLastLevel);
        TextButton newInfo(float y, string caption, int hotkey)
        {
            auto b = new TextButton(new Geom(20, y, infoXl, 20, From.TOP_RIG));
            b.text = caption;
            b.hotkey = hotkey;
            return b;
        }
        _delete  = newInfo(infoY, Lang.browserDelete.transl, keyMenuDelete);
        _extract = newInfo(infoY + 20, "(extract)", // Lang.browserExtract.transl;
                           keyMenuExport);
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
            replayRecent = Replay.loadFromFile(fn);
            levelRecent  = new Level(fn); // open the replay file as level
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

    override void calcSelf()
    {
        super.calcSelf();
        calcDeleteMixin();
    }

private:

    TextButton _extract;

    mixin DeleteMixin deleteMixin;

    MsgBox newMsgBoxDelete()
    {
        auto m = new MsgBox(Lang.browserBoxDeleteReplayTitle.transl);
        m.addMsg(Lang.browserBoxDeleteReplayQuestion.transl);
        m.addMsg(Lang.browserBoxDirectory.transl~ " " ~ fileRecent.dirRootful);
        m.addMsg(Lang.browserBoxFileName.transl ~ " " ~ fileRecent.file);
        return m;
    }
}
