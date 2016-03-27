module gui.picker.bread;

/* Breadcrumb navigation
 * A series of buttons with one nested subdirectory per button.
 */

import std.algorithm;

import gui;
import file.filename;

class Breadcrumb : Element {
private:
    MutFilename  _basedir;
    MutFilename  _currentDir;
    TextButton[] _buttons;
    Label        _label;
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
        if (_buttons.length == 0)
            return;
        if (_buttons[$-1].execute) {
            assert (currentDir != basedir);
            assert (currentDir.isChildOf(basedir));
            string s = currentDir.dirRootless[0 .. $-1];
            while (s.length > 0 && s[$-1] != '/')
                s = s[0 .. $-1];
            currentDir = new Filename(s);
            makeButtons();
            _execute = true;
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
        rmAllChildren();
        if (currentDir != basedir)
            _buttons = [ new TextButton(new Geom(this.geom), "../") ];
        else
            _buttons = null;
        _buttons.each!(b => addChild(b));
        reqDraw();
    }
}
