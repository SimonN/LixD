module gui.picker.tilerlev;

import std.conv;
import std.string;

import gui;
import gui.picker.tiler;
import level.level;

class LevelTiler : Tiler {
public:
    enum buttonYlg = 20;
    this(Geom g) { super(g); }

protected:
    override @property int pageLen() const
    {
        return this.ylg.to!int / buttonYlg;
    }

    override TextButton newDirButton(Filename fn)
    {
        assert (fn);
        return new TextButton(new Geom(0, 0, xlg,
            dirSizeMultiplier * buttonYlg), fn.dirInnermost);
    }

    override Button newFileButton(Filename fn, in int fileID)
    {
        assert (fn);
        Level level = new Level(fn);
        return new TextButton(new Geom(0, 0, xlg, buttonYlg),
            "%d. %s".format(fileID, level.name));
    }

    override float buttonXg(in int idFromTop) const { return 0; }
    override float buttonYg(in int idFromTop) const
    {
        return idFromTop * buttonYlg;
    }
}
