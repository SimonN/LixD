module editor.calc;

import std.algorithm;
import std.format;
import std.range;

import basics.rect;
import basics.user; // hotkeys for movement
import editor.editor;
import editor.hover;
import editor.io;
import editor.select;
import file.language; // select grid
import gui;
import hardware.keyboard;
import hardware.mousecur;

package:

void implEditorWork(Editor editor)
{
    editor.maybeCloseTerrainBrowser();
    editor.maybeCloseOkCancelWindow();
    editor.maybeCloseSaveBrowser();
    editor.selectGrid();
    if (! editor.mainUIisActive) {
        // This is probably a bad hack.
        // Otherwise, the hover description remains on the info bar even
        // with windows open. When the editor doesn't have focus: bar empty.
        editor._panel.forceClearInfo();
    }
    // Massive hack! Otherwise, the info bar is blit over the save browser.
    // I should find out why.
    editor._panel.shown = editor._saveBrowser is null;
}

void implEditorCalc(Editor editor) {
    with (editor)
{
    assert (_panel);
    _map.calcScrolling();
    if (aboutToTrash)
        mouseCursor.yf = 2; // trashcan
    else if (_map.scrollingNow)
        mouseCursor.xf = 3; // scrolling arrows
    if (! _dragger.framing && ! _dragger.moving)
        _panel.calc();
    else
        _panel.calcButDisableMouse();
    editor.handleNonstandardPanelButtons();
    editor.hoverTiles();
    editor.selectTiles();
    editor.moveTiles();
    editor._panel.info = editor.describeHover();
}}

package:

void handleNonstandardPanelButtons(Editor editor) { with (editor)
{
    with (_panel.buttonFraming)
        on = hotkey.keyHeld || _dragger.framing ? true
           : hotkey.keyReleased ? false : on;
    with (_panel.buttonSelectAdd)
        on = hotkey.keyHeld     ? true
           : hotkey.keyReleased ? false : on;
    with (_panel.buttonZoom) {
        if (executeLeft)
            _map.zoomIn();
        if (executeRight)
            _map.zoomOut();
    }
}}

void selectGrid(Editor editor)
{
    int g = editorGridSelected;
    scope (exit)
        editorGridSelected = g;
    g = (g == 1 || g == 2 || g == 16 || g == editorGridCustom.value) ? g : 1;
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
    immutable grid = editorGridSelected.value;
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

string describeHover(Editor editor) { with (editor)
{
    const(Hover[]) list = _hover.empty ? _selection : _hover;
    if (list.empty)
        return "";
    string name = list.length == 1
        ? list[0].tileDescription
        : "%d %s".format(list.length, list is _hover
            ? Lang.editorBarHover.transl : Lang.editorBarSelection.transl);
    int x = list.map!(hov => hov.occ.loc.x).reduce!min;
    int y = list.map!(hov => hov.occ.loc.y).reduce!min;
    return "%s %s (%d, %d) (\u2080\u2093%X, \u2080\u2093%X)"
        .format(name, Lang.editorBarAt.transl, x, y, x, y);
}}

// ############################################################################

void maybeCloseTerrainBrowser(Editor editor) {
    with (editor)
{
    if (! _terrainBrowser || ! _terrainBrowser.done)
        return;
    if (auto pos = _level.addTileWithCenterAt(_terrainBrowser.chosenTile,
                    _map.mouseOnLand.roundTo(editorGridSelected))
    ) {
        _selection = [ Hover.newViaEvilDynamicCast(_level, pos) ];
        _terrainBrowser.saveDirOfChosenTileToUserCfg();
    }
    rmFocus(_terrainBrowser);
    _terrainBrowser = null;
    _panel.allButtonsOff();
}}

void maybeCloseOkCancelWindow(Editor editor) {
    with (editor)
{
    if (! _okCancelWindow || ! _okCancelWindow.done)
        return;
    assert (_okCancelWindow.done);
    _okCancelWindow.writeChangesTo(_level);
    rmFocus(_okCancelWindow);
    _okCancelWindow = null;
    _panel.allButtonsOff();
}}

void maybeCloseSaveBrowser(Editor editor) {
    with (editor)
{
    if (! _saveBrowser || ! _saveBrowser.done)
        return;
    if (_saveBrowser.chosenFile) {
        _loadedFrom = _saveBrowser.chosenFile;
        _panel.currentFilename = _loadedFrom;
        editor.saveToExistingFile();
    }
    rmFocus(_saveBrowser);
    _saveBrowser = null;
    _panel.allButtonsOff();
}}
