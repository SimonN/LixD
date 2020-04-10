module editor.draw;

import std.algorithm;
import std.conv;
import std.string;

import basics.alleg5;
import basics.help;
import editor.editor;
import editor.hover;
import file.language;
import graphic.color;
import graphic.cutbit;
import gui.context; // draw text to screen
import graphic.torbit;
import hardware.display;
import hardware.tharsis;
import tile.draw;
import tile.gadtile;
import tile.occur;

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

// This must be mixin template to be easily accessible from callers, it
// can't be a standalone private function. Reason: _editor is not global.
// Can't take _editor as an argument because function must be argument to
// std.algorithm.filter.
mixin template nATT() {
    bool notAboutToTrash(Occurrence o)
    {
        return ! editor.aboutToTrash
            || ! editor._selection.any!(hover => hover.occ is o);
    }
}

void drawTerrainToSeparateMap(Editor editor) {
    with (editor)
{
    mixin nATT;
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawMapTerrain");
    with (TargetTorbit(_mapTerrain)) {
        _mapTerrain.clearToColor(color.transp);
        _level.terrain.filter!notAboutToTrash.each!drawOccurrence;
    }
}}

void drawMainMap(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawMapMain");
    with (TargetTorbit(editor._map))
    with (editor)
    with (editor._level) {
        editor._map.clearSourceThatWouldBeBlitToTarget(
            color.makecol(bgRed, bgGreen, bgBlue));
        editor.drawGadgets();
        editor._map.loadCameraRect(_mapTerrain);
        editor.drawGadgetAnnotations();
        editor.drawGadgetTriggerAreas();
        editor.drawHovers(_hover, false);
        editor.drawHovers(_selection, true);
        editor.drawDraggedFrame();
    }
}

void drawGadgets(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawGadgets");
    mixin nATT;
    foreach (gadgetList; editor._level.gadgets)
        gadgetList.filter!notAboutToTrash.each!(g => g.tile.cb.draw(g.loc));
}

void drawGadgetTriggerAreas(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.annotateGadgets");
    foreach (gadgetList; editor._level.gadgets)
        foreach (g; gadgetList)
            editor._map.drawRectangle(g.triggerAreaOnMap, color.triggerArea);
}

void drawGadgetAnnotations(Editor editor) {
    with (editor._level)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawGadgetAnnotations");
    void annotate(const(typeof(gadgets[0])) list)
    {
        void print(const(typeof(gadgets[0][0])) g, in int plusY, in string str)
        {
            forceUnscaledGUIDrawing = true;
            editor._map.useDrawingDelegate((int x, int y) {
                drawTextCentered(djvuL, str,
                x + g.tile.cb.xl/2, y + plusY, color.guiText); }, g.loc);
            forceUnscaledGUIDrawing = false;
        }

        foreach (const size_t i, g; list)  {
            assert (g.tile && g.tile.cb);
            assert (intendedNumberOfPlayers >= 1);
            // DTODOREFACTOR:
            // All this sounds like we need better OO for gadget types.
            // Should gadgets know their team IDs? They do in the instantiatons
            // after loading the level in the game, but the GadOccs do not.
            // Who's our authority that assign gadgets <-> teams?
            // I duplicate logic here that's also in the Game's state init.
            enum int plusY = 15;
            int y = -plusY;
            immutable int team = teamIDforGadget(i.to!int);
            immutable int weGetTotal = howManyDoesTeamGetOutOf(team, list.len);

            if (intendedNumberOfPlayers > 1)
                print(g, y += plusY, "ABCDEFGH"[team .. team + 1]);
            if (intendedNumberOfPlayers == 1
                || (g.tile.type == GadType.HATCH && weGetTotal > 1))
                print(g, y += plusY, "%d/%d".format(
                    ((i - team) / intendedNumberOfPlayers) + 1, weGetTotal));
            if (g.tile.type == GadType.HATCH)
                // unicode: LEFTWARDS ARROW, RIGHTWARDS ARROW
                print(g, y += plusY, g.hatchRot ? "\u2190" : "\u2192");
        }
    }
    annotate(gadgets[GadType.HATCH]);
    if (intendedNumberOfPlayers > 1)
        annotate(gadgets[GadType.GOAL]);
}}

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
        editor._map.drawRectangle(ho.occ.selboxOnMap, ho.hoverColor(val));
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

void drawToScreen(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawToScreen");
    with (TargetBitmap(theA5display.al_get_backbuffer))
        editor._map.drawCamera();
}
