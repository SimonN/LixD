module menu.browser.withlast;

import optional;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import game.harvest;
import gui;
import gui.picker;
import hardware.keyset;
import level.level;
import menu.browser.frommain;
import menu.lastgame;

class BrowserWithLastAndDelete : BrowserCalledFromMainMenu {
private:
    Button _delete;
    Optional!MsgBox _boxDelete;
    Optional!SingleplayerLastGameStats _lastGame; // if exist => never killed

public:
    this(T)(string title, Filename baseDir, T t)
    {
        super(title, baseDir, t);
        _delete = new TextButton(new Geom(infoX, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserDelete.transl);
        _delete.hotkey = basics.user.keyMenuDelete;
        addChildren(_delete);
    }

    // Call this after constructing all sub-/superclasses,
    // probably from the code that newed the browser. Don't call during ctor.
    // Reason is that the ctor calls highlightFile.
    // And this function must be called after all subclasses are constructed.
    @property void harvest(Harvest ha)
    {
        // Creating _lastGame saves the trophies.
        auto lg = new SingleplayerLastGameStats(
            new Geom(20, infoY + 20, infoXl, 60, From.TOP_RIGHT), ha);
        _lastGame = some(lg);
        addChild(lg);
        onHighlightWithLastGame(fileRecent, lg.solved);
    }

protected:
    abstract MsgBox newMsgBoxDelete();
    abstract void onOnHighlightNone();
    abstract void onHighlightWithLastGame(Filename, bool solved);
    abstract void onHighlightWithoutLastGame(Filename);

    final override void onHighlightNone()
    {
        _delete.hide();
        _lastGame.dispatch.hide();
        onOnHighlightNone();
    }

    final override void onHighlight(Filename fn)
    {
        _delete.show();
        _lastGame.dispatch.hide();
        onHighlightWithoutLastGame(fn);
    }

    override void calcSelf()
    {
        super.calcSelf();
        calcDeleteMixin();
    }

private:
    void calcDeleteMixin()
    {
        assert (_delete);
        if (_delete.execute) {
            assert (_boxDelete.empty);
            assert (fileRecent);
            _boxDelete = some(newMsgBoxDelete());
            _boxDelete.unwrap.addButton(Lang.browserDelete.transl,
                keyMenuOkay, () {
                    assert (fileRecent);
                    deleteFileRecentHighlightNeighbor();
                    _boxDelete = null;
                });
            _boxDelete.unwrap.addButton(Lang.commonNo.transl,
                KeySet(keyMenuDelete, keyMenuExit), () { _boxDelete = none; });
            addFocus(_boxDelete.unwrap);
        }
    }
}
