module menu.browser.highli;

import optional;

import file.option;
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
    Label      _previewLevelTitle;

public:
    // after calling this(), it's a good idea to call
    // highlight(file) with whatever is deemed the correct current file
    this(SomePickerConfig)(
        in string title,
        Filename  baseDir,
        // Hack! I overwrite every field of this argument during the ctor!
        // Why do I ask for cfg at all here? I want to pass the picker to
        // super(), but I can't call super!SomeTiler() because how IFTI works,
        // therefore cfg is here to resolve the types.
        SomePickerConfig cfg
    ) {
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg), title);
        cfg.all   = new Geom(20, 30, xlg-40, ylg-50);
        cfg.bread = new Geom(0, 0, cfg.all.xl, 20);
        cfg.files = new Geom(0, 30, pickerXl, cfg.all.yl - 30);
        cfg.ls    = new OrderFileLs;
        cfg.baseDir = baseDir;
        cfg.onDirSelect = (Filename fn) { onPickerExecuteDir(); };
        cfg.onFileSelect = (Filename fn) { onPickerExecuteFile(fn); };
        _picker   = new Picker(cfg);

        _buttonExit = new TextButton(new Geom(infoX + infoXl/2, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.commonBack.transl);
        _buttonExit.hotkey = file.option.keyMenuExit;
        _preview = new Preview(newPreviewGeom());
        _previewLevelTitle = new Label(new Geom(infoX, infoY, infoXl+17, 20));
        _previewLevelTitle.undrawBeforeDraw = true;
        addChildren(_picker, _buttonExit, _preview, _previewLevelTitle);
        previewNone();
    }

    // If you need to override this, add onDispose() and let dispose() call it.
    final void dispose()
    {
        if (_preview) {
            _preview.dispose();
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

    @property bool gotoMainMenu()  const pure nothrow @safe @nogc
    {
        return _gotoMainMenu;
    }

    void previewNone()
    {
        _preview.shown = false;
        _previewLevelTitle.text = "";
    }

    void previewLevel(Level l)
    in { assert (l, "call previewNone() instead"); }
    do {
        _preview.shown = true;
        _previewLevelTitle.text = l.name;
        _preview.level = l;
    }

    final Filename currentDir() const { return _picker.currentDir; }

protected:
    abstract void onPickerExecuteFile(Filename fn);
    abstract void onPickerExecuteDir();

    final Geom newPreviewGeom() const
    {
        return new Geom(20, 60, infoXl, 160, From.TOP_RIG);
    }

    // This browser doesn't support setting file buttons to on.
    // But it must expose the on-setting (highlighting) functionality
    // to subclass browsers that allow highlighting. OO design flaw?
    final bool navigateToAndHighlightFile(Filename fn)
    {
        immutable ret = _picker.navigateToAndHighlightFile(
                        fn, CenterOnHighlitFile.onlyIfOffscreen);
        return ret;
    }

    final void navigateTo(Filename fn)
    {
        _picker.currentDir = fn;
    }

    void forceReloadOfCurrentDir()
    {
        _picker.forceReloadOfCurrentDir();
    }

    final Optional!Filename deleteFileHighlightNeighbor(Filename fn)
    {
        auto ret = _picker.deleteFileHighlightNeighbor(fn);
        return ret ? some(ret) : Optional!Filename();
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
    }
}
