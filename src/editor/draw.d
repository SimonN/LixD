module editor.draw;

import basics.alleg5;
import editor.editor;
import graphic.color;
import hardware.display;
import tile.gadtile;

package:

void implEditorDraw(Editor editor)
{
    editor.drawToMap();
    editor.drawToScreen();
}

private:

void drawToMap(Editor editor) {
    with (editor)
    with (DrawingTarget(_map.albit))
{
    _map.clear_screen_rectangle(color.makecol(
        _level.bgRed, _level.bgGreen, _level.bgBlue));
}}

void drawToScreen(Editor editor) {
    with (editor)
    with (DrawingTarget(display.al_get_backbuffer))
{
    _map.drawCamera();
    import graphic.textout;
    import basics.user;
    drawText(djvuM, "To exit the editor, press "
        ~ keyEditorExit.hotkeyNiceBrackets ~ ".", 10, 10, color.white);
}}
