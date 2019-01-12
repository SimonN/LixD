module gui.picker.bread;

/* Breadcrumb navigation
 * A series of buttons with one nested subdirectory per button.
 *
 * This doesn't check whether directories exist! Ls would throw when
 * we search a nonexisting dir, but Breadcrumb won't.
 */

import std.algorithm;

import basics.help; // len
import file.option;
import gui;
import file.filename;

class Breadcrumb : Element {
private:
    Filename _baseDir;
    MutFilename  _currentDir;
    TextButton[] _buttons;
    Label        _label;
    bool         _execute;

public:
    // Picker's search button shall have same shape
    enum butXl = 100f;

    this(Geom g, Filename aBaseDir)
    in { assert (aBaseDir !is null); }
    body {
        super(g);
        _label = new Label(new Geom(0, 0, butXl*3/2, 20, From.LEFT));
        _baseDir = aBaseDir;
        addChild(_label);
    }

    @property bool execute() const { return _execute; }

    @property Filename baseDir() const { return _baseDir; }

    @property Filename currentDir() const
    out (ret) { assert (ret is null || ret.file == ""); }
    body { return _currentDir; }

    @property Filename currentDir(Filename fn)
    {
        assert (baseDir, "set basedir before setting current dir");
        MutFilename newCur = (fn && fn.isChildOf(baseDir))
            ? makeAllowed(fn.guaranteedDirOnly) : baseDir;
        if (newCur != _currentDir) {
            _currentDir = newCur;
            clearButtons();
            immutable int usedChars = makeButtons();
            _label.move(butX + 4, 0);
            _label.text = currentDir.dirRootless[usedChars .. $];
        }
        return _currentDir;
    }

protected:
    override void calcSelf()
    {
        _execute = false;
        foreach (const size_t numSlashesToSkip, Button b; _buttons) {
            if (! b.execute)
                continue;
            assert (currentDir.dirRootless.startsWith(baseDir.dirRootless));
            string s = currentDir.dirRootless[baseDir.dirRootless.length .. $];
            foreach (_; 0 .. numSlashesToSkip)
                s.findSkip("/");
            currentDir = new VfsFilename(
                currentDir.dirRootless[0 .. $ - s.length]);
            _execute = true;
            break;
        }
    }

    override void drawSelf()
    {
        undrawSelf();
        super.drawSelf();
    }

    final float butX() const { return _buttons.map!(b => b.xlg).sum; }

    final void add(TextButton b)
    {
        if (_buttons.len > 0)
            _buttons[$-1].hotkey = _buttons[$-1].hotkey.init;
        _buttons ~= b;
        b.hotkey = keyMenuUpDir;
        addChild(b);
    }

    // Override to restrict possible paths (except for that currentDir must
    // be a child of baseDir, that is enforced by Breadcrumb elsewhere).
    Filename makeAllowed(Filename candidate) const
    in { assert (candidate.isChildOf(baseDir)); }
    out (ret) {
        assert (ret && baseDir && ret.isChildOf(baseDir) && ret.file == "");
    }
    body { return candidate.guaranteedDirOnly; }

    // Override to get custom buttons.
    // Returns array index into currentDir.dirRootless of the first code unit
    // that hasn't been written onto a button. The idea is that
    // moveLabelAndHotkeyButton() use this to print the remainder on the label.
    int makeButtons()
    {
        assert (baseDir, "set basedir before creating buttons");
        int usedChars = 0;
        int iter = baseDir.dirRootless.len;
        for ( ; iter < currentDir.dirRootless.len; ++iter) {
            string cap = currentDir.dirRootless[usedChars .. iter];
            if (cap.len > 0 && cap[$-1] == '/') {
                add(new TextButton(new Geom(butX, 0, butXl, ylg), cap));
                usedChars = iter;
            }
        }
        return usedChars;
    }

private:
    void clearButtons()
    {
        reqDraw();
        _buttons.each!(b => rmChild(b));
        _buttons = null;
    }
}
