module gui.picker.picker;

import std.algorithm;
import std.file; // FileException
import std.conv;

import file.log;
import gui;
import gui.picker;

struct PickerConfig(T)
    if (is (T : FileTiler)
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
    ScrolledFiles _list;

    // We access _list.tiler outside of _list freely. That's okay, ScrolledList
    // allows subclasses to do that, and we fully control the subclass.
    static final class ScrolledFiles : ScrolledList {
        FileTiler _tiler;
        override @property inout(FileTiler) tiler() inout { return _tiler; }
        this(Geom g, FileTiler delegate(Geom) newTiler) {
            super(g);
            addChild(_tiler = newTiler(newGeomForTiler()));
        }
    }

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
        _bread = new Breadcrumb(cfg.bread);
        _ls = cfg.ls;
        _list = new ScrolledFiles(cfg.files, delegate FileTiler(Geom gg)
                                                  { return new T(gg); });
        addChildren(_bread, _list);
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

    @property bool executeDir() const { return _list.tiler.executeDir; }
    @property bool executeFile() const { return _list.tiler.executeFile; }
    @property int executeDirID() const { return _list.tiler.executeDirID; }
    @property int executeFileID() const { return _list.tiler.executeFileID; }

    void highlightNothing() { _list.tiler.highlightNothing(); }
    bool highlightFile(int i, CenterOnHighlitFile chf)
    {
        return _list.tiler.highlightFile(i, chf);
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
        _list.tiler.highlightFile(_ls.files.countUntil(moveTo).to!int, chf);
        _list.tiler.highlightDir (_ls.dirs .countUntil(moveTo).to!int, chf);
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
        else if (_list.tiler.executeDir)
            currentDir = _ls.dirs[_list.tiler.executeDirID];
    }

private:
    void updateAccordingToBreadCurrentDir(
        KeepScrollingPosition ksp = KeepScrollingPosition.no
    ) {
        try
            _ls.currentDir = currentDir;
        catch (FileException e) {
            log(e.msg);
            if (currentDir == basedir && basedir !is null)
                // This throws if the dir doesn't exist afterwards
                basedir.mkdirRecurse();
            currentDir = basedir;
            return;
        }
        _list.tiler.loadDirsFiles(_ls.dirs, _ls.files, ksp);
    }
}
