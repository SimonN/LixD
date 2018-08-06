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
import basics.user;
import file.filename;
import file.language;
import game.harvest;
import game.replay;
import gui;
import gui.picker;
import hardware.keyset;
import level.level;
import menu.browser.withlast;
import menu.lastgame;
import menu.verify;

static import basics.globals;

final class BrowserReplay : BrowserWithLastAndDelete {
private:
    Optional!ReplayToLevelMatcher _matcher; // empty if no replay previewed
    LabelTwo _labelPointedTo;
    TextButton _buttonPlayWithPointedTo;
    TextButton _buttonVerify;

public:
    this()
    {
        super(Lang.browserReplayTitle.transl, basics.globals.dirReplays,
            PickerConfig!(Breadcrumb, ReplayTiler)());
        commonConstructor();
        // Final class calls:
        super.highlight(basics.user.replayLastLevel);
    }

    this(Harvest ha, Optional!(const Replay) lastLoaded)
    {
        super(Lang.browserReplayTitle.transl, basics.globals.dirReplays,
            PickerConfig!(Breadcrumb, ReplayTiler)());
        commonConstructor();
        // Final class calls:
        super.addStatsThenHighlight(
            new StatsAfterReplay(super.newStatsGeom, ha, lastLoaded),
            basics.user.replayLastLevel);
    }

    // Override method with assert(false): Violates fundamental OO principles.
    // We shouldn't inherit from BrowserCalledFromMainMenu as long
    // as that forces us to implement such a levelRecent(). BrowserReplay's
    // caller (the main loop) should get the entire LevelToReplayMatcher
    // instead, then it can start a game from there.
    override @property inout(Level) levelRecent() inout { assert (false); }

    @property ReplayToLevelMatcher matcher()
    in { assert (_matcher.unwrap, "call this only when matcher exists"); }
    body { return _matcher.unwrap; }

protected:
    final override void onOnHighlightNone()
    {
        _matcher = null;
        _labelPointedTo.hide();
        _buttonPlayWithPointedTo.hide();
        previewNone();
    }

    final override void onHighlightWithLastGame(Filename fn, bool solved)
    in { assert (fn, "call onHighlightNone() instead"); }
    body {
        _matcher = some(new ReplayToLevelMatcher(fn));
        previewLevel(matcher.preferredLevel);
        _buttonPlayWithPointedTo.shown = matcher.pointedToIsGood;

        if (! solved && ! matcher.pointedToFilename.empty
            && matcher.pointedToFilename.unwrap.rootless.length
            > dirLevels.rootless.length
        ) {
            // We show this even if the level is bad. It's probably
            // most important then
            _labelPointedTo.show();
            _labelPointedTo.value = matcher.pointedToFilename.unwrap.rootless[
                dirLevels.rootless.length .. $];
        }
        else {
            _labelPointedTo.hide();
        }
    }

    final override void onHighlightWithoutLastGame(Filename fn)
    {
        onHighlightWithLastGame(fn, false);
    }

    override void onPlay(Filename fn)
    {
        assert (_matcher.unwrap);
        if (matcher.includedIsGood
            // Ideally, we don't choose this silently when included is bad.
            // But how to handle doubleclick on replay then? Thus, for now:
            || matcher.pointedToIsGood
        ) {
            basics.user.replayLastLevel = super.fileRecent;
            gotoGame = true;
        }
    }

    override void calcSelf()
    {
        super.calcSelf();
        if (_buttonPlayWithPointedTo.execute
            && _matcher.unwrap && matcher.pointedToIsGood
        ) {
            // like onFileSelect, but for pointedTo
            matcher.forcePointedTo();
            basics.user.replayLastLevel = super.fileRecent;
            gotoGame = true;
        }
        else if (_buttonVerify.execute) {
            basics.user.replayLastLevel = currentDir;
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
        _labelPointedTo = new LabelTwo(new Geom(infoX, infoY + 20f,
            infoXl, 20), "\u27F6"); // unicode long arrow right
        _buttonPlayWithPointedTo = newInfo(1, 100,
            Lang.browserReplayPointedTo.transl, keyMenuEdit);
        _buttonVerify = newInfo(1, 60,
            Lang.browserReplayVerifyDir.transl, keyMenuNewLevel);

        addChildren(_labelPointedTo,
            _buttonPlayWithPointedTo, _buttonVerify);
    }
}
