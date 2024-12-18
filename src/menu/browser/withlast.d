module menu.browser.withlast;

import std.algorithm;

import optional;

import basics.globals;
import opt = file.option.allopts;
import file.language;
import file.filename;
import gui;
import gui.picker;
import file.key.set;
import level.level;
import menu.browser.frommain;

class BrowserWithDelete : BrowserCalledFromMainMenu {
private:
    Button _delete;
    Optional!MsgBox _boxDelete;

public:
    this(T)(string title, Filename baseDir, in float ylOfNameplate, T t)
    {
        super(title, baseDir, ylOfNameplate, t);
        _delete = new TextButton(newDeleteButtonGeom,
            Lang.browserDelete.transl);
        _delete.hotkey = opt.keyMenuDelete.value;
        addChildren(_delete);
    }

protected:
    abstract MsgBox newMsgBoxDelete();
    abstract void onOnHighlightNone();
    abstract void onOnHighlight(Filename);

    Geom newDeleteButtonGeom() const
    {
        return new Geom(infoX, 20, infoXl/2,
            40, From.BOTTOM_LEFT);
    }

    final override void onHighlightNone()
    {
        _delete.hide();
        onOnHighlightNone();
    }

    final override void onHighlight(Filename fn)
    {
        _delete.show();
        onOnHighlight(fn);
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
        if (_delete.execute && ! gotoMainMenu) {
            assert (_boxDelete.empty);
            assert (fileRecent);
            MsgBox box = newMsgBoxDelete();
            _boxDelete = some(box);
            box.addButton(Lang.browserDelete.transl, opt.keyMenuOkay.value,
                () {
                    assert (fileRecent);
                    deleteFileRecentHighlightNeighbor();
                    _boxDelete = null;
                });
            box.addButton(Lang.commonCancel.transl,
                KeySet(opt.keyMenuDelete.value, opt.keyMenuExit.value),
                () { _boxDelete = none; });
            addFocus(box);
        }
    }
}
