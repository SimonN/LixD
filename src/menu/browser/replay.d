module menu.browser.replay;

import basics.user;
import file.filename;
import file.language;
import game.replay;
import gui;
import gui.picker;
import hardware.keyset;
import level.level;
import menu.browser.frommain;

static import basics.globals;

class BrowserReplay : BrowserCalledFromMainMenu {

    this()
    {
        super(Lang.browserReplayTitle.transl,
            basics.globals.dirReplays, PickerConfig!ReplayTiler());
        scope (success)
            super.highlight(basics.user.replayLastLevel);
        TextButton newInfo(float x, float y, string caption, KeySet hotkey)
        {
            auto b = new TextButton(new Geom(infoX + x*infoXl/2, y,
                infoXl/2, 40, From.BOTTOM_LEFT));
            b.text = caption;
            b.hotkey = hotkey;
            return b;
        }
        _delete  = newInfo(1, 60, Lang.browserDelete.transl, keyMenuDelete);
        _extract = newInfo(0, 60, "(extract)" /*Lang.browserExtract.transl*/,
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
        auto m = new MsgBox(Lang.saveBoxTitleDelete.transl);
        m.addMsg(Lang.saveBoxQuestionDeleteReplay.transl);
        m.addMsg(Lang.saveBoxDirectory.transl~ " " ~ fileRecent.dirRootful);
        m.addMsg(Lang.saveBoxFileName.transl ~ " " ~ fileRecent.file);
        return m;
    }
}
