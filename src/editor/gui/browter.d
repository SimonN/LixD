module editor.gui.browter;

import basics.globals;
import basics.user;
import file.language;
import gui;
import gui.picker;
import hardware.mouse;

class TerrainBrowser : Window {
private:
    Picker _picker;
    TextButton _cancel;

public:
    this(string allowedPreExts)
    {
        super(new Geom(0, 0, Geom.screenXlg, Geom.mapYlg, From.TOP),
            Lang.addTerrain.transl);
        auto cfg  = PickerConfig!ImageTiler();
        cfg.all   = new Geom(20, 40, xlg-140, ylg-60);
        cfg.bread = new Geom(0, 0, cfg.all.xl, 30);
        cfg.files = new Geom(0, 40, cfg.all.xl, cfg.all.yl - 40);
        cfg.ls    = new ImageLs(allowedPreExts);
        _picker = new Picker(cfg);
        _picker.basedir = dirImages;
        _picker.currentDir = new Filename("./images/simon/earth/");
        _cancel = new TextButton(new Geom(
            20, 20, 80, 40, From.BOTTOM_RIGHT), Lang.commonCancel.transl);
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
}
