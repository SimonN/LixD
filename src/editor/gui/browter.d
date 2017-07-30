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

public:
    this(string allowedPreExts, UserOptionFilename curDir, MergeAllDirs merge,
        Filename overrideStartDir)
    {
        assert (curDir !is null);
        _curDir = curDir;
        super(new Geom(0, 0, gui.screenXlg, gui.mapYlg, From.TOP),
            _curDir.descShort);
        _picker = merge ? makePicker!true(allowedPreExts)
                        : makePicker!false(allowedPreExts);
        _picker.basedir = dirImages;
        _picker.currentDir = merge ? dirImages
            : overrideStartDir && overrideStartDir.dirExists ? overrideStartDir
            : _curDir.value;
        _cancel = new TextButton(new Geom(
            20, 40, 80, 30, From.TOP_RIGHT), Lang.commonCancel.transl);
        _cancel.hotkey = keyMenuExit;
        addChildren(_picker, _cancel);
    }

    bool done() const
    {
        return chosenTile !is null || _cancel.execute || mouseClickRight;
    }

    Filename chosenTile() const
    {
        if (_picker.executeFile)
            return _picker.executeFileFilename;
        return null;
    }

    void saveDirOfChosenTileToUserCfg()
    {
        assert (chosenTile !is null);
        _curDir.value = chosenTile.guaranteedDirOnly();
    }

private:
    Picker makePicker(bool merge)(string allowedPreExts) const
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
        return new Picker(cfg);
    }
}
