module editor.tiles;

// Moving and manipulating tile instances (TerPos, GadPos).

import std.array;
import std.algorithm;

import editor.editor;
import tile.pos;
import tile.gadtile;

package:

void hoverTiles(Editor editor)
{
    editor._hoverTerrain = [];
    foreach (int i, pos; editor._level.terrain)
        editor.maybeAdd(editor._hoverTerrain, i, pos);

    foreach (GadType type, list; editor._level.pos) {
        editor._hoverGadgets[type] = [];
        foreach (int i, pos; list)
            editor.maybeAdd(editor._hoverGadgets[type], i, pos);
    }
}

void maybeAdd(Pos)(Editor editor, ref Hover[] hovers, in int arrayID, Pos pos)
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
        hovers = [ Hover(arrayID, reason) ];
}

bool mouseOnSolidPixel(Editor editor, TerPos pos) { with (editor._map)
{
    int x = mouseOnLandX;
    int y = mouseOnLandY;
    while (x < pos.x)
        x += xl;
    while (y < pos.y)
        y += yl;
    return 0 != pos.phybitsAtMapPosition(x, y);
}}
