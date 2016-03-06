module editor.select;

// creating the Hover objects for what's under the mouse cursor

import std.algorithm;
import std.range;
import std.conv;

import basics.rect;
import editor.editor;
import editor.hover;
import hardware.keyboard;
import hardware.mouse;
import hardware.semantic;
import tile.pos;
import tile.gadtile;

package:

void hoverTiles(Editor editor) { with (editor)
{
    _hover = [];
    if (_dragger.framing)
        editor.hoverTilesInRect(_dragger.frame(_map));
    else if (_panel.isMouseHere)
        { }
    else if (! priorityInvertHeld)
        editor.hoverTilesNormally();
    else
        editor.hoverTilesReversed();
}}

void selectTiles(Editor editor) { with (editor)
{
    void selectHover()
    {
        _selection = ! _panel.buttonSelectAdd.on
            ? _hover
            : (_selection ~ _hover).sort().uniq.array;
        _panel.buttonSelectAdd.on = _panel.buttonSelectAdd.hotkey.keyHeld;
    }
    if (mouseClickLeft && ! _panel.isMouseHere) {
        if (_hover.empty || _panel.buttonFraming.on) {
            _dragger.startFrame(_map);
            _panel.buttonFraming.on = true;
        }
        else if (_selection.find!"a == b"(_hover[0]) != []) {
            _selection = _selection.filter!(ho => ho != _hover[0]).array;
        }
        else {
            selectHover();
            _dragger.startMove(_map);
        }
    }
    else if (! mouseHeldLeft) {
        if (_dragger.framing) {
            selectHover();
            _panel.buttonFraming.on = _panel.buttonFraming.hotkey.keyHeld;
        }
        _dragger.stop();
    }
}}

// This is called from editor.paninit
void selectAll(Editor editor) { with (editor)
{
    _selection = [];
    foreach (GadType type, ref list; _level.pos)
        foreach (pos; list)
            _selection ~= new GadgetHover(_level, pos);
    foreach (pos; _level.terrain)
        _selection ~= new TerrainHover(_level, pos);
}}

private:

void hoverTilesInRect(Editor editor, Rect rect) { with (editor)
{
    foreach (GadType type, ref list; _level.pos)
        foreach (pos; list)
            if (_map.rectIntersectsRect(rect, pos.selbox))
                _hover ~= new GadgetHover(_level, pos);
    foreach (pos; _level.terrain)
        if (_map.rectIntersectsRect(rect, pos.selbox))
            _hover ~= new TerrainHover(_level, pos);
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
    if (! isPointInRectangle(mouseOnLand, pos.selbox))
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
    auto mol = mouseOnLand;
    while (mol.x < pos.x)
        mol.x += xl;
    while (mol.y < pos.y)
        mol.y += yl;
    return 0 != pos.phybitsOnMap(mol);
}}
