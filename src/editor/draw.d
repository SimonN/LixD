module editor.draw;

import std.algorithm;
import std.string;

import basics.alleg5;
import editor.editor;
import editor.hover;
import graphic.color;
import graphic.cutbit;
import graphic.textout;
import hardware.display;
import hardware.tharsis;
import tile.gadtile;

package:

void implEditorDraw(Editor editor)
{
    auto zone = Zone(profiler, "Editor.implEditorDraw");
    editor.drawTerrainToSeparateMap();
    editor.drawMainMap();
    editor.drawToScreen();
}

private:

void drawTerrainToSeparateMap(Editor editor) {
    with (Zone(profiler, "Editor.drawMapTerrain"))
    with (DrawingTarget(editor._mapTerrain.albit))
{
    editor._mapTerrain.clearToColor(color.transp);
    foreach (t; editor._level.terrain)
        if (auto cb = t.dark ? t.ob.dark : t.ob.cb)
            cb.draw(editor._mapTerrain, t.x, t.y, t.mirr, t.rot,
                    t.dark ? Cutbit.Mode.DARK_EDITOR : Cutbit.Mode.NORMAL);
}}

void drawMainMap(Editor editor) {
    with (Zone(profiler, "Editor.drawMapMain"))
    with (DrawingTarget(editor._map.albit))
    with (editor)
    with (editor._level)
{
    editor._map.clearScreenRect(color.makecol(bgRed, bgGreen, bgBlue));
    editor.drawGadgets();
    editor._map.loadCameraRect(editor._mapTerrain);
    editor.drawGadgetAnnotations();
    editor.drawHovers(_hover, false);
    editor.drawHovers(_selection, true);
}}

void drawGadgets(Editor editor)
{
    auto zone = Zone(profiler, "Editor.drawGadgets");
    foreach (gadgetList; editor._level.pos)
        foreach (g; gadgetList) {
            assert (g.ob && g.ob.cb);
            g.ob.cb.draw(editor._map, g.x, g.y);
        }
}

void drawGadgetAnnotations(Editor editor)
{
    auto zone = Zone(profiler, "Editor.drawGadgetAnnotations");
    void annotate(const(typeof(editor._level.pos[0])) list)
    {
        foreach (int i, g; list) {
            assert (g.ob && g.ob.cb);
            string s = "%d/%d".format(i+1, list.length);
            drawTextCentered(djvuM, s, g.x + g.ob.cb.xl/2, g.y, color.guiText);
        }
    }
    annotate(editor._level.pos[GadType.HATCH]);
    annotate(editor._level.pos[GadType.GOAL]);
}

void drawHovers(Editor editor, const(Hover[]) list, in bool light)
{
    immutable int time  = timerTicks & 0x0F;
    immutable int subtr = time < 0x08 ? time : 0x10 - time;
    immutable int val   = (light ? 0xFF : 0xA0) - (light ? 5 : 10) * subtr;
    foreach (ho; list)
        editor._map.drawRectangle(ho.pos.selbox, ho.hoverColor(val));
}

void drawToScreen(Editor editor) {
    with (editor)
    with (Zone(profiler, "Editor.drawToScreen"))
    with (DrawingTarget(display.al_get_backbuffer))
{
    _map.drawCamera();
}}
