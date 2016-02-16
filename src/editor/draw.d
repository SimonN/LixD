module editor.draw;

import std.algorithm;

import basics.alleg5;
import editor.editor;
import graphic.color;
import graphic.cutbit;
import hardware.display;
import hardware.tharsis;
import tile.gadtile;

package:

void implEditorDraw(Editor editor)
{
    auto zone = Zone(profiler, "Editor.implEditorDraw");
    editor.drawToMap();
    editor.drawToScreen();
}

private:

void drawToMap(Editor editor) {
    with (Zone(profiler, "Editor.drawToMap"))
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
    editor._map.clear_screen_rectangle(color.transp);
}

void drawGadgets(Editor editor)
{
    auto zone = Zone(profiler, "Editor.drawGadgets");
    foreach (gadgetList; editor._level.pos)
        foreach (g; gadgetList) {
            assert (g.ob && g.ob.cb);
            g.ob.cb.draw(editor._map, g.x, g.y);
        }
}

// Bug: If we draw the terrain right on the map, where the gadgets have
// already been drawn to, dark pieces overwrite gadgets. This makes the
// gadgets only visible where no piece is at all. Correct: The gadget
// is visible where no piece is at all, and where dark pieces have cut
// a hole into the terrain.
void drawTerrain(Editor editor)
{
    auto zone = Zone(profiler, "Editor.drawTerrain");
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
    with (Zone(profiler, "Editor.drawToScreen"))
    with (DrawingTarget(display.al_get_backbuffer))
{
    with (_level)
        al_clear_to_color(color.makecol(bgRed, bgGreen, bgBlue));
    _map.drawCamera();
    import graphic.textout;
    import basics.user;
    drawText(djvuM, "To exit the editor, press "
        ~ keyEditorExit.hotkeyNiceBrackets ~ ".", 10, 10, color.white);
}}
