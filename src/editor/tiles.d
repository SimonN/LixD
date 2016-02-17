module editor.tiles;

// Moving and manipulating tile instances (TerPos, GadPos).

import std.algorithm;

import editor.editor;
import tile.pos;

void hoverTiles(Editor editor)
{
    editor._hoverTerrain = [];
    editor._hoverGadgets = [];
    foreach (ref pos; editor._level.terrain)
        editor.maybeAdd(editor._hoverTerrain, pos);
    foreach (ref list; editor._level.pos)
        foreach (ref pos; list)
            editor.maybeAdd(editor._hoverGadgets, pos);
}

void maybeAdd(Pos)(Editor editor, ref Pos*[] hover, ref Pos pos)
    if (isSomePos!Pos)
{
    if (editor.isMouseHere(pos))
        hover ~= &pos;
}

bool isMouseHere(T)(in Editor editor, in T pos)
    if (isSomePos!T) {
    with (editor)
    with (pos.ob)
{
    assert (pos.ob);
    return _map.isPointInRectangle(
        _map.mouseOnLandX, _map.mouseOnLandY,
        pos.x + selboxX, pos.y + selboxY, selboxXl, selboxYl);
}}
