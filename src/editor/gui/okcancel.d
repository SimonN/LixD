module editor.gui.okcancel;

import gui;
import level.level;
import hardware.mouse;

abstract class OkCancelWindow : Window {
private:
    TextButton _okay;
    TextButton _cancel;

public:
    this(Geom g, string title)
    {
        super(g, title);
        _okay   = newOkay  (new Geom(20, 50, 100, 20, From.BOT_RIG));
        _cancel = newCancel(new Geom(20, 20, 100, 20, From.BOT_RIG));
        addChildren(_okay, _cancel);
    }

    final @property bool done() const
    {
        return _okay.execute || mouseClickRight || _cancel.execute;
    }

    final writeChangesTo(Level level)
    {
        if (_okay.execute || mouseClickRight) {
            assert (level);
            selfWriteChangesTo(level);
        }
    }

protected:
    abstract void selfWriteChangesTo(Level);
}
