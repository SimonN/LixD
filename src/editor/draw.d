module editor.draw;

import std.algorithm;

import basics.alleg5;
import editor.editor;
import graphic.color;
import graphic.cutbit;
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
    with (DrawingTarget(editor._map.albit))
{
    editor.clearScreenRectangle();
    editor.drawGadgets();
    editor.drawTerrain();
    editor.drawHover();
    editor.drawSelection();
}}

void clearScreenRectangle(Editor editor)
{
    with (editor._level) {
        immutable col = color.makecol(bgRed, bgGreen, bgBlue);
        editor._map.clear_screen_rectangle(col);
    }
}

void drawGadgets(Editor editor)
{
    foreach (gadgetList; editor._level.pos)
        foreach (g; gadgetList) {
            assert (g.ob && g.ob.cb);
            g.ob.cb.draw(editor._map, g.x, g.y);
        }
}

void drawTerrain(Editor editor)
{
    foreach (t; editor._level.terrain) {
        assert (t.ob);
        if (auto cb = t.dark ? t.ob.dark : t.ob.cb)
            cb.draw(editor._map, t.x, t.y, t.mirr, t.rot,
                    t.dark ? Cutbit.Mode.DARK_EDITOR : Cutbit.Mode.NORMAL);
    }
}

void drawHover(Editor) { }
void drawSelection(Editor) { }

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
