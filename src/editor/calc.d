module editor.calc;

import std.algorithm;

import basics.rect;
import basics.user; // hotkeys for movement
import editor.editor;
import editor.hover;
import editor.select;
import gui.root;
import hardware.keyboard;
import hardware.mousecur;

package:

void implEditorCalc(Editor editor)
{
    if (editor._terrainBrowser)
        editor.calcTerrainBrowser();
    else
        editor.noWindowsOpenCalc();
}

private:

void noWindowsOpenCalc(Editor editor) { with (editor)
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
}}

void moveTiles(Editor editor) { with (editor)
{
    // DTODO: When we move by mouse dragging, snap the entire selection to
    // the grid, according to one of its pieces. Look into the C++ source
    // for how exactly to snap. Don't snap each piece individually.
    immutable movedByMouse
        = _dragger.moving ? _dragger.movedSinceLastCall(_map) : Point(0, 0);
    immutable movedByKeyboard
        = Point(-_grid, 0) * keyEditorLeft .keyTappedAllowingRepeats
        + Point(+_grid, 0) * keyEditorRight.keyTappedAllowingRepeats
        + Point(0, -_grid) * keyEditorUp   .keyTappedAllowingRepeats
        + Point(0, +_grid) * keyEditorDown .keyTappedAllowingRepeats;
    immutable total = movedByMouse + movedByKeyboard;
    if (total != Point(0, 0))
        _selection.each!(tile => tile.moveBy(total));
}}

// ############################################################################

void calcTerrainBrowser(Editor editor) { with (editor)
{
    if (_terrainBrowser.done) {
        auto pos = _level.addTileWithCenterAt(_terrainBrowser.chosenTile,
                                              _map.mouseOnLand);
        rmFocus(_terrainBrowser);
        _terrainBrowser = null;
        _panel.allButtonsOff();
        if (pos)
            _selection = [ Hover.newViaEvilDynamicCast(_level, pos) ];
    }
}}
