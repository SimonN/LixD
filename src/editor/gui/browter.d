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
    UpOneDirButton _upOneDir;
    TextButton _cancel;

public:
    this(string allowedPreExts)
    {
        super(new Geom(0, 0, Geom.screenXlg, Geom.mapYlg, From.TOP),
            Lang.addTerrain.transl);
        _picker = Picker.newPicker!ImageTiler(
            new Geom(20, 40, xlg - 140, ylg - 60),
            new ImageLs(allowedPreExts));
        _picker.basedir = dirImages;
        _picker.currentDir = new Filename("./images/simon/earth/");
        _upOneDir = new UpOneDirButton(new Geom(
            20, 80, 80, 40, From.BOTTOM_RIGHT), _picker);
        _cancel = new TextButton(new Geom(
            20, 20, 80, 40, From.BOTTOM_RIGHT), Lang.commonCancel.transl);
        _cancel.hotkey = keyMenuExit;
        addChildren(_picker, _upOneDir, _cancel);
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
