module gui.picker.bread;

/* Breadcrumb navigation
 * A series of buttons with one nested subdirectory per button.
 *
 * This doesn't check whether directories exist! Ls would throw when
 * we search a nonexisting dir, but Breadcrumb won't.
 *
 * Squashing Convention:
 * If we squash buttons at all (to preserve horizontal space),
 * we squash the outermost non-top-level dirs. We keep one top-level dir
 * and maybe several innermost dirs.
 */


import std.algorithm;

import basics.help; // len
import opt = file.option.allopts;
import gui;
import file.filename;

class Breadcrumb : Element {
private:
    Filename _baseDir;
    MutFilename _currentDir;
    TextButton[] _buttons;
    Label _innermost;
    bool _execute;
    int _dirButtonsSquashed; // To preserve space in deeply-nested dirs

public:
    // Picker's search button shall have same shape
    enum butXl = 100f;
    enum xgBetweenRightmostButtonAndInnermostLabel = 4f;

    this(Geom g, Filename aBaseDir)
    in { assert (aBaseDir !is null); }
    do {
        super(g);
        _innermost = new Label(new Geom(0, 0,
            butXl - xgBetweenRightmostButtonAndInnermostLabel, 20, From.LEFT));
        _baseDir = aBaseDir;
        addChild(_innermost);
    }

    bool execute() const { return _execute; }

    Filename baseDir() const { return _baseDir; }

    Filename currentDir() const
    out (ret) { assert (ret is null || ret.file == ""); }
    do { return _currentDir; }

    Filename currentDir(Filename fn)
    {
        assert (baseDir, "set basedir before setting current dir");
        MutFilename newCur = (fn && fn.isChildOf(baseDir))
            ? makeAllowed(fn.guaranteedDirOnly) : baseDir;
        if (newCur != _currentDir) {
            _currentDir = newCur;
            clearButtons();
            immutable int usedChars = makeButtons();
            moveInnermostLabel();
            _innermost.text = currentDir.dirRootless[usedChars .. $];
        }
        return _currentDir;
    }

protected:
    override void calcSelf()
    {
        _execute = false;
        foreach (const size_t buttonID, Button b; _buttons) {
            if (! b.execute)
                continue;
            currentDir = filenameForButtonID(buttonID);
            _execute = true;
            break;
        }
    }

    override void drawSelf()
    {
        undrawSelf();
        super.drawSelf();
    }

    final float buttonsTotalXlg() const
    {
        return _buttons.map!(b => b.xlg).sum;
    }

    final void addNewRightmostDirButton(in string caption)
    {
        if (_buttons.len > 0)
            _buttons[$-1].hotkey = _buttons[$-1].hotkey.init;
        _buttons ~= new TextButton(new Geom(
            buttonsTotalXlg, 0, butXl, ylg), caption);
        _buttons[$-1].hotkey = opt.keyMenuUpDir.value;
        addChild(_buttons[$-1]);
    }

    // Override to restrict possible paths (except for that currentDir must
    // be a child of baseDir, that is enforced by Breadcrumb elsewhere).
    Filename makeAllowed(Filename candidate) const
    in { assert (candidate.isChildOf(baseDir)); }
    out (ret) {
        assert (ret && baseDir && ret.isChildOf(baseDir) && ret.file == "");
    }
    do { return candidate.guaranteedDirOnly; }

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
                addNewRightmostDirButton(cap);
                usedChars = iter;
            }
        }
        sqashMiddleButtonsIfArrayTooLong();
        return usedChars;
    }

    final void sqashMiddleButtonsIfArrayTooLong()
    {
        /*
         * Always keep top-level button and innermost dir button. Thus, keep 2.
         * It's fine if everything else gets squashed. Normally, squash
         * the outermost non-top-level dirs, this is the squashing convention
         * from the comment at the top of this file.
         */
        while (_buttons.len > 2
            && buttonsTotalXlg + xgBetweenRightmostButtonAndInnermostLabel
                               + _innermost.xlg > this.xlg
        ) {
            rmChild(_buttons[1]);
            foreach (int i; 1 .. _buttons.len - 1) {
                _buttons[i] = _buttons[i+1];
                _buttons[i].move(i * butXl, 0);
            }
            _buttons.length -= 1;
            _buttons[1].text = ".../" ~ _buttons[1].text;
            _dirButtonsSquashed += 1;
            moveInnermostLabel();
        }
    }

private:
    void clearButtons()
    {
        reqDraw();
        _buttons.each!(b => rmChild(b));
        _buttons = null;
        _dirButtonsSquashed = 0;
    }

    void moveInnermostLabel()
    {
        _innermost.move(
            buttonsTotalXlg + xgBetweenRightmostButtonAndInnermostLabel, 0);
    }

    /*
     * For the button with ID (size_t id), return the (newly-allocated)
     * directory name to where that button would switch.
     */
    Filename filenameForButtonID(in size_t id)
    {
        // See squashing convention in the comment at the top of this file.
        if (id == 0) {
            return baseDir;
        }
        else {
            assert (currentDir.dirRootless.startsWith(baseDir.dirRootless));
            string s = currentDir.dirRootless[baseDir.dirRootless.length .. $];
            immutable numSlashesToSkip = id + _dirButtonsSquashed;
            foreach (_; 0 .. numSlashesToSkip)
                s.findSkip("/");
            return currentDir = new VfsFilename(
                currentDir.dirRootless[0 .. $ - s.length]);
        }
    }
}
