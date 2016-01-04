module gui.listdir;

/* In C++-A4-Lix, this was its own class, unrelated to ListFile.
 * It shares so much though, that in D/A5 Lix, it's derived from it.
 * ListFile is slightly beefed up and got hooks to accomodate this.
 */

import std.string; // formatting an assert message
import std.conv;
import std.typecons;

import basics.user; // hotkey for dirUp button
import graphic.color;
import gui;
import file.filename;
import file.language;
import file.log;
import file.search;

// see the comment in override on_dir_load() for why this is a final class
final class ListDir : ListFile {

public:

/*  this(      x, y, xl, yl);
 *  this(from, x, y, xl, yl);
 */
    @property inout(Filename) baseDir() inout {
        return _baseDir; }
    @property override inout(Filename) currentDir() inout {
        return super.currentDir; }
/*  @property void currentDir(in Filename);
 *  @property void baseDir   (in Filename);
 *  void setCurrentDirToParentDir();
 */
    @property auto listFileToControl(ListFile l) { return _listFile = l; }
    @property auto listFileToControl() const     { return _listFile;     }

private:

    @disable @property inout(Filename) currentFile() inout;

    Filename   _baseDir;
    TextButton dirUp;

    ListFile _listFile; // this is reloaded when our dir changes



public this(Geom g)
{
    super(g);

    fileFinder = &(file.search.findDirsNoRecursion);
    searchCrit = function bool(in Filename fn) {
        return fn.file != "." && fn.file != "..";
    };
    fileSorter = delegate void(Filename[] arr) {
        sortFilenamesByOrderTxtThenAlpha(arr, currentDir, true);
    };
    super.useHotkeys = false;
    // but the (this) class shall still check for the dir-up-change key
}



public @property void
baseDir(in Filename fn)
{
    assert (fn, "base directory can't be set to null");
    _baseDir = new Filename(fn.dirRootless);
}



public void
setCurrentDirToParentDir()
{
    string str = currentDir.dirRootless;
    if (str.length && str[$-1] == '/')
        str = str[0 .. $-1];
    while (str.length && str[$-1] != '/')
        str = str[0 .. $-1];

   currentDir = new Filename(str);
   if (_listFile) _listFile.currentDir = currentDir;
}



public override @property void
currentDir(in Filename fn)
{
    assert (_baseDir, "base directory not set, can't load a dir without it");
    assert (fn, "dirname to load in dir list is null");

    bool good_dir     = dirExists(fn) && fn.isChildOf(_baseDir);
    const Filename f  = good_dir ? fn : _baseDir;
    super.currentDir = f;
    if (_listFile)
        _listFile.currentDir = f;
}



// This gets run after the file search in (super), but before it adds
// its own buttons. This is exactly where we should add our own button,
// and tweak the number of buttons (super) shall add.
protected override super.OnDirLoadAction
on_dir_load()
{
    assert (_baseDir, "base directory not set, can't load a dir without it");
    // this must happen even on a non-existing dir
    if (dirUp) {
        rmChild(dirUp);
        dirUp = null;
    }
    // this assert is the reason for finality of this class
    assert (children.length == 0,
        format("there should be 0 children, not %d, before any adding buttons",
        children.length));

    // sanity checks
    immutable bool bad_exists = ! file.search.dirExists(currentDir);
    immutable bool bad_child  = ! currentDir.isChildOf(_baseDir);

    if (bad_exists || bad_child) {
        if (! file.search.dirExists(baseDir)) {
            // this is extremely bad, abort immediately
            logf("Base dir `%s' is missing. Broken installation?",
                baseDir.rootful);
            return OnDirLoadAction.ABORT;
        }
        else if (bad_exists)
            logf("`%s' doesn't exist. Falling back to `%s'.",
            currentDir.rootful, baseDir.rootful);
        else if (bad_child)
            logf("`%s' is not a subdir of `%s'. Falling back to that.",
            currentDir.rootful, baseDir.rootful);

        currentDir = baseDir;       // again goes through load_currentDir()
        return OnDirLoadAction.ABORT; // abort the original pass through it
    }

    if (super.currentDir == _baseDir) {
        bottomButton = ylg.to!int / 20 - 1;
    }
    else {
        bottomButton = ylg.to!int / 20 - 2;
        assert (dirUp is null);
        dirUp = new TextButton(new Geom(0, 0, xlg, 20, From.TOP));
        dirUp.text = Lang.commonDirParent.transl;
        dirUp.undrawColor = color.guiM;
        dirUp.hotkey = basics.user.keyMenuUpDir;
        addChild(dirUp);
        // We don't put the children-deleting function onto dirUp.on_click,
        // because I fear bugs from removing array elements during foreach.
        // Instead, I check for this in calcSelf.
    }
    return OnDirLoadAction.CONTINUE;
}



protected override Button
newFileButton(int from_top, int total, in Filename fn)
{
    // the first slot may have been taken by the dirUp button.
    immutable plusY = dirUp ? 20 : 0;
    return standardTextButton(20 * from_top + plusY, fn.dirInnermost);
}



protected override void
onFileHighlight()
{
    // the file buttons represent dirs that can be switched into
    string str = super.currentFile.rootless;
    if (! str.length) return;
    if (str[$-1] != '/') str ~= '/';

    currentDir = new Filename(str);
    if (_listFile)
        _listFile.currentDir = currentDir;
}



protected override void
calcSelf()
{
    super.calcSelf();
    if (dirUp && dirUp.execute) {
        setCurrentDirToParentDir();
        this.clicked = true;
    }
}

}
// end class ListDir
