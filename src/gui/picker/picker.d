module gui.picker.picker;

/*
 * Navigate directories and select files from them.
 * To be notified of selected files and directories, register callbacks:
 * onDirSelect, onFileSelect. Register these directly in the PickerConfig.
 */

import std.algorithm;
import std.file; // FileException
import std.conv;

import file.log;
import gui;
import gui.picker;

struct PickerConfig(Br, Ti)
    if (is (Br : Breadcrumb) && is (Ti : FileTiler)
) {
    Geom all;
    Geom bread; // Picker will deduct xlg for search button if you want one
    Geom files; // Tiler including scrollbar
    Ls ls;
    MutFilename baseDir;
    bool showSearchButton;

    void delegate(Filename) onDirSelect;
    void delegate(Filename) onFileSelect;
}

class Picker : Element {
private:
    Breadcrumb _bread;
    Ls _ls;
    ScrolledFiles _list;

    TextButton _searchButton; // null when not wanted by PickerConfig
    LevelSearch _searchWindow; // null when closed

    void delegate(Filename) _onDirSelect;
    void delegate(Filename) _onFileSelect;

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
    this(Br, Ti)(PickerConfig!(Br, Ti) cfg)
    out {
        assert (_ls);
    }
    body {
        super(cfg.all);
        import graphic.color;
        undrawColor = color.transp; // Hack. Picker should not be a drawable
                                    // element, but rather only have children.
        if (cfg.showSearchButton)
            cfg.bread.xl -= Breadcrumb.butXl;
        _bread = new Br(cfg.bread, cfg.baseDir);
        _ls = cfg.ls;
        _list = new ScrolledFiles(cfg.files, delegate FileTiler(Geom gg)
        {
            auto t = new Ti(gg);
            t.onDirSelect = (int id) { currentDir = _ls.dirs[id]; };
            if (cfg.onFileSelect)
                t.onFileSelect = (int id) { cfg.onFileSelect(_ls.files[id]); };
            return t;
        });
        if (cfg.showSearchButton)
            createSearchButton(cfg.onFileSelect);
        addChildren(_bread, _list);
        _onDirSelect = cfg.onDirSelect;
        _onFileSelect = cfg.onFileSelect;
    }

    @property Filename baseDir() const { return _bread.baseDir; }
    @property Filename currentDir() const { return _bread.currentDir; }
    @property Filename currentDir(Filename fn)
    {
        if (! currentDir || (fn && fn.dirRootless != currentDir.dirRootless)) {
            _bread.currentDir = fn;
            updateAccordingToBreadCurrentDir();
        }
        return currentDir;
    }

    void highlightNothing() { _list.tiler.highlightNothing(); }
    bool highlightFile(int i, CenterOnHighlitFile chf)
    {
        return _list.tiler.highlightFile(i, chf);
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
    }

private:
    /*
     * I don't know whether updateAccording...'s callers should have
     * checked and prevented unneccessary calls, or wethere updateAccording...
     * should abort when it realizes that no work has to be done.
     * Well, I'll let updateAccording... fire an event every time it's called.
     * If we fire this too often, investigate.
     */
    void updateAccordingToBreadCurrentDir(
        KeepScrollingPosition ksp = KeepScrollingPosition.no
    ) {
        try
            _ls.currentDir = currentDir;
        catch (FileException e) {
            log(e.msg);
            if (currentDir == baseDir && baseDir !is null)
                // This throws if the dir doesn't exist afterwards
                baseDir.mkdirRecurse();
            currentDir = baseDir;
            return;
        }
        _list.tiler.loadDirsFiles(_ls.dirs, _ls.files, ksp);
        if (_onDirSelect)
            _onDirSelect(currentDir);
    }

    void createSearchButton(void delegate(Filename) aOnFileSelect)
    in {
        assert (_bread, "create breadcrumb navigation first");
        assert (aOnFileSelect, "you should provide onFileSelect if you "
        ~ "need the search button, to do something at all with the result");
    }
    body {
        import file.option;
        import file.language;
        _searchButton = new TextButton(new Geom(0, 0, Breadcrumb.butXl,
            _bread.ylg, From.TOP_RIGHT), Lang.browserSearch.transl);
        _searchButton.hotkey = file.option.keyMenuSearch;

        _searchButton.onExecute = ()
        {
            assert (! _searchWindow);
            _searchWindow = new LevelSearch();
            _searchWindow.onDone = (Filename fn)
            {
                _searchWindow = null;
                if (! fn)
                    return;
                this.currentDir = fn;
                aOnFileSelect(fn);
            };
            addFocus(_searchWindow);
        };
        addChild(_searchButton);
    }
}
