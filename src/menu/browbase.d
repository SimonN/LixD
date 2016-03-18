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
import hardware.sound;
import level.level;
import menu.preview;

class BrowserBase : Window {
private:
    bool _gotoMainMenu;
    MutFilename _fileRecent; // only used for highlighting, not selecting

    Picker _picker;

    TextButton buttonPlay;
    TextButton buttonExit;
    Preview    preview;

public:
    enum  float infoXl = 140;
    final float infoY() const
    {
        assert (preview);
        return preview.yg + preview.ylg + 20;
    }

    // after calling this(), it's a good idea to call
    // highlight(file) with whatever is deemed the correct current file
    this(
        in string title,
        Filename  baseDir
    ) {
        super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg), title);
        _picker = Picker.newPicker!LevelTiler(
            new Geom(20,  40, 280, 420),
            new OrderFileLs);
        _picker.basedir = baseDir;
        alias TextBut = TextButton;
        buttonPlay = new TextBut(new Geom(20,  40, infoXl,  40, From.TOP_RIG));
        preview    = new Preview(new Geom(20, 100, infoXl, 100, From.TOP_RIG));
        buttonExit = new TextBut(new Geom(20,  20, infoXl,  40, From.BOT_RIG));
        buttonPlay.text = Lang.browserPlay.transl;
        buttonExit.text = Lang.commonBack.transl;
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
        _picker.highlightFile(fn);
        updateWindowSubtitle();
        dispatchHighlightToBrowserSubclass(fn);
    }

protected:
    // override these
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

    final void movePreviewDown(float plusY)
    {
        assert (preview);
        preview.move(preview.geom.x, preview.geom.y + plusY);
    }

    override void calcSelf()
    {
        if (_picker.executeDir)
            updateWindowSubtitle();
        if (_picker.executeFile) {
            assert (_picker.executeFileFilename !is null);
            if (_fileRecent != MutFilename(_picker.executeFileFilename))
                dispatchHighlightToBrowserSubclass(_fileRecent);
            else
                onFileSelect(_fileRecent);
        }
        else if (buttonPlay.execute) {
            assert (_fileRecent !is null);
            assert (_fileRecent.dirRootless == _picker.currentDir.dirRootless);
            onFileSelect(_fileRecent);
        }
        else if (hardware.mouse.mouseClickRight)
            _gotoMainMenu = true;
    }

private:
    void dispatchHighlightToBrowserSubclass(Filename fn)
    {
        if (fn !is null && fn.file != null) {
            buttonPlay.show();
            _fileRecent = fn;
            onFileHighlight(fn);
        }
        else {
            buttonPlay.hide();
            // keep _fileRecent as it is, we might highlight that again later
            onFileHighlight(null);
        }
    }

    void updateWindowSubtitle()
    {
        assert (_picker.basedir   .rootless.length
            <=  _picker.currentDir.rootless.length);
        windowSubtitle = _picker.currentDir.rootless[
                         _picker.basedir   .rootless.length .. $];
    }
}
