module editor.gui.browter;

import std.algorithm;
import std.conv;
import std.string : representation;

import optional;

import basics.help : len;
import basics.globals;
import basics.user;
import editor.hover;
import file.language;
import file.useropt;
import gui;
import gui.picker;
import hardware.mouse;

enum MergeDirs : int {
    depthTwo = 1,
    allIntoRoot = 2,
}

class TerrainBrowser : Window {
private:
    Picker _picker;
    TextButton _cancel;
    UserOptionFilename _curDir;
    MutFilename _chosenTile; // null until we're good to exit

public:
    this(string allowedPreExts, UserOptionFilename curDir, MergeDirs merge,
        /*
         * If this array contains at least one hover that points to a tile
         * with an allowed pre-extension, the first such tile in the hover
         * determines the starting directory.
         */
        const(Hover)[] allHoveredTiles
    ) {
        assert (curDir !is null);
        _curDir = curDir;
        super(new Geom(0, 0, gui.screenXlg, gui.mapYlg, From.TOP),
            _curDir.lang.transl);
        _picker = makePicker(allowedPreExts, merge);
        _picker.currentDir = merge == MergeDirs.allIntoRoot ? dirImages
            : suitableDepthTwoDir(allHoveredTiles, allowedPreExts);
        _cancel = new TextButton(new Geom(
            20, 40, 80, 30, From.TOP_RIGHT), Lang.commonCancel.transl);
        _cancel.hotkey = keyMenuExit;
        addChildren(_picker, _cancel);
    }

    @property bool done() const
    {
        return chosenTile !is null || _cancel.execute || mouseClickRight;
    }

    @property Filename chosenTile() const { return _chosenTile; }

    void saveDirOfChosenTileToUserCfg()
    {
        assert (chosenTile !is null);
        _curDir.value = chosenTile.guaranteedDirOnly();
    }

private:
    Picker makePicker(string allowedPreExts, MergeDirs merge)
    {
        void commonCfgCode(T)(ref T cfg)
        {
            cfg.all   = new Geom(20, 40, xlg-40, ylg-60);
            cfg.bread = new Geom(0, 0, cfg.all.xl - 80, 30);
            cfg.files = new Geom(0, 40, cfg.all.xl, cfg.all.yl - 40);
            cfg.baseDir = dirImages;
            cfg.onFileSelect = (Filename fn) { _chosenTile = fn; };
        }
        final switch (merge) {
        case MergeDirs.allIntoRoot:
            auto cfg = PickerConfig!(ImageTiler!GadgetBrowserButton)();
            cfg.ls = new MergeAllDirsLs(allowedPreExts);
            commonCfgCode(cfg);
            return new Picker(cfg);
        case MergeDirs.depthTwo:
            auto cfg = PickerConfig!(ImageTiler!TerrainBrowserButton)();
            cfg.ls = new TilesetLs(dirImages, allowedPreExts);
            commonCfgCode(cfg);
            return new Picker(cfg);
        }
    }

    Filename suitableDepthTwoDir(
        const(Hover)[] allHoveredTiles,
        string allowedPreExts
    ) const
    {
        // Return either dirImages or exactly a 2-depth subdir.
        Filename makeSuitable(Filename candidate)
        {
            const string full = candidate.rootless;
            if (full.length < dirImages.rootless.length)
                return dirImages;
            assert (dirImages.rootless[$-1] == '/');
            auto tail = full[dirImages.rootless.length .. $].representation;
            if (tail.count('/') < 2)
                return dirImages;
            tail.findSkip("/");
            tail.findSkip("/");
            return new VfsFilename(full[0 .. full.length - tail.length]);
        }
        bool allowedTile(in Hover hov)
        {
            auto name = hov.occ.tile.name;
            if (name.length < 2)
                return false;
            // This name check for type is bad. Replace the name in the tile
            // class with Optional!Filename and check for its pre-extension?
            return allowedPreExts.canFind(name[$-1])
                || allowedPreExts.canFind('\0') && name[$-2] != '.';
        }
        auto ret = allHoveredTiles.find!allowedTile;
        return makeSuitable(ret.length == 0 ? _curDir.value
            : new VfsFilename(dirImages.rootless ~ ret[0].occ.tile.name));
    }
}
