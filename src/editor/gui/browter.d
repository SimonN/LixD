module editor.gui.browter;

import editor.gui.listbit;
import file.language;
import gui;

class TerrainBrowser : Window {
private:
    TextButton _cancel;
    ListDir    _dirList;
    ListBitmap _fileList;

    enum dirListXl = 80f;

public:
    this()
    {
        super(new Geom(0, 0, Geom.screenXlg, Geom.mapYlg, From.TOP),
            Lang.addTerrain.transl);
        _cancel = new TextButton(
            new Geom(20, 20, dirListXl, 40, From.BOTTOM_LEFT),
            Lang.commonCancel.transl);
        addChild(_cancel);
    }

    bool   done()       const { return chosenTile != null || _cancel.execute; }
    string chosenTile() const { return null; }
}
