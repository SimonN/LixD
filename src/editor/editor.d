module editor.editor;

/*
 * Rough MVC separation:
 * The model is the Level.
 * The view is MapAndCamera.
 * The controller is all the modules in editor.*, and they pass changes
 * to the model via the UndoRedoStack in class Editor.
 */

import enumap;

import editor.calc;
import editor.dragger;
import editor.draw;
import editor.gui.browter;
import editor.gui.okcancel;
import editor.gui.panel;
import editor.io;
import editor.stack;
import editor.undoable.base;
import file.filename;
import graphic.camera.mapncam;
import gui.iroot;
import gui.root;
import gui.msgbox;
import level.level;
import level.oil;
import menu.browser.saveas;
import tile.occur;
import tile.gadtile;

class Editor : IRoot {
private:
    /*
     * To access the level or the undo stack within the editor.* package,
     * see below for package-visible methods of Editor.
     */
    UndoRedoStackThatMergesTileMoves _undoRedo;
    Level _level;

package:
    MapAndCamera _map; // level background color, and gadgets
    MapAndCamera _mapTerrain; // transp, to render terrain, later blit to _map
    Level _levelToCompareForDataLoss;

    bool _gotoMainMenuOnceAllWindowsAreClosed;
    EditorPanel _panel;
    MouseDragger _dragger;

    OilSet _hover;
    OilSet _selection;

    MsgBox         _askForDataLoss;
    TerrainBrowser _terrainBrowser;
    OkCancelWindow _okCancelWindow;
    SaveBrowser    _saveBrowser;

public:
    this()
    {
        this.implConstructor(newEmptyLevel, null);
    }

    this(Filename fn) // may not be null;
    in { assert (fn !is null, "Call this(), not this(fn), for empty level"); }
    do {
        this.implConstructor(delegate Level() { return new Level(fn); }, fn);
    }

    void dispose()
    {
        if (_panel) {
            rmElder(_panel);
            _panel = null;
        }
    }

    bool gotoMainMenu() const pure nothrow @safe @nogc
    {
        return _gotoMainMenuOnceAllWindowsAreClosed && noWindows;
    }

    // Let's prevent data loss from crashes inside the editor.
    // When you catch a D Error (e.g., assertion failure) in the app's main
    // loop, tell the editor to dump the level.
    void emergencySave() const
    {
        import basics.globals;
        level.saveToFile(new VfsFilename(dirLevels.dirRootless
                                       ~ "editor-emergency-save.txt"));
    }

    void calc() { this.implEditorCalc(); }
    void work() { this.implEditorWork(); }

    // We always draw ourselves.
    void reqDraw() { }
    bool draw() { this.implEditorDraw(); return mainUIisActive; }

package:
/*
 * Interaction with the level and the undo stack:
 */
    void setLevelAndCreateUndoStack(
        Level delegate() newLevelFunc, // this should new a Level and return it
        Filename fnOrNull, // null iff new level that was never saved/loaded
    ) {
        _hover = new OilSet;
        _selection = new OilSet;
        _undoRedo = new UndoRedoStackThatMergesTileMoves();
        _panel.currentFilenameOrNull = fnOrNull;
        _level = newLevelFunc();
        _levelToCompareForDataLoss = newLevelFunc();
    }

    @property Level levelRefacme() pure nothrow @nogc
    {
        return _level;
    }

    @property const(Level) level() const pure nothrow @nogc
    {
        return _level;
    }

    void apply(Command)(Command cmd)
        if (is (Command : Undoable))
    {
        _selection = _undoRedo.apply(_level, cmd).clone;
    }

    void applyAndTrustThatTheSelectionWillNotChange(Command)(Command cmd)
        if (is (Command : Undoable))
    {
        _undoRedo.apply(_level, cmd);
    }

    void undoOne() { _selection = _undoRedo.undoOne(_level).clone; }
    void redoOne() { _selection = _undoRedo.redoOne(_level).clone; }
    void stopCurrentMove() { _undoRedo.stopCurrentMove(); }

/*
 * Remaining package methods that aren't about the stack:
 */

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
    @property bool noWindows() const pure nothrow @safe @nogc
    {
        return ! _askForDataLoss && ! _terrainBrowser && ! _okCancelWindow
            && ! _saveBrowser;
    }
}
