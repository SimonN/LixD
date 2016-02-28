module editor.select;

// creating the Hover objects for what's under the mouse cursor

import std.algorithm;
import std.range;
import std.conv;

import editor.editor;
import editor.hover;
import hardware.semantic;
import hardware.mouse;
import tile.pos;
import tile.gadtile;

package:

void hoverTiles(Editor editor)
{
    editor._hover = [];
    if (! priorityInvertHeld)
        editor.hoverTilesNormally();
    else
        editor.hoverTilesReversed();
}

void selectTiles(Editor editor) { with (editor)
{
    if (mouseClickLeft && ! _panel.isMouseHere) {
        _selection = _hover;
    }
}}

private:

void hoverTilesNormally(Editor editor) { with (editor)
{
    // The tiles at the end of each list are in the foreground.
    // Later tiles will throw out earlier tiles in the hover, unless the
    // earlier tiles have a strictly better reason than the later tiles.
    foreach (GadType type, ref list; _level.pos)
        foreach (i, pos; list)
            editor.maybeAdd(&list, i, pos);
    foreach (i, pos; _level.terrain)
        editor.maybeAdd(&_level.terrain, i, pos);
}}

void hoverTilesReversed(Editor editor) { with (editor)
{
    foreach (i, pos; _level.terrain.retro.enumerate)
        editor.maybeAdd(&_level.terrain, _level.terrain.length - i - 1, pos);
    foreach (GadType type, ref list; _level.pos)
        foreach (i, pos; list.retro.enumerate)
            editor.maybeAdd(&list, list.length - i - 1, pos);
}}

void maybeAdd(Pos)(
    Editor editor,
    Pos[]* list,
    in size_t arrayID,
    Pos pos
)   if (is (Pos : AbstractPos))
{   with (editor)
    with (editor._map)
{
    if (! isPointInRectangle(mouseOnLandX, mouseOnLandY, pos.selbox))
        return;
    static if (is (Pos == TerPos))
        immutable Hover.Reason reason = editor.mouseOnSolidPixel(pos)
            ? Hover.Reason.mouseOnSolidPixel
            : Hover.Reason.mouseInSelbox;
    else
        // this is a hack, to get the strongest possible reason,
        // even though all we know is mouse inside selbox.
        enum Hover.Reason reason = Hover.Reason.mouseOnSolidPixel;
    if (editor._hover == null || reason >= editor._hover[0].reason) {
        static if (is (Pos == TerPos))
            _hover = [ new TerrainHover(editor._level, pos, reason) ];
        else
            _hover = [ new GadgetHover( editor._level, pos, reason) ];
    }
}}

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
