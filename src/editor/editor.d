module editor.editor;

/* I would like some MVC separation here. The model is class Level.
 * The Editor is Controller and View.
 */

import enumap;

import editor.calc;
import editor.dragger;
import editor.draw;
import editor.gui.browter;
import editor.gui.okcancel;
import editor.hover;
import editor.io;
import editor.gui.panel;
import file.filename;
import graphic.camera.mapncam;
import gui.iroot;
import gui.msgbox;
import level.level;
import menu.browser.saveas;
import tile.occur;
import tile.gadtile;

class Editor : IRoot {
package:
    MapAndCamera _map; // level background color, and gadgets
    MapAndCamera _mapTerrain; // transp, to render terrain, later blit to _map
    Level _level;
    Level _levelToCompareForDataLoss;
    MutFilename _loadedFrom; // whenever this changes, notify the panel

    bool _gotoMainMenuOnceAllWindowsAreClosed;
    EditorPanel _panel;
    MouseDragger _dragger;

    Hover[] _hover;
    Hover[] _selection;

    MsgBox         _askForDataLoss;
    TerrainBrowser _terrainBrowser;
    OkCancelWindow _okCancelWindow;
    SaveBrowser    _saveBrowser;

public:
    this(Filename fn)
    {
        _loadedFrom = fn;
        this.implConstructor();
    }

    ~this() { this.implDestructor(); }

    bool gotoMainMenu() const
    {
        return _gotoMainMenuOnceAllWindowsAreClosed && noWindows;
    }

    // Let's prevent data loss from crashes inside the editor.
    // When you catch a D Error (e.g., assertion failure) in the app's main
    // loop, tell the editor to dump the level.
    void emergencySave() const
    {
        import basics.globals;
        _level.saveToFile(new VfsFilename(dirLevels.dirRootless
                                       ~ "editor-emergency-save.txt"));
    }

    void calc() { this.implEditorCalc(); }
    void work() { this.implEditorWork(); }

    // We always draw ourselves.
    void reqDraw() { }
    bool draw() { this.implEditorDraw(); return mainUIisActive; }

package:
    // Verify this when you would like to open new windows.
    @property bool mainUIisActive() const
    {
        return noWindows && ! _gotoMainMenuOnceAllWindowsAreClosed;
    }

    // you can drag tiles onto the panel to delete them
    @property bool aboutToTrash() const
    {
        assert (_dragger && _panel);
        return _dragger.moving && _panel.isMouseHere;
    }

private:
    @property bool noWindows() const
    {
        return ! _askForDataLoss && ! _terrainBrowser && ! _okCancelWindow
            && ! _saveBrowser;
    }
}
