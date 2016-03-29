module gui.picker.tilerlev;

// This is used in the main singleplayer browser,
// and in the replay browser.

import std.conv;
import std.string;

import gui;
import gui.picker.tiler;
import level.metadata;
import game.replay;

static import basics.user;

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
    final override TextButton newFileButton(Filename fn, in int fileID)
    {
        assert (fn);
        const result = basics.user.getLevelResult(fn);
        const dat = new LevelMetaData(fn);
        auto  ret = new TextButton(new Geom(0, 0, xlg, buttonYlg),
            "%s%d. %s".format(fileID < 9 ? "  " : null, fileID + 1, dat.name));
        ret.alignLeft  = true;
        ret.checkFrame = result is null       ? 0
            : result.built    != dat.built    ? 3
            : result.lixSaved >= dat.required ? 2 : 0;
            // Never display the little ring for looked-at-but-didn't-solve.
            // It makes people sad!
        return ret;
    }
}

class ReplayTiler : LevelOrReplayTiler {
public:
    this(Geom g) { super(g); }

protected:
    final override TextButton newFileButton(Filename fn, in int fileID)
    {
        const replay = Replay.loadFromFile(fn);
        auto  level  = new LevelMetaData(fn); // included level
        if (level.empty)
            level = new LevelMetaData(replay.levelFilename); // pointed-to lvl
        auto ret = new TextButton(new Geom(0, 0, xlg, buttonYlg),
            "%s (%s)".format(level.name, replay.playerLocalName));
        ret.alignLeft = true;
        return ret;
    }
}
