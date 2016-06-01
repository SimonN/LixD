module menu.browser.highli;

import basics.user;
import file.filename;
import file.language;
import gui;
import gui.picker;
import hardware.mouse;
import level.level;
import menu.preview;

class BrowserHighlight : Window {
private:
    Picker     _picker;
    bool       _gotoMainMenu;
    TextButton _buttonExit;
    Preview    _preview;

public:
    // after calling this(), it's a good idea to call
    // highlight(file) with whatever is deemed the correct current file
    this(SomeTiler)(
        in string title,
        Filename  baseDir,
        PickerConfig!SomeTiler cfg // Hack! I overwrite every field of this
                                   // argument during the constructor! Why do
                                   // I ask for cfg at all here? I want to pass
                                   // SomeTiler to BrowserHighlight.this(), but
                                   // can't call super!SomeTiler() explicitly.
                                   // IFTI works, so cfg is to pass the type.
    )   if (is (SomeTiler : Tiler)
    ) {
        super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg), title);
        cfg.all   = new Geom(20, 40, xlg-40, ylg-60);
        cfg.bread = new Geom(0, 0, cfg.all.xl, 30);
        cfg.files = new Geom(0, 40, pickerXl, cfg.all.yl - 40);
        cfg.ls    = new OrderFileLs;
        _picker   = new Picker(cfg);
        _picker.basedir = baseDir;
        _buttonExit = new TextButton(new Geom(infoX + infoXl/2, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.commonBack.transl);
        _buttonExit.hotkey = basics.user.keyMenuExit;
        _preview = new Preview(new Geom(20, 80, infoXl, 160, From.TOP_RIG));
        addChildren(_picker, _buttonExit, _preview);
        updateWindowSubtitle();
    }

    ~this()
    {
        if (_preview) {
            destroy(_preview);
            _preview = null;
        }
    }

    enum  float pickerXl = 320;
    final float infoX()  const { return pickerXl + 40;       }
    final float infoXl() const { return xlg - pickerXl - 60; }
    final float infoY()  const
    {
        assert (_preview);
        return _preview.yg + _preview.ylg + 20;
    }

    @property bool gotoMainMenu() const { return _gotoMainMenu; }

    void previewLevel(Level l) { _preview.level = l;    }
    void clearPreview()        { _preview.level = null; }

    final Filename currentDir() const { return _picker.currentDir; }

protected:
    // override these as soon as possible
    void onPickerExecuteFile(Filename) {}
    void onPickerExecuteDir ()         {}

    // This browser doesn't support setting file buttons to on.
    // But it must expose the on-setting (highlighting) functionality
    // to subclass browsers that allow highlighting. OO design flaw?
    final bool navigateToAndHighlightFile(Filename fn)
    {
        immutable ret = _picker.navigateToAndHighlightFile(
                        fn, CenterOnHighlitFile.onlyIfOffscreen);
        updateWindowSubtitle();
        return ret;
    }

    final void navigateTo(Filename fn)
    {
        _picker.currentDir = fn;
        updateWindowSubtitle();
    }

    final auto deleteFileHighlightNeighbor(Filename fn)
    {
        return _picker.deleteFileHighlightNeighbor(fn);
    }

    final auto moveHighlightBy(Filename old, in int by)
    {
        return _picker.moveHighlightBy(old, by,
                                       CenterOnHighlitFile.onlyIfOffscreen);
    }

    override void calcSelf()
    {
        super.calcSelf();
        if (hardware.mouse.mouseClickRight || _buttonExit.execute)
            _gotoMainMenu = true;
        else if (_picker.executeFile)
            onPickerExecuteFile(_picker.executeFileFilename);
        else if (_picker.executeDir)
            onPickerExecuteDir();
    }

private:
    void updateWindowSubtitle()
    {
        assert (_picker.basedir   .rootless.length
            <=  _picker.currentDir.rootless.length);
        windowSubtitle = _picker.currentDir.rootless[
                         _picker.basedir   .rootless.length .. $];
    }
}