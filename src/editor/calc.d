module editor.calc;

import editor.editor;
import editor.select;
import hardware.keyboard;
import hardware.mousecur;

package:

void implEditorCalc(Editor editor) { with (editor)
{
    _map.calcScrolling();
    if (_map.scrollingNow)
        mouseCursor.xf = 3;
    editor.handleNonstandardPanelButtons();
    editor.hoverTiles();
    editor.selectTiles();
}}

private:

void handleNonstandardPanelButtons(Editor editor) { with (editor)
{
    auto fra = _panel.buttonFraming;
    if (_dragger.framing || fra.hotkey.keyHeld)
        fra.on = true;
    else if (fra.hotkey.keyReleased)
        fra.on = false;
}}
