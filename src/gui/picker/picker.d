module gui.picker.picker;

import std.algorithm;
import std.file; // FileException
import std.conv;

import file.log;
import gui;
import gui.picker;

struct PickerConfig(T)
    if (is (T : Tiler)
) {
    Geom all;
    Geom bread;
    Geom files; // Tiler including scrollbar
    Ls ls;
}

class Picker : Element {
private:
    Breadcrumb _bread;
    Ls _ls;
    Frame _frame;
    Tiler _tiler;
    Scrollbar _scrollbar;

public:
    // Create all class objects in cfg, then give them to this constructor.
    this(T)(PickerConfig!T cfg)
    out {
        assert (_ls);
    }
    body {
        super(cfg.all);
        import graphic.color;
        undrawColor = color.transp; // Hack. Picker should not be a drawable
                                    // element, but rather only have children.
        _frame     = new Frame(cfg.files);
        _bread     = new Breadcrumb(cfg.bread);
        _ls        = cfg.ls;
        _tiler     = new T        (cfg.files.newGeomTiler);
        _scrollbar = new Scrollbar(cfg.files.newGeomScrollbar);
        _scrollbar.pageLen    = _tiler.pageLen;
        _scrollbar.coarseness = _tiler.coarseness;
        _scrollbar.wheelSpeed = _tiler.wheelSpeed;
        addChildren(_bread, _frame, _tiler, _scrollbar);
    }

    @property Filename basedir() const { return _bread.basedir; }
    @property Filename basedir(Filename fn)
    {
        _bread.basedir = fn; // this resets currentDir if no longer child
        updateAccordingToBreadCurrentDir();
        return basedir;
    }

    @property Filename currentDir() const { return _bread.currentDir; }
    @property Filename currentDir(Filename fn)
    {
        if (fn && fn.dirRootless != currentDir.dirRootless) {
            _bread.currentDir = fn;
            updateAccordingToBreadCurrentDir();
        }
        return currentDir;
    }

    @property bool executeDir() const
    {
        return _tiler.executeDir || _bread.execute;
    }

    @property bool executeFile()   const { return _tiler.executeFile;   }
    @property int  executeFileID() const { return _tiler.executeFileID; }

    void highlightNothing() { _tiler.highlightNothing(); }
    bool highlightFile(int i, CenterOnHighlitFile chf)
    {
        immutable b = _tiler.highlightFile(i, chf);
        _scrollbar.pos = _tiler.top;
        return b;
    }

    Filename executeFileFilename() const
    {
        assert (executeFile, "call this only when executeFile == true");
        return _ls.files[executeFileID];
    }

    bool navigateToAndHighlightFile(Filename fn, CenterOnHighlitFile chf)
    {
        if (! fn)
            highlightNothing();
        currentDir = fn;
        immutable int id = _ls.files.countUntil(fn).to!int;
        if (id >= 0)
            return highlightFile(id, chf);
        else {
            highlightNothing();
            return false;
        }
    }

    Filename moveHighlightBy(Filename old, in int by, CenterOnHighlitFile chf)
    {
        Filename moveTo = _ls.moveHighlightBy(old, by);
        _tiler.highlightFile(_ls.files.countUntil(moveTo).to!int, chf);
        _tiler.highlightDir (_ls.dirs .countUntil(moveTo).to!int, chf);
        _scrollbar.pos = _tiler.top;
        return moveTo;
    }

    Filename deleteFileHighlightNeighbor(Filename toDelete)
    {
        immutable oldID = _ls.files.countUntil(toDelete).to!int;
        _ls.deleteFile(toDelete);
        updateAccordingToBreadCurrentDir(KeepScrollingPosition.yes);
        immutable newID = _ls.files.length.to!int > oldID ? oldID : oldID - 1;
        if (highlightFile(newID, CenterOnHighlitFile.onlyIfOffscreen))
            return _ls.files[newID];
        else
            return null;
    }

protected:
    override void calcSelf()
    {
        if (_bread.execute)
            updateAccordingToBreadCurrentDir();
        else if (_tiler.executeDir)
            currentDir = _ls.dirs[_tiler.executeDirID];
        else if (_scrollbar.execute)
            _tiler.top = _scrollbar.pos;
    }

private:
    enum KeepScrollingPosition { no, yes }

    void updateAccordingToBreadCurrentDir(
        KeepScrollingPosition ksp = KeepScrollingPosition.no
    ) {
        try
            _ls.currentDir = currentDir;
        catch (FileException e) {
            log(e.msg);
            if (currentDir == basedir)
                throw e;
            currentDir = basedir;
            return;
        }
        _tiler.loadDirsFiles(_ls.dirs, _ls.files);
        _scrollbar.totalLen = _tiler.totalLen;
        if (ksp == KeepScrollingPosition.no)
            _scrollbar.pos = 0;
    }
}

private:

Geom newGeomScrollbar(Geom files) pure
{
    return new Geom(files.x + files.xl - 20, files.y, 20, files.yl);
}

Geom newGeomTiler(Geom files) pure
{
    return new Geom(files.x, files.y, files.xl - 20, files.yl);
}

