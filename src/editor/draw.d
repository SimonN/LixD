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
    editor.drawTerrainToSeparateMap();
    editor.drawMainMap();
    editor.drawToScreen();
}

private:

void drawTerrainToSeparateMap(Editor editor) {
    with (Zone(profiler, "Editor.drawMapTerrain"))
    with (DrawingTarget(editor._mapTerrain.albit))
{
    editor._mapTerrain.clearScreenRect(color.transp);
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
    editor.drawHover(_hoverTerrain,  _hoverGadgets,  false);
    editor.drawHover(_selectTerrain, _selectGadgets, true);
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

void drawHover(Editor editor,
    const(Hover[]) hovTer,
    typeof(Editor._hoverGadgets) hovGad,
    in bool light
) { with (editor._level)
    with (editor._map)
{
    immutable colTer = hoverColor(0, light);
    immutable colGad = hoverColor(1, light);
    foreach (GadType type, list; hovGad)
        list.each!(a => drawRectangle(pos[type][a.arrayID].selbox, colGad));
    hovTer  .each!(a => drawRectangle(terrain  [a.arrayID].selbox, colTer));
}}

AlCol hoverColor(in int hue, in bool light)
{
    immutable int time  = timerTicks & 0x0F;
    immutable int subtr = time < 0x08 ? time : 0x10 - time;
    immutable int val   = (light ? 0xFF : 0xA0) - (light ? 5 : 10) * subtr;
    if (hue == 0)
        return color.makecol(val, val, val);
    else
        return color.makecol(val, val, val/2);
}

void drawToScreen(Editor editor) {
    with (editor)
    with (Zone(profiler, "Editor.drawToScreen"))
    with (DrawingTarget(display.al_get_backbuffer))
{
    _map.drawCamera();
}}
