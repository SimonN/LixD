module editor.select;

// creating the Hover objects for what's under the mouse cursor

import std.algorithm;
import std.range;

import basics.rect;
import file.option; // keyPriorityInvert
import editor.editor;
import editor.mirrtile : removeFromLevelTheSelection; // for dragging on panel
import editor.undoable.base;
import hardware.keyboard;
import hardware.mouse;
import level.oil;
import tile.occur;
import tile.gadtile;
import tile.visitor;

package:

void hoverTiles(Editor editor) { with (editor)
{
    if (_dragger.framing) {
        editor.hoverTilesInRect(_dragger.frame(_map));
        return;
    }
    if (_dragger.moving || _panel.isMouseHere) {
        _hover.clear();
        return;
    }
    auto range = editor.rangeOfAllOilsFromBackgroundToForeground;
    if (keyPriorityInvert.keyHeld) {
        editor.hoverTileAtMouse(range);
        return;
    }
    editor.hoverTileAtMouse(range.retro);
}}

void selectTiles(Editor editor) { with (editor)
{
    void selectHover()
    {
        if (! _panel.buttonSelectAdd.on) {
            _selection.clear;
        }
        foreach (hovered; _hover[]) {
            _selection.insert(hovered);
        }
        _panel.buttonSelectAdd.on = _panel.buttonSelectAdd.hotkey.keyHeld;
    }
    if (mouseClickLeft && ! _panel.isMouseHere) {
        if (_hover.empty || _panel.buttonFraming.on) {
            _dragger.startFrame(_map);
            _panel.buttonFraming.on = true;
        }
        else if (_selection[].canFind(_hover[].front)) {
            if (_panel.buttonSelectAdd.on)
                _selection.removeKey(_hover[].front);
            else
                _dragger.startMove(_map, _hover[].front);
        }
        else {
            assert (_hover.length == 1);
            selectHover();
            _dragger.startMove(_map, _hover[].front);
        }
    }
    else if (! mouseHeldLeft) {
        if (_dragger.framing) {
            selectHover();
            _panel.buttonFraming.on = _panel.buttonFraming.hotkey.keyHeld;
        }
        else if (aboutToTrash) {
            editor.removeFromLevelTheSelection();
        }
        _dragger.stop();
    }
}}

// This is called from editor.paninit
void selectAll(Editor editor)
{
    editor._selection = rangeOfAllOilsFromBackgroundToForeground(editor)
        .toOilSet;
}

///////////////////////////////////////////////////////////////////////////////
private: ///////////////////////////////////////////////////////////// :private
///////////////////////////////////////////////////////////////////////////////

auto rangeOfAllOilsFromBackgroundToForeground(Editor editor) { with (editor)
{
    auto gadOils = levelRefacme.gadgets[].joiner
        .map!(occ => Oil.makeViaLookup(level, occ));
    auto terOils = level.terrain.enumerate!int
        .map!(tuple => new TerOil(tuple.index));
    return gadOils.chain(terOils);
}}

void hoverTilesInRect(Editor editor, Rect rect) { with (editor)
{
    _hover = editor.rangeOfAllOilsFromBackgroundToForeground
        .filter!(oil => _map.topology.rectIntersectsRect(
            rect, oil.occ(level).selboxOnMap))
        .toOilSet;
}}

/*
 * Makes _hover an OilSet with either 0 or 1 elements.
 *
 * If several elements qualify, the elements that are encountered earlier
 * in the range are preferred. Thus, for normal hovering without priority
 * invert, pass a range that gives the end of the terrain list first, i.e.,
 * the tiles that will be drawn last, on top of all others.
 */
void hoverTileAtMouse(OilRan)(Editor editor, OilRan range) { with (editor)
{
    _hover.clear();
    auto inSelbox = range
        .filter!(oil => _map.torbit.isPointInRectangle(
        _map.mouseOnLand, oil.occ(level).selboxOnMap));
    if (inSelbox.empty) {
        return;
    }
    _hover.insert(inSelbox.save
        .filter!(oil => editor.isMouseOnSolidPixel(oil))
        .chain(inSelbox) // if the filter was empty, at least this is nonempty
        .front);
}}

/*
 * Call this function only when you know that the mouse is on pos's selbox.
 * For the reason, see comment at function mouseOnSolidPixel(TerOcc).
 */
bool isMouseOnSolidPixel(Editor editor, in Oil oil) { with (editor)
{
    const(TerOcc) occ = cast (const(TerOcc)) oil.occ(level);
    if (occ is null) {
        return true; // It's a gadget, it should remain easily selectable.
    }
    return editor.isMouseOnSolidPixel(occ);
}}

// Call this function only when you know that the mouse is on pos's selbox.
// The asserts in this function after fixing mol makes that sure.
bool isMouseOnSolidPixel(Editor editor, in TerOcc pos) { with (editor)
{
    auto mol = _map.mouseOnLand;
    immutable tile = pos.selboxOnMap;

    while (mol.x >= tile.x + tile.xl) mol.x -= _map.topology.xl;
    while (mol.y >= tile.y + tile.yl) mol.y -= _map.topology.yl;
    while (mol.x < tile.x) mol.x += _map.topology.xl;
    while (mol.y < tile.y) mol.y += _map.topology.yl;
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
