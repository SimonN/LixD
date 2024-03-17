module editor.draw;

import std.algorithm;
import std.conv;
import std.string;

import basics.alleg5;
import basics.help;
import editor.drawcol;
import editor.editor;
import file.language;
import graphic.color;
import graphic.cutbit;
import gui.context; // draw text to screen
import graphic.torbit;
import hardware.display;
import hardware.tharsis;
import level.oil;
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
    if (editor.level.topology.matches(editor._map.torbit)) {
        return;
    }
    with (editor.level.topology) {
        editor._map       .resize(xl, yl);
        editor._mapTerrain.resize(xl, yl);
        editor._map       .setTorusXY(torusX, torusY);
        editor._mapTerrain.setTorusXY(torusX, torusY);
    }
    editor._map.zoomOutToSeeEntireMap();
}

// This must be mixin template to be easily accessible from callers, it
// can't be a standalone private function. Reason: _editor is not global.
// Can't take _editor as an argument because function must be argument to
// std.algorithm.filter.
mixin template nATT() {
    bool notAboutToTrash(in Occurrence o)
    {
        return ! editor.aboutToTrash
            || Oil.makeViaLookup(editor.level, o) !in editor._selection;
    }
}

void drawTerrainToSeparateMap(Editor editor) {
    with (editor)
{
    mixin nATT;
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawMapTerrain");
    with (TargetTorbit(_mapTerrain.torbit)) {
        _mapTerrain.torbit.clearToColor(color.transp);
        level.terrain.filter!notAboutToTrash.each!drawOccurrence;
    }
}}

void drawMainMap(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawMapMain");
    with (TargetTorbit(editor._map.torbit))
    with (editor)
    {
        editor._map.clearSourceThatWouldBeBlitToTarget(level.bgColor);
        editor.drawGadgets();
        editor._map.loadCameraRect(_mapTerrain.torbit);
        editor.drawGadgetAnnotations();
        drawAllTriggerAreas(level.gadgets, _map.torbit);
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
    foreach (gadgetList; editor.level.gadgets)
        gadgetList.filter!notAboutToTrash.each!(g => g.tile.cb.draw(g.loc));
}

void drawGadgetAnnotations(Editor editor) {
    with (editor.level)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawGadgetAnnotations");
    void annotate(const(typeof(gadgets[0])) list)
    {
        void print(const(typeof(gadgets[0][0])) g, in int plusY, in string str)
        {
            forceUnscaledGUIDrawing = true;
            editor._map.torbit.useDrawingDelegate((int x, int y) {
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
            const(int[]) teams = teamIDsForGadget(i.to!int, list.len);
            const int numForUs = howManyDoesTeamGetOutOf(teams[0], list.len);

            if (intendedNumberOfPlayers > 1)
                print(g, y += plusY, teams.map!(
                    function char(int i) { return 'A'+i & 0xFF; }).to!string);
            if (intendedNumberOfPlayers == 1
                || (g.tile.type == GadType.HATCH && numForUs > 1))
                print(g, y += plusY, "%d/%d".format(
                    ((i - teams[0]) / intendedNumberOfPlayers) + 1, numForUs));
            if (g.tile.type == GadType.HATCH)
                // unicode: LEFTWARDS ARROW, RIGHTWARDS ARROW
                print(g, y += plusY, g.hatchRot ? "\u2190" : "\u2192");
        }
    }
    annotate(gadgets[GadType.HATCH]);
    if (intendedNumberOfPlayers > 1)
        annotate(gadgets[GadType.GOAL]);
}}

void drawDraggedFrame(Editor editor)
{
    if (! editor._dragger.framing)
        return;
    immutable val = hoverColorLightness(false);
    assert (val >= 0x40 && val < 0xC0); // because we'll be varying by 0x40
    immutable col = color.makecol(val + 0x40, val, val - 0x40);
    editor._map.torbit.drawRectangle(editor._dragger.frame(editor._map), col);
}

void drawToScreen(Editor editor)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Editor.drawToScreen");
    with (TargetBitmap(theA5display.al_get_backbuffer))
        editor._map.drawCamera();
}
