module menu.browser.replay;

/*
 * This must be refactored: Even though we inherit
 * from BrowserCalledFromMainMenu, we may not implement levelRecent() inout
 * despite the base class's promise. Reason: _matcher requires mutability.
 * For now, we have assert(false) in levelRecent() and thus violate OO.
 * See comment at that method.
 */

import optional;

import basics.globals : dirLevels;
import opt = file.option.allopts;
import file.filename;
import file.language;
import file.replay;
import gui;
import gui.picker;
import file.key.set;
import level.level;
import menu.browser.withlast;
import menu.repmatch;
import menu.verify;

static import basics.globals;

final class BrowserReplay : BrowserWithDelete {
private:
    Optional!ReplayToLevelMatcher _matcher; // empty if no replay previewed
    TextButton _buttonPlayWithPointedTo;
    TextButton _buttonVerify;

public:
    this()
    {
        super(Lang.browserReplayTitle.transl, basics.globals.dirReplays,
            ylOfNameplateForReplays, PickerConfig!(Breadcrumb, ReplayTiler)());
        commonConstructor();
        // Final class calls:
        super.highlight(opt.replayLastLevel.value);
    }

    // Override method with assert(false): Violates fundamental OO principles.
    // We shouldn't inherit from BrowserCalledFromMainMenu as long
    // as that forces us to implement such a levelRecent(). BrowserReplay's
    // caller (the main loop) should get the entire LevelToReplayMatcher
    // instead, then it can start a game from there.
    override @property inout(Level) levelRecent() inout { assert (false); }

    @property ReplayToLevelMatcher matcher()
    in { assert (! _matcher.empty, "call this only when matcher exists"); }
    do { return _matcher.front; }

protected:
    final override void onOnHighlightNone()
    {
        _matcher = null;
        _buttonPlayWithPointedTo.hide();
        previewNone();
    }

    final override void onOnHighlight(Filename fn)
    in { assert (fn, "call onHighlightNone() instead"); }
    do {
        _matcher = some(new ReplayToLevelMatcher(fn));
        foreach (lv; matcher.preferredLevel)
            preview(matcher.replay, fn, lv);
        _buttonPlayWithPointedTo.shown = matcher.pointedToIsGood;
    }

    override void onPlay(Filename fn)
    {
        assert (! _matcher.empty);
        if (matcher.includedIsGood
            // Ideally, we don't choose this silently when included is bad.
            // But how to handle doubleclick on replay then? Thus, for now:
            || matcher.pointedToIsGood
        ) {
            opt.replayLastLevel = super.fileRecent;
            gotoGame = true;
        }
    }

    override void calcSelf()
    {
        import hardware.mouse;
        super.calcSelf();
        if (_buttonPlayWithPointedTo.execute
            && ! _matcher.empty && matcher.pointedToIsGood
        ) {
            // like onFileSelect, but for pointedTo
            matcher.forcePointedTo();
            opt.replayLastLevel = super.fileRecent;
            gotoGame = true;
        }
        else if (_buttonVerify.execute) {
            opt.replayLastLevel = currentDir;
            auto win = new VerifyMenu(currentDir);
            addFocus(win);
        }
    }

    override MsgBox newMsgBoxDelete()
    {
        auto m = new MsgBox(Lang.saveBoxTitleDelete.transl);
        m.addMsg(Lang.saveBoxQuestionDeleteReplay.transl);
        m.addMsg(Lang.saveBoxDirectory.transl~ " " ~ fileRecent.dirRootless);
        m.addMsg(Lang.saveBoxFileName.transl ~ " " ~ fileRecent.file);
        return m;
    }

private:
    void commonConstructor()
    {
        buttonPlayYFromBottom = 100f;
        TextButton newInfo(float x, float y, string caption, KeySet hotkey)
        {
            auto b = new TextButton(new Geom(infoX + x*infoXl/2, y,
                infoXl/2, 40, From.BOTTOM_LEFT));
            b.text = caption;
            b.hotkey = hotkey;
            return b;
        }
        _buttonPlayWithPointedTo = newInfo(1, 100,
            Lang.browserReplayPointedTo.transl, opt.keyMenuEdit.value);
        _buttonVerify = newInfo(1, 60,
            Lang.browserReplayVerifyDir.transl, opt.keyMenuNewLevel.value);

        addChildren(_buttonPlayWithPointedTo, _buttonVerify);
    }
}
