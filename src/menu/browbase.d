module menu.browbase;

/*  class BrowserBase
 *
 *      Guarantee for all inherited classes: onFileHighlight will be called
 *      for every file on which possibly on_file_select could be called later.
 *      Whenever on_file_select is called, onFileHighlight has been called
 *      on the same filename before, and no other onFileHighlight calls have
 *      been made in the meantime. (Impl. by private BrowserBase.fileRecent.)
 */

import std.conv;

import file.filename;
import file.language;
import gui;
import level.level;
import menu.preview;

class BrowserBase : Window {

    enum UseCheckmarks  { yes, no };
    enum UseReplayStyle { yes, no };

/*  this(string windowTitle,
 *      in Filename baseDir,
 *      in Filename currentFile,
 *      bool useCheckmarks = false,
 *      bool replayStyle   = false); -- see below for implementation
 */

    ~this() { if (preview) destroy(preview); preview = null; }

    void setButtonPlayText(in string s) { buttonPlay.text = s; }

    @property bool gotoMainMenu() const { return _gotoMainMenu; }

    @property auto baseDir()     const { return dirList.baseDir;     }
    @property auto currentFile() const { return levList.currentFile; }

/*  void setCurrentDirToParentDir()
 *
 *  void load_dir(in Filename, bool call_onFileHighlight = true);
 *  void highlight_nothing();
 *
 *  void set_preview_y_and_yl(in int y, in int yl);
 */
    void previewLevel(Level l) { preview.level = l;    }
    void clearPreview()        { preview.level = null; }

    @property int  infoY() const   { return _infoY; }
    @property void infoY(in int i) { _infoY = i;    }

    // override these
    void onFileHighlight(Filename) {}
    void onFileSelect   (Filename) {}

private:

    bool _gotoMainMenu;

    int        _infoY;
    Filename   fileRecent; // only used for highlighting, not selecting

    ListDir    dirList;
    ListLevel  levList;

    Frame      _coverFrame; // looks like the levList's outer frame
    Label[]    _coverDesc;  // the cover text in file-empty dirs

    TextButton buttonPlay;
    TextButton buttonExit;
    Preview    preview;

//  void       highlight(Filename);



public:

this(
    in string      windowTitle,
    in Filename    baseDir,
       Filename    currentFile,
    UseCheckmarks  useCheckmarks = UseCheckmarks.no,
    UseReplayStyle replayStyle   = UseReplayStyle.no
) {
    super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg), windowTitle);

    immutable int lxlg = to!int(Geom.screenXlg - 100 - 140 - 4*20);

    dirList = new ListDir  (new Geom(20,  40, 100,  420));
    levList = new ListLevel(new Geom(140, 40, lxlg, 420));

    buttonPlay = new TextButton(new Geom(20,  40, 140,  40, From.TOP_RIG));
    preview    = new Preview   (new Geom(20, 100, 140, 100, From.TOP_RIG));
    buttonExit = new TextButton(new Geom(20,  20, 140,  40, From.BOT_RIG));

    // preview_yl = 100 or 93 doesn't fit exactly for the 640x480 resolution,
    // the correct value there would have been 92. But it'll make the image
    // longer by 1, without costing quality, and it fits the strange constants
    // in C++-A4 Lix's level.cpp.

    dirList.baseDir = baseDir;
    dirList.listFileToControl = levList;
    dirList.currentDir = currentFile;

    levList.highlight(currentFile);
    if (levList.currentFile == currentFile
        && currentFile !is null
        && currentFile.file != null
    )
        this.highlight(currentFile);
    else
        this.highlight(null);

    buttonPlay.text = Lang.browserPlay.transl;
    buttonExit.text = Lang.commonBack.transl;
    buttonExit.onExecute = () { _gotoMainMenu = true; };

    addChildren(preview, dirList, levList, buttonPlay, buttonExit);

    subtitle = dirList.currentDir.rootless;
}



public void set_preview_y_and_yl(in int y, in int yl)
{
    preview.geom = new Geom(preview.xg, y, preview.xlg, preview.ylg,
        preview.geom.from);
    reqDraw();
}



private void
highlight(Filename fn)
{
    if (fn is null) {
        buttonPlay.hide();
        // keep fileRecent as it is, we might highlight that again later
        onFileHighlight(null);
    }
    else {
        buttonPlay.show();
        fileRecent = fn;
        onFileHighlight(fn);
    }
}



protected override void
calcSelf()
{
    if (dirList.clicked) {
        subtitle = dirList.currentDir.rootless;
        if (fileRecent &&
            fileRecent.dirRootless == dirList.currentDir.dirRootless)
            highlight(fileRecent);
        else
            highlight(null);
    }
    else if (levList.clicked) {
        auto fn = levList.currentFile;
        auto button = levList.buttonLastClicked;
        if (fn !is null && button !is null) {
            if (button.on)
                // button executed for the first time
                highlight(fn);
            else
                // button execute for the second time
                onFileSelect(fn);
        }
    }
    else if (buttonPlay.execute) {
        if (fileRecent !is null
         && fileRecent.isChildOf(dirList.currentDir)
         && fileRecent ==        levList.currentFile)
            onFileSelect(fileRecent);
    }
}

}
// end class
