module editor.calc;

import editor.editor;
import hardware.mousecur;

package:

void implEditorCalc(Editor editor) { with (editor)
{
    // make a gui and query a button instead
    import hardware.keyboard;
    import basics.user;
    if (keyEditorExit.keyTapped) {
        _gotoMainMenu = true;
        return;
    }
    _map.calcScrolling();
    if (_map.scrollingNow)
        mouseCursor.xf = 3;
}}
