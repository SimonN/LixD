module menu.rep4lev;

/*
 * RepForLev: When you have selected, but not yet started, a level in the
 * level browser, you may open RepForLev on that level.
 * RepForLev lists all replays within Lix's file tree for that level.
 * RepForLev only looks at a replay's basename and compares it with the
 * level's basename to determine whether the replay belongs to that level.
 */

import std.algorithm;

import optional;

import basics.globals;
import file.filename;
import file.language;
import opt = file.option.allopts;
import gui;
import gui.picker;
import hardware.mouse;
import hardware.tharsis;
import level.level;
import menu.repmatch;

class RepForLev : Window {
private:
    Picker _picker;
    TextButton _back;

    Filename _levelFn;

    // Optional + Rebindable = corrupt memory. Hack solution: Null in var name:
    // This variable can be legally null after RepForLev's constructor.
    MutFilename _replayFnNullUntilReplayIsSelected;
    bool _gotoBrowSin; // cancel the dialog

public:
    this(Filename aLevelFn, Level aLevel)
    in {
        assert (aLevelFn);
        assert (aLevel);
    }
    do {
        _levelFn = aLevelFn;
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg),
            Lang.repForLevTitle.translf(aLevel.name));
        commonConstructor();
    }

    const pure nothrow @safe @nogc {
        bool gotoBrowSin() { return _gotoBrowSin; }
        bool gotoGame() { return null !is _replayFnNullUntilReplayIsSelected; }
    }

    @property ReplayToLevelMatcher matcher()
    in { assert (gotoGame, "demand the matcher only when its data is ready"); }
    do {
        auto m = new ReplayToLevelMatcher(_replayFnNullUntilReplayIsSelected);
        m.forceLevel(_levelFn);
        return m;
    }

protected:
    override void calcSelf()
    {
        _gotoBrowSin = hardware.mouse.mouseClickRight || _back.execute;
    }

private:
    void commonConstructor()
    {
        {
            auto cfg = PickerConfig!(Breadcrumb, ReplayFinderTiler)();
            cfg.all = new Geom(20, 40, this.xlg - 40, this.ylg - 120);
            cfg.bread = new Geom(9999, 9999, 30, 30); // Hack, don't want bread
            cfg.files = new Geom(new Geom(0, 0, cfg.all.xlg, cfg.all.ylg));
            cfg.ls = new ReplayFinderLs(_levelFn);
            cfg.baseDir = dirReplays;
            cfg.showSearchButton = false;
            cfg.onFileSelect = (Filename fn) {
                _replayFnNullUntilReplayIsSelected = fn;
            };
            _picker = new Picker(cfg);

            version (tharsisprofiling)
                auto zone = Zone(profiler, "ls replays for " ~ _levelFn.file);
            _picker.currentDir = _picker.baseDir;
        }
        _back = new TextButton(new Geom(20, 20, 100, 40, From.BOTTOM_RIGHT),
            Lang.commonBack.transl);
        _back.hotkey = opt.keyMenuExit.value;
        addChildren(_picker, _back);
    }
}

private class ReplayFinderLs : Ls {
private:
    Filename _levelFn;

public:
    this(Filename aLevelFn) { _levelFn = aLevelFn; }

protected:
    final override bool searchCriterion(Filename fn) const
    {
        return fn.fileNoExtNoPre.length > _levelFn.fileNoExtNoPre.length
            && fn.fileNoExtNoPre[_levelFn.fileNoExtNoPre.length] == '-'
            && fn.fileNoExtNoPre.startsWith(_levelFn.fileNoExtNoPre);
    }

    final override MutFilename[] dirsInCurrentDir() const { return []; }
    final override MutFilename[] filesInCurrentDir() const
    {
        return currentDir.findTree(filenameExtReplay);
    }
}

private class ReplayFinderTiler : LevelOrReplayTiler {
public:
    this(Geom g) { super(g); }

protected:
    final override TextButton newFileButton(Filename fn, in int fileID)
    {
        auto ret = new TextButton(new Geom(0, 0, xlg, buttonYlg),
            fn.rootless[
                (fn.rootless.length > dirReplays.rootless.length
                    ? dirReplays.rootless.length : 0)
                .. (fn.rootless.length - fn.file.length
                    + fn.fileNoExtNoPre.length)]);
        ret.alignLeft = true;
        return ret;
    }
}
