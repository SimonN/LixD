module editor.gui.browter;

import basics.globals;
import basics.user;
import file.language;
import file.useropt;
import gui;
import gui.picker;
import hardware.mouse;

enum MergeAllDirs : bool { no = false, yes = true }

class TerrainBrowser : Window {
private:
    Picker _picker;
    TextButton _cancel;
    UserOptionFilename _curDir;
    MutFilename _chosenTile; // null until we're good to exit

public:
    this(string allowedPreExts, UserOptionFilename curDir, MergeAllDirs merge,
        Filename overrideStartDir)
    {
        assert (curDir !is null);
        _curDir = curDir;
        super(new Geom(0, 0, gui.screenXlg, gui.mapYlg, From.TOP),
            _curDir.lang.transl);
        _picker = merge ? makePicker!true(allowedPreExts)
                        : makePicker!false(allowedPreExts);
        _picker.currentDir = merge ? dirImages
            : overrideStartDir && overrideStartDir.dirExists ? overrideStartDir
            : _curDir.value;
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
    Picker makePicker(bool merge)(string allowedPreExts)
    {
        static if (merge) {
            auto cfg = PickerConfig!(ImageTiler!GadgetBrowserButton)();
            cfg.ls  = new RecursingImageLs(allowedPreExts);
        }
        else {
            auto cfg  = PickerConfig!(ImageTiler!TerrainBrowserButton)();
            cfg.ls = new ImageLs(allowedPreExts);
        }
        cfg.all   = new Geom(20, 40, xlg-40, ylg-60);
        cfg.bread = new Geom(0, 0, cfg.all.xl - 80, 30);
        cfg.files = new Geom(0, 40, cfg.all.xl, cfg.all.yl - 40);
        cfg.baseDir = dirImages;
        cfg.onFileSelect = (Filename fn) { _chosenTile = fn; };
        return new Picker(cfg);
    }
}
