module gui.picker.picker;

import gui;
import gui.picker;

class Picker(T) : Frame if (is (T : Tiler)) {
private:
    Ls _ls;
    Tiler _tiler;
    Scrollbar _scrollbar;

    MutFilename _basedir;

public:
    this(Geom g)
    {
        assert (g.xl >= 20);
        super(g);
        _tiler     = new T        (new Geom(0, 0, g.xl - 20, g.yl));
        _scrollbar = new Scrollbar(new Geom(0, 0, 20, g.yl, From.RIGHT));
        _ls        = new Ls;
        addChildren(_tiler, _scrollbar);
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
        return currentDir;
    }
}
