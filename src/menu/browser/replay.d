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
private:
    Replay _replayRecent;
    Level _included;
    Level _pointedTo;
    TextButton _buttonPlayWithPointedTo;
    TextButton _extract;
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
        _buttonPlayWithPointedTo = newInfo(1, 100, "pointedTo", keyMenuEdit);
        _delete  = newInfo(1, 60, Lang.browserDelete.transl, keyMenuDelete);
        _extract = newInfo(0, 60, "(extract)" /*Lang.browserExtract.transl*/,
                           keyMenuExport);
        addChildren(_buttonPlayWithPointedTo, _delete, _extract);
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
        assert (_extract);
        if (fn is null) {
            _replayRecent = null;
            _included = null;
            _pointedTo = null;
            _buttonPlayWithPointedTo.hide();
            _delete.hide();
            _extract.hide();
        }
        else {
            _forcePointedTo = false;
            _replayRecent = Replay.loadFromFile(fn);
            _included = new Level(fn); // open the replay file as level
            _pointedTo = new Level(_replayRecent.levelFilename);
            _delete.show();
            _buttonPlayWithPointedTo.hidden = ! _pointedTo.good;
            _extract.hidden = ! _included.nonempty;
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
