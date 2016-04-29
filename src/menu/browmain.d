module menu.browmain;

import game.replay;
import file.filename;
import gui;
import level.level;
import menu.browbase;

class BrowserCalledFromMainMenu : BrowserBase {
private:
    bool     _gotoGame;
    Replay   _replayRecent;
    Level    _levelRecent;

public:
    // forward constructor :E
    this(T)(string title, Filename baseDir, T t) { super(title, baseDir, t); }

    @property bool          gotoGame()     const { return _gotoGame;     }
    @property inout(Replay) replayRecent() inout { return _replayRecent; }
    @property inout(Level)  levelRecent()  inout { return _levelRecent;  }

protected:
    @property bool   gotoGame(bool b)       { return _gotoGame     = b; }
    @property Replay replayRecent(Replay r) { return _replayRecent = r; }
    @property Level  levelRecent (Level l)  { return _levelRecent  = l; }
}

/* How to use the DeleteMixin:
 * Mix it into a browser. Implement the following method by filling out
 * title and msgs, but without adding buttons:
 *
 *  MsgBox newMsgBoxDelete();
 */
mixin template DeleteMixin()
{
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
            _boxDelete.addButton(Lang.commonNo.transl,  keyMenuDelete, () {
                _boxDelete = null;
            });
            addFocus(_boxDelete);
        }
    }
}
