module gui.picker.tilerlev;

// This is used in the main singleplayer browser,
// and in the replay browser.

import optional;

import std.conv;
import std.string;

import file.option;
import file.trophy;
import file.date;
import gui;
import gui.picker.tiler;
import level.metadata;
import file.replay;

abstract class LevelOrReplayTiler : FileTiler {
public:
    enum buttonYlg = 20;
    this(Geom g) { super(g); }

    @property int wheelSpeed() const { return 5; }
    @property int coarseness() const { return 1; }

    final @property int pageLen() const
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

    Geom newButtonGeom()
    {
        // x and y position don't matter, button will be repositioned later
        return new Geom(0, 0, xlg, buttonYlg);
    }
}

class LevelTiler : LevelOrReplayTiler {
public:
    this(Geom g) { super(g); }

protected:
    final override TextButton newFileButton(Filename fn, in int fileID)
    {
        assert (fn);
        TextButton ret;
        try {
            const dat = new LevelMetaData(fn);
            TrophyKey key;
            key.fileNoExt = fn.fileNoExtNoPre;
            key.title = dat.nameEnglish;
            key.author = dat.author;

            ret = new TextButton(newButtonGeom(), "%s%d. %s".format(
                fileID < 9 ? "  " : "", fileID + 1, dat.name));
            ret.checkFrame = determineCheckFrame(dat, getTrophy(key));
        }
        catch (Exception e) {
            ret = new TextButton(newButtonGeom(), fn.file);
        }
        ret.alignLeft = true;
        return ret;
    }

private:
    int determineCheckFrame(const(LevelMetaData) dat, Optional!Trophy tro)
    {
        if (tro.empty)
            return 0;
        Date troDate = tro.unwrap.built;
        return dat.built != troDate ? 3
            : tro.unwrap.lixSaved >= dat.required ? 2
            : 0;
        // Never display the little ring for looked-at-but-not-solved.
        // It makes people sad!
    }
}

class LevelWithFilenameTiler : LevelOrReplayTiler {
public:
    this(Geom g) { super(g); }

protected:
    final override TextButton newFileButton(Filename fn, in int fileID)
    {
        assert (fn);
        TextButton ret;
        try {
            const dat = new LevelMetaData(fn);
            ret = new TextButton(new Geom(0, 0, xlg, buttonYlg),
                // 21A6 is the mapsto arrow, |->
                "%s   \u21A6   %s".format(fn.fileNoExtNoPre, dat.name));
        }
        catch (Exception e) {
            ret = new TextButton(newButtonGeom(), fn.file);
        }
        ret.alignLeft  = true;
        return ret;
    }
}

class ReplayTiler : LevelOrReplayTiler {
public:
    this(Geom g) { super(g); }

protected:
    final override TextButton newFileButton(Filename fn, in int fileID)
    {
        auto ret = new TextButton(new Geom(0, 0, xlg, buttonYlg),
            fn.fileNoExtNoPre);
        ret.alignLeft = true;
        return ret;
    }
}
