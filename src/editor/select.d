module editor.select;

// creating the Hover objects for what's under the mouse cursor

import std.algorithm;
import std.range;

import basics.rect;
import basics.user; // keyPriorityInvert
import editor.editor;
import editor.hover;
import hardware.keyboard;
import hardware.mouse;
import tile.occur;
import tile.gadtile;

package:

void hoverTiles(Editor editor) { with (editor)
{
    _hover = [];
    if (_dragger.framing)
        editor.hoverTilesInRect(_dragger.frame(_map));
    else if (_panel.isMouseHere)
        { }
    else if (! keyPriorityInvert.keyHeld)
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
        else if (_selection.canFind(_hover[0])) {
            if (_panel.buttonSelectAdd.on)
                _selection = _selection.filter!(ho => ho != _hover[0]).array;
            else
                _dragger.startMove(_map, _hover[0]);
        }
        else {
            assert (_hover.length == 1);
            selectHover();
            _dragger.startMove(_map, _hover[0]);
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
    immutable reason = Hover.Reason.selectAll;
    _selection = _level.pos[].joiner
        .map!(pos => cast (Hover) new GadgetHover(_level, pos, reason)).array
        ~ _level.terrain
        .map!(pos => cast (Hover) new TerrainHover(_level, pos, reason)).array;
}}

private:

void hoverTilesInRect(Editor editor, Rect rect) { with (editor)
{
    immutable reason = Hover.Reason.frameSpanning;
    _hover = _level.pos[].joiner
        .filter!(pos => _map.rectIntersectsRect(rect, pos.selboxOnMap))
        .map!(pos => cast (Hover) new GadgetHover(_level, pos, reason)).array
        ~ _level.terrain
        .filter!(pos => _map.rectIntersectsRect(rect, pos.selboxOnMap))
        .map!(pos => cast (Hover) new TerrainHover(_level, pos, reason)).array;
}}

void hoverTilesNormally(Editor editor) { with (editor)
{
    // The tiles at the end of each list are in the foreground.
    // Later tiles will throw out earlier tiles in the hover, unless the
    // earlier tiles have a strictly better reason than the later tiles.
    _level.pos[].joiner.each!(pos => editor.maybeAdd(pos));
    _level.terrain     .each!(pos => editor.maybeAdd(pos));
}}

void hoverTilesReversed(Editor editor) { with (editor)
{
    _level.terrain.retro     .each!(pos => editor.maybeAdd(pos));
    _level.pos[].retro.joiner.each!(pos => editor.maybeAdd(pos));
}}

void maybeAdd(Pos)(
    Editor editor,
    Pos pos
)   if (is (Pos : Occurrence) && ! is (Pos == Occurrence))
{   with (editor)
{
    if (! _map.isPointInRectangle(_map.mouseOnLand, pos.selboxOnMap))
        return;
    static if (is (Pos == TerOcc))
        immutable Hover.Reason reason = editor.mouseOnSolidPixel(pos)
            ? Hover.Reason.mouseOnSolidPixel
            : Hover.Reason.mouseInSelbox;
    else
        // this is a hack, to get the strongest possible reason,
        // even though all we know is mouse inside selbox.
        enum Hover.Reason reason = Hover.Reason.mouseOnSolidPixel;
    if (editor._hover == null || reason >= editor._hover[0].reason) {
        static if (is (Pos == TerOcc))
            _hover = [ new TerrainHover(editor._level, pos, reason) ];
        else
            _hover = [ new GadgetHover( editor._level, pos, reason) ];
    }
}}

// Call this function only when you know that the mouse is on pos's selbox.
// The asserts in this function after fixing mol makes that sure.
bool mouseOnSolidPixel(Editor editor, in TerOcc pos) {
    with (editor)
{
    auto mol = _map.mouseOnLand;
    if (pos.selboxOnMap.x < 0) mol.x -= _map.xl;
    if (pos.selboxOnMap.y < 0) mol.y -= _map.yl;
    while (mol.x < pos.selboxOnMap.x) mol.x += _map.xl;
    while (mol.y < pos.selboxOnMap.y) mol.y += _map.yl;
    version (assert) {
        string str()
        {
            import std.string;
            return "%s not in selbox %s, because "
                   "selbox's start+length: %s. Mouse on land: %s"
                .format(mol.toString, pos.selboxOnMap,
                    (pos.selboxOnMap.topLeft + pos.selboxOnMap.len).toString,
                    _map.mouseOnLand.toString);
        }
        assert (mol.x >= pos.selboxOnMap.x, str());
        assert (mol.y >= pos.selboxOnMap.y, str());
        assert (mol.x <  pos.selboxOnMap.x + pos.selboxOnMap.xl, str());
        assert (mol.y <  pos.selboxOnMap.y + pos.selboxOnMap.yl, str());
    }
    return 0 != pos.phybitsOnMap(mol);
}}
