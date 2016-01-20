module menu.browrep;

import basics.user;
import file.filename;
import file.language;
import game.replay;
import graphic.color;
import gui;
import level.level;
import menu.browmain;

class BrowserReplay : BrowserCalledFromMainMenu {

    this()
    {
        TextButton newInfo(float y, string caption, int hotkey)
        {
            auto b = new TextButton(new Geom(20, y, infoXl, 20, From.TOP_RIG));
            b.text = caption;
            b.hotkey = hotkey;
            b.undrawColor = color.guiM;
            return b;
        }
        _delete  = newInfo(infoY, Lang.browserDelete.transl, keyMenuDelete);
        _extract = newInfo(infoY + 20, "(extract)", // Lang.browserExtract.transl;
                           keyMenuExport);
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
            replayRecent = new Replay(fn);
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
