module gui.picker.bread;

/* Breadcrumb navigation
 * A series of buttons with one nested subdirectory per button.
 */

import std.algorithm;

import basics.help; // len
import basics.user;
import gui;
import file.filename;

class Breadcrumb : Element {
private:
    MutFilename  _basedir;
    MutFilename  _currentDir;
    TextButton[] _buttons;
    bool         _execute;

public:
    this(Geom g) { super(g); }

    @property bool execute() const { return _execute; }

    @property Filename basedir() const { return _basedir; }
    @property Filename basedir(Filename fn)
    {
        assert (fn);
        _basedir = fn.guaranteedDirOnly();
        if (! _currentDir || ! _currentDir.isChildOf(_basedir))
            currentDir = _basedir;
        return basedir;
    }

    @property Filename currentDir() const { return _currentDir; }
    @property Filename currentDir(Filename fn)
    {
        assert (basedir, "set basedir before setting current dir");
        MutFilename newCur = (fn && fn.isChildOf(basedir))
                           ? fn.guaranteedDirOnly() : basedir;
        if (newCur != _currentDir) {
            _currentDir = newCur;
            makeButtons();
        }
        return _currentDir;
    }

protected:
    override void calcSelf()
    {
        _execute = false;
        foreach (int i, Button b; _buttons)
            if (b.execute) {
                string s = currentDir.dirRootless;
                foreach (unused; 0 .. _buttons.len - i) {
                    // erase one dir from the end of the path
                    assert (s.length == 0 || s[$-1] == '/');
                    s = s[0 .. $-1];
                    while (s.length > 0 && s[$-1] != '/')
                        s = s[0 .. $-1];
                }
                currentDir = new Filename(s);
                _execute = true;
                break;
            }
    }

    override void drawSelf()
    {
        undrawSelf();
        super.drawSelf();
    }

private:
    void makeButtons()
    {
        reqDraw();
        rmAllChildren();
        _buttons = null;
        enum butXl = 80;
        float butX() { return _buttons.map!(b => b.xlg).sum; }
        int lastButtonIter = 0;
        int iter = basedir.dirRootless.len;
        for ( ; iter < currentDir.dirRootless.len; ++iter) {
            string cap = currentDir.dirRootless[lastButtonIter .. iter];
            if (cap.len > 0 && cap[$-1] == '/') {
                _buttons ~= new TextButton(new Geom(butX, 0, butXl, ylg), cap);
                lastButtonIter = iter;
            }
        }
        if (_buttons.len > 0) {
            _buttons[$-1].hotkey = keyMenuUpDir;
            _buttons.each!(b => addChild(b));
        }
        auto label = new Label(new Geom(butX + 4, 0, butXl, 20, From.LEFT));
        label.text = currentDir.dirRootless[lastButtonIter .. iter];
        addChild(label);
    }
}
