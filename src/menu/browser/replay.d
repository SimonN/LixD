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
import menu.verify;

static import basics.globals;

class BrowserReplay : BrowserCalledFromMainMenu {
private:
    Replay _replayRecent;
    Level _included;
    Level _pointedTo;
    TextButton _buttonPlayWithPointedTo;
    TextButton _buttonVerify;
    bool _forcePointedTo;

    mixin DeleteMixin deleteMixin;

public:
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
        // DTODOLANG: caption these two buttons, even if they're hacks
        _buttonPlayWithPointedTo = newInfo(1, 100, "pointedTo", keyMenuEdit);
        _buttonVerify = newInfo(1, 60, "Verify Dir", KeySet());

        _delete  = newInfo(0, 20, Lang.browserDelete.transl, keyMenuDelete);
        addChildren(_buttonPlayWithPointedTo, _buttonVerify, _delete);
    }

    override @property inout(Level) levelRecent() inout
    {
        return (_pointedTo !is null && _pointedTo.good
            && (_forcePointedTo || _included is null || ! _included.good))
            ? _pointedTo : _included;
    }

    override @property inout(Replay) replayRecent() inout
    {
        return _replayRecent;
    }

protected:

    override void onFileHighlight(Filename fn)
    {
        assert (_delete);
        if (fn is null) {
            _replayRecent = null;
            _included = null;
            _pointedTo = null;
            _buttonPlayWithPointedTo.hide();
            _delete.hide();
        }
        else {
            _forcePointedTo = false;
            _replayRecent = Replay.loadFromFile(fn);
            _included = new Level(fn); // open the replay file as level
            _pointedTo = new Level(_replayRecent.levelFilename);
            _delete.show();
            _buttonPlayWithPointedTo.shown = _pointedTo.good;
            // _extract.shown = _included.nonempty; -- _extract not yet impl
            // Even without _extract implemented, we need _included,
            // for this.levelRecent().
        }
        previewLevel(levelRecent);
    }

    override void onFileSelect(Filename fn)
    {
        assert (replayRecent !is null);
        assert (levelRecent  !is null);
        _forcePointedTo = false;
        if (levelRecent.good) {
            basics.user.replayLastLevel = super.fileRecent;
            gotoGame = true;
        }
    }

    override void calcSelf()
    {
        super.calcSelf();
        calcDeleteMixin();
        if (_buttonPlayWithPointedTo.execute && replayRecent !is null) {
            // like onFileSelect, but for pointedTo
            _forcePointedTo = true;
            if (levelRecent && levelRecent.good) {
                basics.user.replayLastLevel = super.fileRecent;
                gotoGame = true;
            }
        }
        else if (_buttonVerify.execute) {
            basics.user.replayLastLevel = currentDir;
            auto win = new VerifyMenu(currentDir);
            addFocus(win);
        }
    }

private:
    MsgBox newMsgBoxDelete()
    {
        auto m = new MsgBox(Lang.saveBoxTitleDelete.transl);
        m.addMsg(Lang.saveBoxQuestionDeleteReplay.transl);
        m.addMsg(Lang.saveBoxDirectory.transl~ " " ~ fileRecent.dirRootless);
        m.addMsg(Lang.saveBoxFileName.transl ~ " " ~ fileRecent.file);
        return m;
    }
}
