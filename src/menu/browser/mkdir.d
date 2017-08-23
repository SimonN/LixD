module menu.browser.mkdir;

/* Our caller should give us focus.
 * We remove our own focus once we're done.
 */

import basics.user; // hotkeys
import file.filename;
import file.language;
import file.log;
import gui;
import hardware.mouse;
import hardware.sound;
import std.string;

class MkdirDialog : Window {
private:
    bool _done;
    Filename _parentDir;
    MutFilename _createdDir; // null if we didn't create a dir

    Label _pleaseEnter;
    Texttype _name;
    TextButton _okay;
    TextButton _cancel;

public:
    this(Geom g, in Filename aParentDir)
    in { assert (aParentDir); }
    body {
        super(g, Lang.browserMkdirTitle.transl);
        _parentDir = aParentDir;
        _pleaseEnter = new Label(new Geom(20, 40, this.xlg - 40, 20),
            Lang.browserMkdirPleaseEnter.transl);
        _name = new Texttype(new Geom(20, 60, this.xlg - 40, 20));
        _name.allowedChars = Texttype.AllowedChars.filename;
        _name.on = true;
        _name.onEnter = () { this.tryToCreateDir(); };

        _okay = new TextButton(newButtonGeom(-1), Lang.commonOk.transl);
        _cancel = new TextButton(newButtonGeom(1), Lang.commonCancel.transl);
        _okay.onExecute = () { this.tryToCreateDir(); };
        _cancel.onExecute = () { setDone(); };
        _okay.hotkey = keyMenuOkay;
        _cancel.hotkey = keyMenuExit;
        addChildren(_pleaseEnter, _name, _okay, _cancel);
    }

    @property bool done() const { return _done; }
    @property Filename createdDir() const { return _createdDir; }

protected:
    override void calcSelf()
    {
        super.calcSelf();
        if (mouseClickRight)
            setDone();
    }

private:
    Geom newButtonGeom(in int mult) const
    {
        immutable bXl = (this.xlg - 60) / 2;
        return new Geom(mult * (bXl/2 + 10), 20, bXl, this.ylg - 120,
            From.BOTTOM);
    }

    void tryToCreateDir()
    {
        string fn = _name.text.strip;
        if (fn == "") {
            _name.on = true;
            return;
        }
        try {
            assert (cast (VfsFilename) _parentDir,
                "not sure whether command-line dirs should ever be here");
            _createdDir = new VfsFilename(_parentDir.dirRootless ~ fn ~ "/");
            _createdDir.mkdirRecurse();
        }
        catch (Exception e) {
            log(e.msg);
            _pleaseEnter.text = e.msg;
            _createdDir = null;
            _name.text = "";
            _name.on = true;
        }
        playLoud(Sound.DISKSAVE);
        setDone();
    }

    void setDone()
    {
        rmFocus(this);
        _done = true;
    }
}
