module editor.hover;

// Moving and manipulating tile instances (TerPos, GadPos).

import std.algorithm;
import std.range;
import std.conv;

import editor.editor;
import hardware.semantic;
import tile.pos;
import tile.gadtile;

package:

void hoverTiles(Editor editor)
{
    editor._hoverTerrain = [];
    foreach (GadType type, unused; editor._level.pos)
        editor._hoverGadgets[type] = [];
    if (! priorityInvertHeld)
        editor.hoverTilesNormally();
    else
        editor.hoverTilesReversed();
}

private:

void hoverTilesNormally(Editor editor) { with (editor)
{
    foreach (i, pos; _level.terrain)
        editor.maybeAdd(_hoverTerrain, i, pos);
    if (_hoverTerrain != null)
        return;

    foreach (GadType type, ref list; _level.pos)
        foreach (i, const pos; list) {
            editor.maybeAdd(_hoverGadgets[type], i, pos);
            if (_hoverGadgets[type] != null)
                return;
        }
}}

void hoverTilesReversed(Editor editor) { with (editor)
{
    foreach (GadType type, ref list; _level.pos)
        foreach (i, const pos; list.retro.enumerate) {
            editor.maybeAdd(_hoverGadgets[type], list.length - i - 1, pos);
            if (_hoverGadgets[type] != null)
                return;
        }
    foreach (i, pos; _level.terrain.retro.enumerate)
        editor.maybeAdd(_hoverTerrain, _level.terrain.length - i - 1, pos);
}}

void maybeAdd(Pos)(
    Editor editor,
    ref Hover[] hovers,
    in size_t arrayID,
    in Pos pos)
    if (is (Pos : AbstractPos))
{
    with (editor._map)
        if (! isPointInRectangle(mouseOnLandX, mouseOnLandY, pos.selbox))
            return;
    static if (is (Pos == TerPos))
        immutable Hover.Reason reason = editor.mouseOnSolidPixel(pos)
            ? Hover.Reason.mouseOnSolidPixel
            : Hover.Reason.mouseInSelbox;
    else
        enum Hover.Reason reason = Hover.Reason.mouseInSelbox;
    if (hovers == null || reason >= hovers[0].reason)
        hovers = [ Hover(arrayID.to!int, reason) ];
}

bool mouseOnSolidPixel(Editor editor, in TerPos pos) { with (editor._map)
{
    int x = mouseOnLandX;
    int y = mouseOnLandY;
    while (x < pos.x)
        x += xl;
    while (y < pos.y)
        y += yl;
    return 0 != pos.phybitsAtMapPosition(x, y);
}}
