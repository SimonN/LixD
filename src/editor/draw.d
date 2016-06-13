module editor.draw;

import std.algorithm;
import std.string;

import basics.alleg5;
import basics.help;
import editor.editor;
import editor.hover;
import file.language;
import graphic.color;
import graphic.cutbit;
import graphic.textout;
import hardware.display;
import hardware.tharsis;
import tile.draw;
import tile.gadtile;

package:

void implEditorDraw(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.implEditorDraw");
    editor.updateTopologies();
    editor.drawTerrainToSeparateMap();
    editor.drawMainMap();
    editor.drawToScreen();
}

private:

void updateTopologies(Editor editor)
{
    with (editor._level.topology) {
        editor._map       .resize(xl, yl);
        editor._mapTerrain.resize(xl, yl);
        editor._map       .setTorusXY(torusX, torusY);
        editor._mapTerrain.setTorusXY(torusX, torusY);
    }
}

void drawTerrainToSeparateMap(Editor editor) {
    with (editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawMapTerrain");
    with (DrawingTarget(_mapTerrain.albit)) {
        _mapTerrain.clearToColor(color.transp);
        _level.terrain.each!(occ => occ.drawOccurrence(editor._mapTerrain));
    }
}}

void drawMainMap(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawMapMain");
    with (DrawingTarget(editor._map.albit))
    with (editor)
    with (editor._level) {
        editor._map.clearScreenRect(color.makecol(bgRed, bgGreen, bgBlue));
        editor.drawGadgets();
        editor._map.loadCameraRect(_mapTerrain);
        editor.drawGadgetAnnotations();
        editor.drawHovers(_hover, false);
        editor.drawHovers(_selection, true);
        editor.drawDraggedFrame();
        editor._panel.info = editor.describeHover();
    }
}

void drawGadgets(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawGadgets");
    foreach (gadgetList; editor._level.pos)
        foreach (g; gadgetList) {
            assert (g.tile && g.tile.cb);
            g.tile.cb.draw(editor._map, g.point);
        }
}

void drawGadgetAnnotations(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawGadgetAnnotations");
    void annotate(const(typeof(editor._level.pos[0])) list)
    {
        foreach (int i, g; list) {
            assert (g.tile && g.tile.cb);
            drawTextCentered(djvuS, "%d/%d".format(i+1, list.length),
                g.point.x + g.tile.cb.xl/2, g.point.y, color.guiText);
            if (g.tile.type == GadType.HATCH)
                // unicode: LEFTWARDS ARROW, RIGHTWARDS ARROW
                drawTextCentered(djvuM, g.hatchRot ? "\u2190" : "\u2192",
                    g.point.x + g.tile.cb.xl/2, g.point.y + 5, color.guiText);
        }
    }
    annotate(editor._level.pos[GadType.HATCH]);
    annotate(editor._level.pos[GadType.GOAL]);
}

// Returns value in 0 .. 256
int hoverColorVal(bool light)
{
    immutable int time  = timerTicks & 0x3F;
    immutable int subtr = time < 0x20 ? time : 0x40 - time;
    return (light ? 0xFF : 0xB0) - 2 * subtr;
}

void drawHovers(Editor editor, const(Hover[]) list, in bool light)
{
    immutable val = hoverColorVal(light);
    foreach (ho; list)
        editor._map.drawRectangle(ho.pos.selboxOnMap, ho.hoverColor(val));
}

void drawDraggedFrame(Editor editor) { with (editor)
{
    if (! _dragger.framing)
        return;
    immutable val = hoverColorVal(false);
    assert (val >= 0x40 && val < 0xC0); // because we'll be varying by 0x40
    immutable col = color.makecol(val + 0x40, val, val - 0x40);
    _map.drawRectangle(_dragger.frame(_map), col);
}}

string describeHover(Editor editor) { with (editor)
{
    if (_hover.length == 1)
        return _hover[0].description;
    else if (_hover.length > 1)
        return "%d %s".format(_hover.len, Lang.editorBarHover.transl);
    else if (_selection.length == 1)
        return _selection[0].description;
    else if (_selection.length > 1)
        return "%d %s".format(_selection.len, Lang.editorBarSelection.transl);
    return "";
}}

void drawToScreen(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawToScreen");
    with (DrawingTarget(display.al_get_backbuffer))
        editor._map.drawCamera();
}
