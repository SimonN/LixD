module gui.listfile;

/* A file lister.
 * ListLevel and ListBitmap are derived from this.
 */

import std.array;
import std.algorithm;
import std.conv;
import std.string; // formatting assert message
import std.typecons;

import basics.user; // custom keys for navigating the file list
import graphic.color;
import gui;
import file.filename;
import file.language; // '..' for the default pager button
import file.search;
import hardware.keyboard;

class ListFile : Frame {

public:

    alias FileFinder = Filename[] function(in Filename);
    alias SearchCrit = bool function(in Filename);
    alias FileSorter = void delegate(Filename[]);

/*  static SearchCrit default_fileFinder;
 *  static SearchCrit default_searchCrit;
 *         FileSorter default_fileSorter;
 *
 *  void load_dir(in Filename, const int which_page = 0);
 *
 *      This is the main function, should be called by the browsers often.
 *
 *  void highlight            (in Filename);
 *  void highlight_file_number(int);
 *  void highlight_move       (int);
 */
    @property void       fileFinder(FileFinder ff) { _fileFinder = ff; }
    @property void       searchCrit(SearchCrit sc) { _searchCrit = sc; }
    @property void       fileSorter(FileSorter fs) { _fileSorter = fs; }
    @property FileFinder fileFinder() const { return _fileFinder; }
    @property SearchCrit searchCrit() const { return _searchCrit; }
    @property FileSorter fileSorter() const { return _fileSorter; }

    @property bool   clicked()             { return _clicked;             }
    @property int    filesTotal()          { return files.length.to!int;  }
    @property int    page()                { return _page;                }

    @property inout(Button) buttonLastClicked() inout {
        return _buttonLastClicked; }

    deprecated("Do we still need this in the browser?")
    const(Filename) get_file(int i) { return files[i]; }

    @property void            currentDir(in Filename fn) { load_dir(fn);  }
    @property inout(Filename) currentDir()  inout { return _currentDir;  }
    @property inout(Filename) currentFile() inout { return _currentFile; }

    final @property bottomButton() const   { return _bottomButton;      }
    final @property bottomButton(in int i) { return _bottomButton = i;  }

    @property bool useHotkeys()       { return _useHotkeys;     }
    @property bool useHotkeys(bool b) { return _useHotkeys = b; }

protected:

    @property bool clicked(bool b) { return _clicked = b; }

//  final void buttons_clear();

    // never called by ListFile, it's an offer for derived classes
    final TextButton standardTextButton(in float y, in string str)
    {
        TextButton b = new TextButton(new Geom(0, y, xlg, 20, Geom.From.TOP));
        b.text = str;
        return b;
    }

    abstract Button newFileButton(int from_top, int total, in Filename);

    // override this if wanted
    Button newFlipButton()
    {
        return new TextButton(new Geom(0,
            bottomButton() * 20, xlg, 20), // both 20 == height of button
            Lang.commonDirFlipPage.transl);
    }

    enum OnDirLoadAction { CONTINUE, RELOAD, ABORT }

    // Alter the listed directory contents if necessary, by overriding
    OnDirLoadAction on_dir_load() { return OnDirLoadAction.CONTINUE; }
    void onFileHighlight() { }
    void put_to_file_list(Filename s) { files ~= s; }

    // retrieve the raw list of files. Useful when overriding on_dir_load()
    // to sort the files before buttons are drawn.
    @property inout(Filename[]) file_list() inout { return files; }

/*  override void calcSelf();
 *  override void drawSelf();
 */
private:

    int  _page;
    int  _bottomButton;
    int  _fileNumberAtTop;
    bool _bottomButtonFlipsPage;

    bool _useHotkeys;
    bool _clicked;

    Filename[] files;
    Button[]   buttons;
    Button     _buttonLastClicked;

    Filename   _currentDir;
    Filename   _currentFile; // need not be in currentDir

    FileFinder _fileFinder;
    SearchCrit _searchCrit;
    FileSorter _fileSorter;



public:

this(Geom g)
{
    super(g);
    _fileFinder   = &default_fileFinder;
    _searchCrit   = &default_searchCrit;
    _fileSorter   = &default_fileSorter;
    _bottomButton = g.yl.to!int / 20 - 1;
    _useHotkeys   = true;
    undrawColor   = color.guiM;
}



public static Filename[]
default_fileFinder(in Filename where)
{
    return file.search.findRegularFilesNoRecursion(where);
}



public static bool
default_searchCrit(in Filename fn)
{
    // use everything
    return true;
};



public void
default_fileSorter(Filename[] arr)
{
    // sort by pure filename
    arr.sort();
};



public void
load_dir(in Filename to_load, in int which_page = 0)
{
    assert (to_load, "dirname to load in file list is null");
    if (! _currentDir || _currentDir.dirRootless != to_load.dirRootless) {
        _currentDir = new Filename(to_load.dirRootless);
        _page = which_page;
    }
    load_currentDir();
}



protected final void
buttons_clear()
{
    foreach (b; buttons) {
        rmChild(b);
    }
    buttons = null;
    reqDraw();
}



public void
highlight(in Filename fn)
{
    highlight_file_number(files.countUntil(fn).to!int);
}



public void
highlight_file_number(in int pos)
{
    assert (pos >= -1);
    assert (pos < files.length.to!int,
        format("%s.highlight_file_number(%d): argument must be < %d",
        this, pos, files.length.to!int));

    if (pos == -1) {
        // file to be highlighted is not in the directory
        _currentFile = currentDir;
        _buttonLastClicked = null;
        return;
    }
    // Main progression of this function: the file was found.
    // If not on the current page, swap the page.
    if (_bottomButtonFlipsPage) {
        if (pos <  _fileNumberAtTop
         || pos >= _fileNumberAtTop + bottomButton) {
            _page = (bottomButton > 0) ? pos / bottomButton : 0;
            load_currentDir();
        }
    }
    _currentFile = files[pos];

    Button but = buttons[pos - _fileNumberAtTop];

    if (_buttonLastClicked == but) {
        but.on = ! but.on;
    }
    else if (_buttonLastClicked) {
        _buttonLastClicked.on = false;
        but.on = true;
    }
    else {
        but.on = true;
    }
    _buttonLastClicked = but;
    onFileHighlight();
}



public void highlight_move(in int by)
{
    if (by == 0) return;
    if (! files.length) return;

    // Do we have a valid highlight right now?
    int pos = files.countUntil(_currentFile).to!int;
    immutable int last = (files.length - 1).to!int;

    if (pos != -1) {
        // if first file and by < 0, select last one.
        // if last file  and by > 0, select first one.
        if      (pos == 0    && by < 0) pos = last;
        else if (pos == last && by > 0) pos = 0;
        else {
            // If not first or last file, move by the given number of steps,
            // but stop on the first/last entries. Don't wrap around even
            // with steps left!
            int byLeft = by;
            do {
                if (by > 0) { ++pos; --byLeft; }
                else        { --pos; ++byLeft; }
            } while (byLeft != 0 && pos != 0 && pos != last);
        }
    }
    // If none of the files were highlighted before the method call,
    // start on the bottom or top. Do not move yet.
    else {
        if (by < 0) pos = last;
        else        pos = 0;
    }
    highlight_file_number(pos);
}



private void
load_currentDir()
{
    assert (_currentDir, "can't load null dir");
    reqDraw();
    _bottomButtonFlipsPage = false;
    buttons_clear();
    _buttonLastClicked = null;
    files = null;

    try files = _fileFinder(_currentDir)
        .filter!(a => _searchCrit(a)).array();
    catch (Exception e) {
        // don't do anything, maybe on_dir_load() will do something
        // on nonexistant dir
    }
    _fileSorter(files);

    // Hook/event function: derived classes may alter file via overriding
    // the empty on_dir_load() and calls to add_to_file_list().
    final switch (on_dir_load()) {
        case OnDirLoadAction.CONTINUE: break;
        case OnDirLoadAction.RELOAD: load_currentDir(); return;
        case OnDirLoadAction.ABORT: return;
    }

    // create one button per file
    if (_page * _bottomButton >= files.length) _page = 0;
    _fileNumberAtTop = _page * _bottomButton;
    // The following (while) doeis: If there is more than one page, fill
    // each page fully with file buttons. Therefore, the last page may get
    // filled with entries from the second-to-last page.
    while (_page > 0 && _fileNumberAtTop + _bottomButton > files.length)
        --_fileNumberAtTop;

    int nextFromFile = _fileNumberAtTop;

    void add_file_button(in int i)
    {
        Button b = newFileButton(i, nextFromFile, files[nextFromFile]);
        b.undrawColor = color.guiM;
        buttons ~= b;
        addChild(b);
        ++nextFromFile;
    }

    for (int i = 0; i < bottomButton
     && nextFromFile < files.length; ++i) {
        add_file_button(i);
    }
    // Add page-flipping button, unless we're filling the first page exactly,
    // or if there is no room for buttons anyway otherwise. In that case,
    // add an extra regular button.
    if (_bottomButton < 0) {
        // don't add anything at all
    }
    else if (nextFromFile == files.length - 1 && page == 0
        || _bottomButton == 0
    ) {
        add_file_button(_bottomButton);
    }
    else if (nextFromFile < files.length || page > 0) {
        // looks similar to add_file_button() above
        Button b = newFlipButton();
        b.undrawColor = color.guiM;
        buttons ~= b;
        addChild(b);
        _bottomButtonFlipsPage = true;
    }

    // Maybe highlight a button
    if (_currentFile && _currentDir.dirRootful == _currentFile.dirRootful)
        for (int i = 0; i < buttons.length; ++i)
            if (i != _bottomButton || ! _bottomButtonFlipsPage)
                if (_currentFile == files[_fileNumberAtTop + i]) {
                    _buttonLastClicked = buttons[i];
                    _buttonLastClicked.on = true;
                }
}



protected override void
calcSelf()
{
    _clicked = false;
    foreach (int i, b; buttons) {
        if (b.execute) {
            // page-switching button has been clicked?
            if (i == _bottomButton && _bottomButtonFlipsPage) {
                ++_page;
                if (_page * _bottomButton >= files.length) _page = 0;
                load_currentDir();
                _clicked = false;
                break;
            }
            // otherwise, a normal file button has been clicked
            else {
                highlight_file_number(_fileNumberAtTop + i);
                _clicked = true;
                break;
            }
        }
    }
    // end foreach Button

    if (_useHotkeys && buttons.length) {
        bool anyMovementWithKeys = true;
        if      (keyTappedAllowingRepeats(keyMenuUpBy1))   highlight_move(-1);
        else if (keyTappedAllowingRepeats(keyMenuUpBy5))   highlight_move(-5);
        else if (keyTappedAllowingRepeats(keyMenuDownBy1)) highlight_move(1);
        else if (keyTappedAllowingRepeats(keyMenuDownBy5)) highlight_move(5);
        else anyMovementWithKeys = false;
        if (anyMovementWithKeys) _clicked = true;
    }
}



protected override void
drawSelf()
{
    undrawSelf();
    super.drawSelf();
}

}
// end class
