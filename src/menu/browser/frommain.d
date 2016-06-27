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
