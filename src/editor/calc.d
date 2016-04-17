module editor.calc;

import std.algorithm;

import basics.rect;
import basics.user; // hotkeys for movement
import editor.editor;
import editor.hover;
import editor.select;
import file.language; // select grid
import gui;
import hardware.keyboard;
import hardware.mousecur;

package:

void implEditorCalc(Editor editor)
{
    if      (editor._terrainBrowser) editor.calcTerrainBrowser();
    else if (editor._okCancelWindow) editor.calcOkCancelWindow();
    else                             editor.calcNoWindows();
}

private:

void calcNoWindows(Editor editor) {
    with (editor)
{
    _map.calcScrolling();
    if (_map.scrollingNow)
        mouseCursor.xf = 3;
    editor.handleNonstandardPanelButtons();
    editor.hoverTiles();
    editor.selectTiles();
    editor.moveTiles();
}}

void handleNonstandardPanelButtons(Editor editor) { with (editor)
{
    with (_panel.buttonFraming)
        on = hotkey.keyHeld || _dragger.framing ? true
           : hotkey.keyReleased ? false : on;
    with (_panel.buttonSelectAdd)
        on = hotkey.keyHeld     ? true
           : hotkey.keyReleased ? false : on;
    editor.selectGrid();
}}

void selectGrid(Editor editor)
{
    int g = editorGridSelected;
    scope (exit)
        editorGridSelected = g;
    g = (g == 1 || g == 2 || g == 16 || g == editorGridCustom) ? g : 1;
    assert (editor._panel.button(Lang.editorButtonGrid2));
    if (keyEditorGrid.keyTapped)
        g = () { switch (g) {
            case 16: return 1;
            case  1: return 2;
            case  2: return editorGridCustom;
            default: return 16;
        }}();
    else {
        void check(Button b, in int targetGrid)
        {
            if (b.execute)
                g = (b.on ? 1 : targetGrid);
            b.on = (g == targetGrid);
        }
        with (editor._panel) {
            check(button(Lang.editorButtonGrid2), 2);
            check(button(Lang.editorButtonGridCustom), editorGridCustom);
            check(button(Lang.editorButtonGrid16), 16);
        }
    }
}

void moveTiles(Editor editor) {
    with (editor)
{
    immutable grid = editorGridSelected;
    immutable movedByKeyboard
        = Point(-grid, 0) * keyEditorLeft .keyTappedAllowingRepeats
        + Point(+grid, 0) * keyEditorRight.keyTappedAllowingRepeats
        + Point(0, -grid) * keyEditorUp   .keyTappedAllowingRepeats
        + Point(0, +grid) * keyEditorDown .keyTappedAllowingRepeats;
    immutable total = movedByKeyboard
                    + _dragger.snapperShouldMoveBy(_map, grid);
    if (total != Point(0, 0))
        _selection.each!(tile => tile.moveBy(total));
}}

// ############################################################################

void calcTerrainBrowser(Editor editor) {
    with (editor)
{
    if (_terrainBrowser.done) {
        auto pos = _level.addTileWithCenterAt(_terrainBrowser.chosenTile,
                                              _map.mouseOnLand);
        rmFocus(_terrainBrowser);
        editor.closeWindows();
        if (pos)
            _selection = [ Hover.newViaEvilDynamicCast(_level, pos) ];
    }
}}

void calcOkCancelWindow(Editor editor) {
    with (editor)
{
    if (_okCancelWindow.done) {
        _okCancelWindow.writeChangesTo(_level);
        rmFocus(_okCancelWindow);
        editor.closeWindows();
    }
}}

void closeWindows(Editor editor) {
    with (editor)
{
    _terrainBrowser = null;
    _okCancelWindow = null;
    _panel.allButtonsOff();
    editor.selectGrid(); // grid button flickers otherwise
}}
