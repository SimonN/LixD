module menu.browser.withlast;

import std.algorithm;

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
    Optional!StatsAfterGame _lastGame; // if exist => never killed
    bool _showLastGameOnNextHighlight = false; // workaround for 2x highlights

public:
    this(T)(string title, Filename baseDir, T t)
    {
        super(title, baseDir, t);
        _delete = new TextButton(newDeleteButtonGeom,
            Lang.browserDelete.transl);
        _delete.hotkey = basics.user.keyMenuDelete;
        addChildren(_delete);
    }

protected:
    abstract MsgBox newMsgBoxDelete();
    abstract void onOnHighlightNone();
    abstract void onHighlightWithLastGame(Filename, bool solved);
    abstract void onHighlightWithoutLastGame(Filename);

    // Call this from the final class.
    void addStatsThenHighlight(StatsAfterGame lgs, Filename fn)
    {
        // The final class creates lgs and thereby already saves the trophies.
        _lastGame = some(lgs);
        addChild(lgs);
        _showLastGameOnNextHighlight = true;
        super.highlight(fn);
    }

    final Geom newStatsGeom() const
    {
        return new Geom(20, infoY + 20, infoXl, 60, From.TOP_RIGHT);
    }

    Geom newDeleteButtonGeom() const
    {
        return new Geom(infoX, 20, infoXl/2,
            40, From.BOTTOM_LEFT);
    }

    final override void onHighlightNone()
    {
        // Keep _showLastGameOnNextHighlight because the single call to
        // super.highlight() in addHarvest...() will call onHighlightNone,
        // and only then onHighlight(Filename). Then later, onHighlight(Fn)
        // will set _showLastGameOnNextHighlight to false.
        _delete.hide();
        _lastGame.dispatch.hide();
        onOnHighlightNone();
    }

    final override void onHighlight(Filename fn)
    {
        _delete.show();
        if (_showLastGameOnNextHighlight) {
            _lastGame.dispatch.show();
            onHighlightWithLastGame(fn, _lastGame.unwrap.solved);
        }
        else {
            _lastGame.dispatch.hide();
            onHighlightWithoutLastGame(fn);
        }
        _showLastGameOnNextHighlight = false;
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
