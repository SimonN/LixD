module gui.picker.tilerlev;

// This is used in the main singleplayer browser,
// and in the replay browser.

import std.conv;
import std.string;

import gui;
import gui.picker.tiler;
import level.level;

abstract class LevelOrReplayTiler : Tiler {
public:
    enum buttonYlg = 20;
    this(Geom g) { super(g); }

    final override @property int pageLen() const
    {
        return this.ylg.to!int / buttonYlg;
    }

protected:
    final override TextButton newDirButton(Filename fn)
    {
        assert (fn);
        return new TextButton(new Geom(0, 0, xlg,
            dirSizeMultiplier * buttonYlg), fn.dirInnermost);
    }

    final override float buttonXg(in int idFromTop) const { return 0; }
    final override float buttonYg(in int idFromTop) const
    {
        return idFromTop * buttonYlg;
    }
}

class LevelTiler : LevelOrReplayTiler {
public:
    this(Geom g) { super(g); }

protected:
    final override Button newFileButton(Filename fn, in int fileID)
    {
        assert (fn);
        Level level = new Level(fn);
        return new TextButton(new Geom(0, 0, xlg, buttonYlg),
            "%d. %s".format(fileID, level.name));
    }
}

class ReplayTiler : LevelOrReplayTiler {
public:
    this(Geom g) { super(g); }

protected:
    final override Button newFileButton(Filename fn, in int fileID)
    {
        // DTODO: placeholder method. Copy the relevant code here.
        return new TextButton(new Geom(0, 0, xlg, buttonYlg), fn.file);
    }
}
