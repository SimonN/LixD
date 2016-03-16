module gui.picker.picker;

import gui;
import gui.picker;

class Picker : Frame {
private:
    Ls _ls;
    Tiler _tiler;
    Scrollbar _scrollbar;

    MutFilename _basedir;

public:
    // Create both arguments separately, then give them to this class.
    static typeof(this) newPicker(T)(Geom g, Ls ls)
        if (is (T : Tiler))
    {
        assert (g.xl >= 20);
        assert (ls);
        return new typeof(this)(g, ls, new T(new Geom(0, 0, g.xl - 20, g.yl)));
    }

    @property Filename basedir() const { return _basedir; }
    @property Filename basedir(Filename fn)
    {
        assert (fn);
        _basedir = fn;
        if (! _ls.currentDir || ! _ls.currentDir.isChildOf(_basedir))
            currentDir = _basedir;
        return basedir;
    }

    @property Filename currentDir() const { return _ls.currentDir; }
    @property Filename currentDir(Filename fn)
    {
        if (! fn) {
            if (basedir)
                currentDir = basedir;
            return currentDir;
        }
        if (currentDir == fn)
            return currentDir;
        _ls.currentDir = (basedir && ! fn.isChildOf(basedir))
                        ? basedir : fn;
        _tiler.loadDirsFiles(_ls.dirs, _ls.files);
        _scrollbar.totalLen = _tiler.totalLen;
        _scrollbar.pos = 0;
        return currentDir;
    }

    override void calcSelf()
    {
        if (_tiler.executeDir)
            currentDir = _ls.dirs[_tiler.executeDirID];
        else if (_scrollbar.execute)
            _tiler.top = _scrollbar.pos;
    }

private:
    this(Geom g, Ls ls, Tiler tiler)
    {
        super(g);
        _ls        = ls;
        _tiler     = tiler;
        _scrollbar = new Scrollbar(new Geom(0, 0, 20, g.yl, From.RIGHT));
        _scrollbar.pageLen = _tiler.pageLen;
        addChildren(_tiler, _scrollbar);
    }
}
