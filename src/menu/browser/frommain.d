module menu.browser.frommain;

import game.replay;
import file.filename;
import gui;
import level.level;
import menu.browser.select;

class BrowserCalledFromMainMenu : BrowserHighlightSelect {
private:
    bool _gotoGame;

public:
    // forward constructor :E
    this(T)(string title, Filename baseDir, T t) { super(title, baseDir, t); }

    @property bool gotoGame() const { return _gotoGame; }
    @property inout(Replay) replayRecent() inout { return null; }
    abstract @property inout(Level) levelRecent() inout;

protected:
    @property bool gotoGame(bool b) { return _gotoGame = b; }
}

/* How to use the DeleteMixin:
 * Mix it into a browser. Implement the following method by filling out
 * title and msgs, but without adding buttons:
 *
 *  MsgBox newMsgBoxDelete();
 *
 * In the using class's calcSelf, call calcDeleteMixin.
 */
mixin template DeleteMixin()
{
    import hardware.keyset;

    private Button _delete;
    private MsgBox _boxDelete;

    private void calcDeleteMixin()
    {
        assert (_delete);
        if (_delete.execute) {
            assert (! _boxDelete);
            assert (fileRecent);
            _boxDelete = newMsgBoxDelete();
            _boxDelete.addButton(Lang.browserDelete.transl, keyMenuOkay, () {
                assert (fileRecent);
                deleteFileRecentHighlightNeighbor();
                _boxDelete = null;
            });
            _boxDelete.addButton(Lang.commonNo.transl,
                KeySet(keyMenuDelete, keyMenuExit),
                () { _boxDelete = null; });
            addFocus(_boxDelete);
        }
    }
}

/*
 * How to use the SearchMixin:
 * Mix it into a browser. In the browser's constructor, call
 * createSearchButton with the desired geom. In the browser's workSelf(),
 * call workSearchMixin().
 */
mixin template SearchMixin()
{
    private Button _button;
    private SearchWindow _window;

    private void createSearchButton(Geom g)
    {
        _button = new TextButton(g, Lang.browserSearch.transl);
        _button.hotkey = basics.user.keyMenuSearch;
        _button.onExecute = () {
            assert (! _window);
            _window = new SearchWindow();
            addFocus(_window);
        };
        addChild(_button);
    }

    private void workSearchMixin()
    {
        assert (_button);
        if (_window && _window.done) {
            if (_window.selectedResult)
                highlight(_window.selectedResult);
            _window = null;
        }
    }
}
