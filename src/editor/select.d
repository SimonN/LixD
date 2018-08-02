module editor.select;

// creating the Hover objects for what's under the mouse cursor

import std.algorithm;
import std.range;

import basics.rect;
import file.option; // keyPriorityInvert
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
    else if (_dragger.moving || _panel.isMouseHere)
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
        else if (aboutToTrash) {
            editor._selection.each!(s => s.removeFromLevel());
            editor._selection = null;
        }
        _dragger.stop();
    }
}}

// This is called from editor.paninit
void selectAll(Editor editor) { with (editor)
{
    immutable reason = Hover.Reason.selectAll;
    _selection = _level.gadgets[].joiner
        .map!(occ => cast (Hover) new GadgetHover(_level, occ, reason)).array
        ~ _level.terrain
        .map!(occ => TerrainHover.newViaEvilDynamicCast(_level, occ))
        .map!(ho => cast (Hover) ho)
        .tee!(ho => ho.reason = reason).array;
}}

private:

// copy-pasta from void selectAll()
void hoverTilesInRect(Editor editor, Rect rect) { with (editor)
{
    immutable reason = Hover.Reason.frameSpanning;
    _hover = _level.gadgets[].joiner
        .filter!(occ => _map.rectIntersectsRect(rect, occ.selboxOnMap))
        .map!(occ => cast (Hover) new GadgetHover(_level, occ, reason)).array
        ~ _level.terrain
        .filter!(occ => _map.rectIntersectsRect(rect, occ.selboxOnMap))
        .map!(occ => TerrainHover.newViaEvilDynamicCast(_level, occ))
        .map!(ho => cast (Hover) ho)
        .map!((ho) { ho.reason = reason; return ho; }).array;
    assert (_hover.all!(ho => ho.reason == reason));
}}

void hoverTilesNormally(Editor editor) { with (editor)
{
    // The tiles at the end of each list are in the foreground.
    // Later tiles will throw out earlier tiles in the hover, unless the
    // earlier tiles have a strictly better reason than the later tiles.
    _level.gadgets[].joiner.each!(occ => editor.maybeAdd(occ));
    _level.terrain.each!(occ => editor.maybeAdd(occ));
}}

void hoverTilesReversed(Editor editor) { with (editor)
{
    _level.terrain.retro.each!(occ => editor.maybeAdd(occ));
    _level.gadgets[].retro.joiner.each!(occ => editor.maybeAdd(occ));
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
        static if (is (Pos == TerOcc)) {
            auto ho = TerrainHover.newViaEvilDynamicCast(editor._level, pos);
            ho.reason = reason;
            _hover = [ ho ];
        }
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
    immutable tile = pos.selboxOnMap;

    while (mol.x >= tile.x + tile.xl) mol.x -= _map.xl;
    while (mol.y >= tile.y + tile.yl) mol.y -= _map.yl;
    while (mol.x < tile.x) mol.x += _map.xl;
    while (mol.y < tile.y) mol.y += _map.yl;
    version (assert) {
        string str()
        {
            import std.string;
            return format("%s not in selbox %s, because "
                        ~ "selbox's start+length: %s. Mouse on land: %s",
                mol.toString, pos.selboxOnMap,
                (pos.selboxOnMap.topLeft + pos.selboxOnMap.len).toString,
                _map.mouseOnLand.toString);
        }
        assert (mol.x >= tile.x, str());
        assert (mol.y >= tile.y, str());
        assert (mol.x <  tile.x + tile.xl, str());
        assert (mol.y <  tile.y + tile.yl, str());
    }
    return 0 != pos.phybitsOnMap(mol);
}}
