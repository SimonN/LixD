module editor.calc;

import std.algorithm;

import editor.editor;
import editor.select;
import gui.root;
import hardware.keyboard;
import hardware.mousecur;

package:

void implEditorCalc(Editor editor) { with (editor)
{
    if (_terrainBrowser) {
        if (_terrainBrowser.done) {
            rmFocus(_terrainBrowser);
            _terrainBrowser = null;
            _panel.allButtonsOff();
        }
    }
    else
        editor.noWindowsOpenCalc();
}}

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
    if (! _dragger.moving)
        return;
    auto movedBy = _dragger.movedSinceLastCall(_map);
    _selection.each!(tile => tile.moveBy(movedBy));
}}
