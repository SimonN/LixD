module editor.gui.browter;

import std.algorithm;
import std.conv;
import std.string : representation;

import optional;

import basics.help : len;
import basics.globals;
import file.option;
import editor.hover;
import file.language;
import file.option;
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
        _picker = makePicker(allHoveredTiles, allowedPreExts, merge);
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
        _curDir = chosenTile.guaranteedDirOnly();
    }

private:
    Picker makePicker(
        const(Hover)[] allHoveredTiles,
        string allowedPreExts,
        MergeDirs merge
    ) {
        Picker commonCfgCode(T)(ref T cfg)
        {
            cfg.all   = new Geom(20, 40, xlg-40, ylg-60);
            cfg.bread = new Geom(0, 0, cfg.all.xl - 80, 30);
            cfg.files = new Geom(0, 40, cfg.all.xl, cfg.all.yl - 40);
            cfg.baseDir = dirImages;
            cfg.onFileSelect = (Filename fn) { _chosenTile = fn; };
            return new Picker(cfg);
        }
        final switch (merge) {
        case MergeDirs.allIntoRoot: {
            auto cfg = PickerConfig!(ImageBreadcrumb,
                ImageTiler!GadgetBrowserButton)();
            cfg.ls = allowedPreExts.canFind(preExtSteel)
                ? new SteelLs()
                : new MergeAllDirsLs(allowedPreExts);
            Picker p = commonCfgCode(cfg);
            p.currentDir = dirImages;
            return p;
        }
        case MergeDirs.depthTwo: {
            auto cfg = PickerConfig!(ImageBreadcrumb,
                ImageTiler!TerrainBrowserButton)();
            cfg.ls = new TilesetLs(dirImages, allowedPreExts);
            Picker p = commonCfgCode(cfg);
            p.navigateToAndHighlightFile(
                allowedTileOr(allHoveredTiles, allowedPreExts, _curDir.value),
                CenterOnHighlitFile.always);
            return p;
        }}
    }
}

private:

Filename allowedTileOr(
    const(Hover)[] hoveredTiles, // find a suitable tile among these
    string allowedPreExts, // require these pre-extensions to allow a tile
    Filename fallback, // if no tile was allowed, return this
) {
    bool allowedTile(in Hover hov) {
        auto name = hov.occ.tile.name;
        if (name.length < 2)
            return false;
        // This name check for type is bad. Replace the name in the tile
        // class with Optional!Filename and check for its pre-extension?
        return allowedPreExts.canFind(name[$-1])
            || allowedPreExts.canFind('\0') && name[$-2] != '.';
    }
    auto allowed = hoveredTiles.find!allowedTile;
    return allowed.length == 0 ? fallback
        : allowed[0].occ.tile.name.tileNameToFilename;
}

/*
 * This is very hackish. The tile library should do it instead.
 * Or redesign the tile browser to make this unnecessary.
 */
Filename tileNameToFilename(string name)
{
    return new VfsFilename(dirImages.rootless ~ name ~ ".png");
}

class ImageBreadcrumb : Breadcrumb {
public:
    this(Geom g, Filename aBaseDir) { super(g, aBaseDir); }

protected:
    override Filename makeAllowed(Filename candidate) const
    {
        MutFilename cand = candidate.guaranteedDirOnly;
        while (cand.dirRootless[baseDir.dirRootless.len .. $].count('/') > 2) {
            assert (cand.rootless[$-1] == '/');
            string s = cand.rootless[0 .. $-1];
            while (s.length && s[$-1] != '/')
                s = s[0 .. $-1];
            cand = new VfsFilename(s);
        }
        return cand;
    }

    override int makeButtons()
    {
        int iter = baseDir.dirRootless.len;
        for ( ; iter < currentDir.dirRootless.len; ++iter) {
            string cap = currentDir.dirRootless[0 .. iter];
            if (cap.len > 0 && cap[$-1] == '/') {
                addNewRightmostDirButton(cap);
                return iter;
            }
        }
        return 0;
    }
}

class SteelLs : MergeAllDirsLs {
public:
    this() { super([preExtSteel]); }

protected:
    override void sortFiles(MutFilename[] arr) const
    {
        bool hasEnd(string s, string tail)
        {
            return s.representation.length >= tail.representation.length
                && s.representation[$ - tail.representation.length .. $]
                == tail.representation;
        }
        int weight(Filename a)
        {
            return hasEnd(a.dirRootless, "/geoo/steel/") ? 0
                : hasEnd(a.dirRootless, "/amanda/steel/") ? 1
                // All uncaught tiles will go here in the middle. At the end:
                : hasEnd(a.dirRootless, "/geoo/construction/") ? 200
                : hasEnd(a.dirRootless, "/rod_steel/") ? 201
                : hasEnd(a.dirRootless, "/matt/steel/") ? 202
                : hasEnd(a.dirRootless, "/toys/") ? 203
                : hasEnd(a.dirRootless, "/overlays/") ? 204
                : 100;
        }
        bool steelLessThan(Filename a, Filename b)
        {
            immutable wa = weight(a);
            immutable wb = weight(b);
            return wa != wb ? wa < wb : a.fnLessThan(b);
        }
        arr.sort!steelLessThan;
    }
}
