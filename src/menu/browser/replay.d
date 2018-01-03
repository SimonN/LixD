module menu.browser.replay;

/*
 * This must be refactored: Even though we inherit
 * from BrowserCalledFromMainMenu, we may not implement levelRecent() inout
 * despite the base class's promise. Reason: _matcher requires mutability.
 * For now, we have assert(false) in levelRecent() and thus violate OO.
 * See comment at that method.
 */

import basics.globals : dirLevels;
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
    ReplayToLevelMatcher _matcher; // may be null if no replay previewed

    LabelTwo _labelPointedTo;
    TextButton _buttonPlayWithPointedTo;
    TextButton _buttonVerify;
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
        _labelPointedTo = new LabelTwo(new Geom(infoX, infoY + 20f,
            infoXl, 20), "\u27F6"); // unicode long arrow right
        _buttonPlayWithPointedTo = newInfo(1, 100, "pointedTo", keyMenuEdit);
        _buttonVerify = newInfo(1, 60, "Verify Dir", KeySet());

        _delete  = newInfo(0, 20, Lang.browserDelete.transl, keyMenuDelete);
        addChildren(_labelPointedTo,
            _buttonPlayWithPointedTo, _buttonVerify, _delete);
    }

    // Override method with assert(false): Violates fundamental OO principles.
    // We shouldn't inherit from BrowserCalledFromMainMenu as long
    // as that forces us to implement such a levelRecent(). BrowserReplay's
    // caller (the main loop) should get the entire LevelToReplayMatcher
    // instead, then it can start a game from there.
    override @property inout(Level) levelRecent() inout { assert (false); }
    @property inout(ReplayToLevelMatcher) matcher() inout { return _matcher; }

protected:
    override void onFileHighlight(Filename fn)
    {
        assert (_delete);
        if (fn is null) {
            _matcher = null;
            _labelPointedTo.hide();
            _buttonPlayWithPointedTo.hide();
            _delete.hide();
        }
        else {
            _matcher = new ReplayToLevelMatcher(fn);
            _delete.show();
            _buttonPlayWithPointedTo.shown = _matcher.pointedToIsGood;
            if (_matcher.pointedToFilename.rootless.length
                > dirLevels.rootless.length
            ) {
                // We show this even if the level is bad. It's probably
                // most important then
                _labelPointedTo.show();
                _labelPointedTo.value = _matcher.pointedToFilename.rootless[
                    dirLevels.rootless.length .. $];
            }
            else {
                _labelPointedTo.hide();
            }
        }
        previewLevel(_matcher ? _matcher.preferredLevel : null);
    }

    override void onFileSelect(Filename fn)
    {
        assert (_matcher);
        if (_matcher.includedIsGood) {
            basics.user.replayLastLevel = super.fileRecent;
            gotoGame = true;
        }
    }

    override void calcSelf()
    {
        super.calcSelf();
        calcDeleteMixin();
        if (_buttonPlayWithPointedTo.execute
            && _matcher && _matcher.pointedToIsGood
        ) {
            // like onFileSelect, but for pointedTo
            _matcher.forcePointedTo();
            basics.user.replayLastLevel = super.fileRecent;
            gotoGame = true;
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
