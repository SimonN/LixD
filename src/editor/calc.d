module editor.calc;

import std.algorithm;
import std.format;
import std.range;

import optional;

import basics.topology;
import file.option; // hotkeys for movement
import editor.editor;
import editor.hover;
import editor.io;
import editor.select;
import file.language; // select grid
import gui;
import hardware.keyboard;
import hardware.mousecur;

package:

void implEditorWork(Editor editor)
{
    editor.maybeCloseTerrainBrowser();
    editor.maybeCloseOkCancelWindow();
    editor.maybeCloseSaveBrowser();
    if (editor.mainUIisActive) {
        // We handle keypresses independently from the UI focus here,
        // therefore we must hide selectGrid in this if branch
        editor.selectGrid();
    }
    else {
        // This else branch is probably a bad hack.
        // Otherwise, the hover description remains on the info bar even
        // with windows open. When the editor doesn't have focus: bar empty.
        editor._panel.forceClearInfo();
    }
    // Massive hack! Otherwise, the info bar is blit over the save browser.
    // I should find out why.
    editor._panel.shown = editor._saveBrowser is null;
}

void implEditorCalc(Editor editor) {
    with (editor)
{
    assert (_panel);
    _map.calcScrolling();
    if (aboutToTrash)
        mouseCursor.yf = 2; // trashcan
    else if (_map.isHoldScrolling)
        mouseCursor.xf = 3; // scrolling arrows
    if (! _dragger.framing && ! _dragger.moving)
        _panel.calc();
    else
        _panel.calcButDisableMouse();
    editor.handleNonstandardPanelButtons();
    editor.hoverTiles();
    editor.selectTiles();
    editor.moveTiles();
    editor.describeOnStatusBar();
}}

package:

void handleNonstandardPanelButtons(Editor editor) { with (editor)
{
    with (_panel.buttonFraming)
        on = hotkey.keyHeld || _dragger.framing ? true
           : hotkey.keyReleased ? false : on;
    with (_panel.buttonSelectAdd)
        on = hotkey.keyHeld     ? true
           : hotkey.keyReleased ? false : on;
    with (_panel.buttonZoom) {
        if (executeLeft)
            _map.zoomIn();
        if (executeRight)
            _map.zoomOut();
    }
}}

void selectGrid(Editor editor)
{
    int g = editorGridSelected;
    scope (exit)
        editorGridSelected = g;
    g = (g == 1 || g == 2 || g == 16 || g == editorGridCustom.value) ? g : 1;
    assert (editor._panel.button(Lang.editorButtonGrid2));
    if (keyEditorGrid.keyTapped)
        g = () { switch (g) {
            case 16: return 1;
            case  1: return 2;
            case  2: return editorGridCustom;
            default: return 16;
        }}();
    else {
        void check(Button b, in int targetGrid)
        {
            if (b.execute)
                g = (b.on ? 1 : targetGrid);
            b.on = (g == targetGrid);
        }
        with (editor._panel) {
            check(button(Lang.editorButtonGrid2), 2);
            check(button(Lang.editorButtonGridCustom), editorGridCustom);
            check(button(Lang.editorButtonGrid16), 16);
        }
    }
}

void moveTiles(Editor editor) {
    with (editor)
{
    immutable grid = editorGridSelected.value;
    immutable movedByKeyboard
        = Point(-grid, 0) * keyEditorLeft .keyTappedAllowingRepeats
        + Point(+grid, 0) * keyEditorRight.keyTappedAllowingRepeats
        + Point(0, -grid) * keyEditorUp   .keyTappedAllowingRepeats
        + Point(0, +grid) * keyEditorDown .keyTappedAllowingRepeats;
    immutable total = movedByKeyboard
                    + _dragger.snapperShouldMoveBy(_map, grid);
    if (total != Point(0, 0))
        _selection.each!(tile => tile.moveBy(total));
}}

// ############################################################################
private: // ########################################################### private
// ############################################################################

import level.level;
import tile.visitor;
import tile.occur;
import tile.tilelib;

final class AddingVisitor : TileVisitor {
    Level level;
    Occurrence theNew;

    this(Level lev)
    {
        level = lev;
        theNew = null;
    }

    override void visit(const(TerrainTile) te)
    {
        level.terrain ~= new TerOcc(te);
        theNew = level.terrain[$-1];
    }

    override void visit(const(TileGroup) gr)
    {
        visit(cast (const(TerrainTile)) gr);
    }

    override void visit(const(GadgetTile) ga)
    {
        level.gadgets[ga.type] ~= new GadOcc(ga);
        theNew = level.gadgets[ga.type][$-1];
    }
}

void maybeCloseTerrainBrowser(Editor editor) {
    with (editor)
{
    if (! _terrainBrowser || ! _terrainBrowser.done)
        return;
    tile.tilelib.resolveTileName(_terrainBrowser.chosenTile).match!(
        () { },
        (const(AbstractTile) ti)
        {
            assert (ti);
            auto visitor = new AddingVisitor(_level);
            ti.accept(visitor);

            assert (visitor.theNew);
            assert (visitor.theNew.tile is ti);
            assert (ti.cb);
            visitor.theNew.loc = _level.topology.clamp(_map.mouseOnLand)
                - ti.cb.len / 2;
            // Must round the location, not the mouse coordinates for center.
            visitor.theNew.loc = roundWithin(_level.topology,
                Rect(visitor.theNew.loc, ti.cb.len.x, ti.cb.len.y),
                editorGridSelected);
            _selection = [ Hover.newViaEvilDynamicCast(_level, visitor.theNew) ];
            _terrainBrowser.saveDirOfChosenTileToUserCfg();
        });
    rmFocus(_terrainBrowser);
    _terrainBrowser = null;
    _panel.allButtonsOff();
}}

void maybeCloseOkCancelWindow(Editor editor) {
    with (editor)
{
    if (! _okCancelWindow) {
        return;
    }
    if (_okCancelWindow.done) {
        _okCancelWindow.writeChangesTo(_level);
        rmFocus(_okCancelWindow);
        _okCancelWindow = null;
        _panel.allButtonsOff();
    }
    else {
        // This mutates the _level, but later, writeChangesTo can revert that.
        // Then, even when we exited _okCancelWindow by pressing Cancel,
        // the background color for example will revert to before dialog.
        _okCancelWindow.previewChangesOn(_level);
    }
}}

void maybeCloseSaveBrowser(Editor editor) {
    with (editor)
{
    if (! _saveBrowser || ! _saveBrowser.done)
        return;
    if (_saveBrowser.chosenFile) {
        _loadedFrom = _saveBrowser.chosenFile;
        _panel.currentFilename = _loadedFrom;
        editor.saveToExistingFile();
    }
    rmFocus(_saveBrowser);
    _saveBrowser = null;
    _panel.allButtonsOff();
}}

pure Point roundWithin(in Topology topol, in Rect tile, in int grid)
in {
    assert (topol);
}
body {
    Point ret = tile.topLeft.roundTo(grid);
    // This is pedestrian code and I'd rather use a static smaller topology to
    // clamp the point in one line:
    if (topol.torusX) {
        while (ret.x + tile.xl/2 < 0)
            ret.x += grid;
        while (ret.x - tile.xl/2 >= topol.xl)
            ret.x -= grid;
    }
    if (topol.torusY) {
        while (ret.y + tile.yl/2 < 0)
            ret.y += grid;
        while (ret.y - tile.yl/2 >= topol.yl)
            ret.y -= grid;
    }
    return ret;
}

void describeOnStatusBar(Editor editor)
{
    import std.array : join;
    string[2] parts;
    parts[0] = editor.describeMousePosition();
    parts[1] = editor.describeHoveredTiles();
    editor._panel.info = parts[].filter!(s => ! s.empty).join(" ");
}

string describeHoveredTiles(Editor editor) { with (editor)
{
    const(Hover[]) list = _hover.empty ? _selection : _hover;
    if (list.empty)
        return "";
    string name = list.length == 1
        ? list[0].tileDescription
        : "%d %s".format(list.length, list is _hover
            ? Lang.editorBarHover.transl : Lang.editorBarSelection.transl);
    immutable Point p = Point(list.map!(hov => hov.occ.loc.x).reduce!min,
                              list.map!(hov => hov.occ.loc.y).reduce!min);
    return format!"%s %s %s"(name, Lang.editorBarAt.transl, p.toDec);
}}

string describeMousePosition(Editor editor)
{
    if (editor._panel.isMouseHere)
        return "";
    return editor._map.mouseOnLand.toDec;
}

string toDec(in Point p) pure
{
    return format!"(%d, %d)"(p.x, p.y);
}
