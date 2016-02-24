module editor.tiles;

// Moving and manipulating tile instances (TerPos, GadPos).

import std.algorithm;

import editor.editor;
import tile.pos;
import tile.gadtile;

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

void maybeAdd(Pos)(Editor editor, ref int[] hover, int i, Pos pos)
    if (is (Pos : AbstractPos))
{
    with (editor._map)
        if (! isPointInRectangle(mouseOnLandX, mouseOnLandY, pos.selbox))
            return;
    static if (is (Pos == TerPos)) {
        if (editor.mouseOnSolidPixel(pos))
            hover ~= i;
    }
    else
        hover ~= i;
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
