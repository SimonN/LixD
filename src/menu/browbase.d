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
import hardware.mouse;
import hardware.sound;
import level.level;
import menu.preview;

class BrowserBase : Window {

    ~this() { if (preview) destroy(preview); preview = null; }

    void setButtonPlayText(in string s) { buttonPlay.text = s; }

    @property bool gotoMainMenu() const { return _gotoMainMenu; }
    @property auto fileRecent()   inout { return _fileRecent;   }

    void previewLevel(Level l) { preview.level = l;    }
    void clearPreview()        { preview.level = null; }

    enum  float infoXl = 140;
    final float infoY() const
    {
        assert (preview);
        return preview.yg + preview.ylg + 20;
    }

    // after calling this(), it's a good idea to call
    // highlight(file) with whatever is deemed the correct current file
    this(
        in string   title,
        in Filename baseDir,
        ListLevel.LevelCheckmarks   lcm,
        ListLevel.ReplayToLevelName rtl
    ) {
        super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg), title);
        immutable int lxlg = to!int(Geom.screenXlg - 100 - 140 - 4*20);
        dirList = new ListDir  (new Geom(20,  40, 100,  420));
        levList = new ListLevel(new Geom(140, 40, lxlg, 420),
                                ListLevel.WriteFilenames.no, lcm, rtl);
        alias TextBut = TextButton;
        buttonPlay = new TextBut(new Geom(20,  40, infoXl,  40, From.TOP_RIG));
        preview    = new Preview(new Geom(20, 100, infoXl, 100, From.TOP_RIG));
        buttonExit = new TextBut(new Geom(20,  20, infoXl,  40, From.BOT_RIG));
        dirList.listFileToControl = levList;
        dirList.baseDir    = baseDir;
        dirList.currentDir = baseDir;
        buttonPlay.text = Lang.browserPlay.transl;
        buttonExit.text = Lang.commonBack.transl;
        buttonPlay.hotkey = basics.user.keyMenuOkay;
        buttonExit.hotkey = basics.user.keyMenuExit;
        buttonExit.onExecute = () { _gotoMainMenu = true; };
        addChildren(preview, dirList, levList, buttonPlay, buttonExit);
        updateWindowSubtitle();
    }

    final void highlight(Filename fn)
    {
        if (fn !is null && fn.file != null)
            dirList.currentDir = fn;
        updateWindowSubtitle();
        levList.highlight(fn);
        dispatchHighlightToBrowserSubclass(fn);
    }

protected:

    // override these
    void onFileHighlight(Filename) {}
    void onFileSelect   (Filename) {}

    final void deleteFileRecentHighlightNeighbor()
    {
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
        playLoud(Sound.SCISSORS);
    }

    final void movePreviewDown(float plusY)
    {
        assert (preview);
        preview.move(preview.geom.x, preview.geom.y + plusY);
    }

    override void calcSelf()
    {
        if (dirList.clicked) {
            windowSubtitle = dirList.currentDir.rootless;
            if (_fileRecent &&
                _fileRecent.dirRootless == dirList.currentDir.dirRootless)
                highlight(_fileRecent);
            else
                highlight(null);
        }
        else if (levList.clicked) {
            auto fn = levList.currentFile;
            auto button = levList.buttonLastClicked;
            if (fn !is null && button !is null) {
                if (button.on)
                    // button executed for the first time
                    dispatchHighlightToBrowserSubclass(fn);
                else {
                    // button execute for the second time
                    assert (fn == _fileRecent);
                    onFileSelect(fn);
                }
            }
        }
        else if (buttonPlay.execute) {
            if (_fileRecent !is null
             && _fileRecent.isChildOf(dirList.currentDir)
             && _fileRecent ==        levList.currentFile)
                onFileSelect(_fileRecent);
        }
        else if (hardware.mouse.mouseClickRight)
            _gotoMainMenu = true;
    }

private:

    bool _gotoMainMenu;

    Filename   _fileRecent; // only used for highlighting, not selecting

    ListDir    dirList;
    ListLevel  levList;

    Frame      _coverFrame; // looks like the levList's outer frame
    Label[]    _coverDesc;  // the cover text in file-empty dirs

    TextButton buttonPlay;
    TextButton buttonExit;
    Preview    preview;

    void dispatchHighlightToBrowserSubclass(Filename fn)
    {
        if (levList.currentFile == fn && fn !is null && fn.file != null) {
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
        assert (dirList.baseDir   .rootless.length
            <=  dirList.currentDir.rootless.length);
        windowSubtitle = dirList.currentDir.rootless[
                         dirList.baseDir   .rootless.length .. $];
    }
}
// end class
