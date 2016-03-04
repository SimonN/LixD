module editor.select;

// creating the Hover objects for what's under the mouse cursor

import std.algorithm;
import std.range;
import std.conv;

import basics.topology; // Rect
import editor.editor;
import editor.hover;
import hardware.semantic;
import hardware.mouse;
import tile.pos;
import tile.gadtile;

package:

void hoverTiles(Editor editor) { with (editor)
{
    _hover = [];
    if (_dragger.framing)
        editor.hoverTilesInRect(_dragger.frame(_map));
    else if (! priorityInvertHeld)
        editor.hoverTilesNormally();
    else
        editor.hoverTilesReversed();
}}

void selectTiles(Editor editor) { with (editor)
{
    if (mouseClickLeft && ! _panel.isMouseHere) {
        _selection = _hover;
        if (_selection.empty)
            _dragger.startFrame(_map);
        else
            _dragger.startMove(_map);
    }
    else if (! mouseHeldLeft) {
        if (_dragger.framing)
            _selection = _hover;
        _dragger.stop();
    }
}}

private:

void hoverTilesInRect(Editor editor, Rect rect) { with (editor)
{
    foreach (GadType type, ref list; _level.pos)
        foreach (pos; list)
            if (_map.rectIntersectsRect(rect, pos.selbox))
                _hover ~= new GadgetHover(_level, pos, Hover.Reason.none);
    foreach (pos; _level.terrain)
        if (_map.rectIntersectsRect(rect, pos.selbox))
            _hover ~= new TerrainHover(_level, pos, Hover.Reason.none);
}}

void hoverTilesNormally(Editor editor) { with (editor)
{
    // The tiles at the end of each list are in the foreground.
    // Later tiles will throw out earlier tiles in the hover, unless the
    // earlier tiles have a strictly better reason than the later tiles.
    foreach (GadType type, ref list; _level.pos)
        foreach (pos; list)
            editor.maybeAdd(&list, pos);
    foreach (i, pos; _level.terrain)
        editor.maybeAdd(&_level.terrain, pos);
}}

void hoverTilesReversed(Editor editor) { with (editor)
{
    foreach (pos; _level.terrain.retro)
        editor.maybeAdd(&_level.terrain, pos);
    foreach (GadType type, ref list; _level.pos)
        foreach (pos; list.retro)
            editor.maybeAdd(&list, pos);
}}

void maybeAdd(Pos)(
    Editor editor,
    Pos[]* list,
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
