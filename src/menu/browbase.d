module menu.browbase;

/*  class BrowserBase
 *
 *      Guarantee for all inherited classes: onFileHighlight will be called
 *      for every file on which possibly on_file_select could be called later.
 *      Whenever on_file_select is called, onFileHighlight has been called
 *      on the same filename before, and no other onFileHighlight calls have
 *      been made in the meantime. (Impl. by private BrowserBase._fileRecent.)
 */

import std.conv;
static import std.file;

import basics.user; // hotkeys
import file.filename;
import file.language;
import file.log;
import gui;
import gui.picker;
import hardware.mouse;
import hardware.keyboard; // up/down change of highlighted file
import hardware.sound;
import level.level;
import menu.preview;

class BrowserBase : Window {
private:
    bool _gotoMainMenu;
    MutFilename _fileRecent; // highlight, not select. May be in different dir.
    MutFilename _upDownTo; // last-highlit dir or file with up/down keys
    Picker _picker;

    TextButton buttonPlay;
    TextButton buttonExit;
    Preview    preview;

public:
    enum  float pickerXl = 320;
    final float infoX()  const { return pickerXl + 40;       }
    final float infoXl() const { return xlg - pickerXl - 60; }

    // after calling this(), it's a good idea to call
    // highlight(file) with whatever is deemed the correct current file
    this(
        in string title,
        Filename  baseDir
    ) {
        super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg), title);
        auto cfg  = PickerConfig!LevelTiler();
        cfg.all   = new Geom(20, 40, xlg-40, ylg-60);
        cfg.bread = new Geom(0, 0, cfg.all.xl, 30);
        cfg.files = new Geom(0, 40, pickerXl, cfg.all.yl - 40);
        cfg.ls    = new OrderFileLs;
        _picker   = new Picker(cfg);
        _picker.basedir = baseDir;
        buttonExit = new TextButton(new Geom(infoX + infoXl/2, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.commonBack.transl);
        buttonPlay = new TextButton(new Geom(infoX, 80,
            infoXl/3, 40, From.BOTTOM_LEFT), Lang.browserPlay.transl);
        preview    = new Preview(new Geom(20, 80, infoXl, 160, From.TOP_RIG));
        buttonPlay.hotkey = basics.user.keyMenuOkay;
        buttonExit.hotkey = basics.user.keyMenuExit;
        buttonExit.onExecute = () { _gotoMainMenu = true; };
        addChildren(preview, _picker, buttonPlay, buttonExit);
        updateWindowSubtitle();
    }

    ~this() { if (preview) destroy(preview); preview = null; }

    void setButtonPlayText(in string s) { buttonPlay.text = s; }

    @property bool gotoMainMenu() const { return _gotoMainMenu; }
    @property auto fileRecent()   inout { return _fileRecent;   }

    void previewLevel(Level l) { preview.level = l;    }
    void clearPreview()        { preview.level = null; }

    final void highlight(Filename fn)
    {
        if (fn && _picker.navigateToAndHighlightFile(
            fn, CenterOnHighlitFile.onlyIfOffscreen)
        ) {
            buttonPlay.show();
            _fileRecent = fn;
            onFileHighlight(fn);
        }
        else {
            buttonPlay.hide();
            // keep _fileRecent as it is, we might highlight that again later
            onFileHighlight(null);
        }
        updateWindowSubtitle();
    }

protected:
    // override theser
    void onFileHighlight(Filename) {}
    void onFileSelect   (Filename) {}

    final void deleteFileRecentHighlightNeighbor()
    {
        /+
        assert (fileRecent);
        try std.file.remove(fileRecent.rootful);
        catch (Exception e)
            logf(e.msg);
        auto number = levList.currentNumber;
        levList.load_dir(levList.currentDir);
        levList.highlightNumber(-1);
        levList.highlightNumber(number);
        _fileRecent = null;
        highlight(levList.currentFile);
        +/
        playLoud(Sound.SCISSORS);
    }

    override void calcSelf()
    {
        if (_picker.executeFile) {
            MutFilename clicked = _picker.executeFileFilename;
            assert (clicked !is null);
            if (clicked != _fileRecent)
                highlight(clicked);
            else
                onFileSelect(_fileRecent);
        }
        else if (buttonPlay.execute) {
            assert (_fileRecent !is null);
            onFileSelect(_fileRecent);
        }
        else if (_picker.executeDir) {
            highlightIfInCurrentDir(_fileRecent);
            _upDownTo = null;
        }
        else if (keyMenuOkay.keyTapped && _upDownTo) {
            _picker.currentDir = _upDownTo;
            highlightIfInCurrentDir(_fileRecent);
            _upDownTo = null;
        }
        else if (hardware.mouse.mouseClickRight)
            _gotoMainMenu = true;
        else {
            immutable moveBy = keyMenuUpBy1  .keyTappedAllowingRepeats * -1
                             + keyMenuUpBy5  .keyTappedAllowingRepeats * -5
                             + keyMenuDownBy1.keyTappedAllowingRepeats * 1
                             + keyMenuDownBy5.keyTappedAllowingRepeats * 5;
            if (moveBy != 0) {
                _upDownTo = _picker.moveHighlightBy(
                    _upDownTo ? _upDownTo : _fileRecent,
                    moveBy, CenterOnHighlitFile.onlyIfOffscreen);
                highlightIfInCurrentDir(_upDownTo);
            }
        }
    }

private:
    void updateWindowSubtitle()
    {
        assert (_picker.basedir   .rootless.length
            <=  _picker.currentDir.rootless.length);
        windowSubtitle = _picker.currentDir.rootless[
                         _picker.basedir   .rootless.length .. $];
    }

    @property void highlightIfInCurrentDir(Filename fn)
    {
        highlight(fn && fn.dirRootless == _picker.currentDir.dirRootless
            ? fn : null);
    }
}
