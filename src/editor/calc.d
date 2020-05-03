module editor.calc;

import std.algorithm;
import std.format;
import std.range;

import optional;

import basics.help;
import basics.topology;
import file.option; // hotkeys for movement
import editor.editor;
import editor.io;
import editor.movetile;
import editor.select;
import editor.undoable.addrm;
import file.language; // select grid
import gui;
import hardware.keyboard;
import hardware.mousecur;
import level.oil;
import tile.occur;
import tile.visitor;
import tile.tilelib;

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

// ############################################################################
private: // ########################################################### private
// ############################################################################

final class OccMakingVisitor : TileVisitor {
    public Occurrence occ;

    this(const(AbstractTile) tile) { tile.accept(this); }

    void visit(const(TerrainTile) te) { occ = new TerOcc(te); }
    void visit(const(TileGroup)   gr) { occ = new TerOcc(gr); }
    void visit(const(GadgetTile)  ga) { occ = new GadOcc(ga); }
}

Occurrence makeAndPositionOccFor(Editor editor, const(AbstractTile) tile) {
    with (editor)
{
    Occurrence occ = (new OccMakingVisitor(tile)).occ;
    assert (occ);
    assert (occ.tile);
    assert (occ.tile is tile);
    assert (occ.tile.cb);
    occ.loc = level.topology.clamp(_map.mouseOnLand) - tile.cb.len / 2;
    // Must round the location, not the mouse coordinates for center.
    occ.loc = roundWithin(level.topology,
        Rect(occ.loc, tile.cb.len.x, tile.cb.len.y),
        editorGridSelected);
    return occ;
}}

void maybeCloseTerrainBrowser(Editor editor) {
    with (editor)
{
    if (! _terrainBrowser || ! _terrainBrowser.done)
        return;
    tile.tilelib.resolveTileName(_terrainBrowser.chosenTile).each!(
        (const(AbstractTile) ti)
        {
            Occurrence newOcc = editor.makeAndPositionOccFor(ti);
            apply(new TileInsertion(
                Oil.makeAtEndOfList(level, ti), newOcc));
            _terrainBrowser.saveDirOfChosenTileToUserCfg();
        });
    rmFocus(_terrainBrowser);
    _terrainBrowser = null;
    _panel.allButtonsOff();
}}

    import editor.guiapply;
void maybeCloseOkCancelWindow(Editor editor) {
    with (editor)
{
    if (! _okCancelWindow) {
        return;
    }
    if (_okCancelWindow.done) {
        _okCancelWindow.writeChangesTo(levelRefacme);
        rmFocus(_okCancelWindow);
        _okCancelWindow = null;
        _panel.allButtonsOff();
    }
    else {
        // This mutates the level, but later, writeChangesTo can revert that.
        // Then, even when we exited _okCancelWindow by pressing Cancel,
        // the background color for example will revert to before dialog.
        _okCancelWindow.previewChangesOn(levelRefacme);
    }
    maybeApplyTopologyWindowResult(editor);
}}

void maybeCloseSaveBrowser(Editor editor) {
    with (editor)
{
    if (! _saveBrowser || ! _saveBrowser.done)
        return;
    if (_saveBrowser.chosenFile) {
        _panel.currentFilenameOrNull = _saveBrowser.chosenFile;
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
    const(OilSet) list = _hover[].empty ? _selection : _hover;
    if (list[].empty)
        return "";
    string name = list.length == 1
        ? describeSingle(list[].front.occ(level))
        : "%d %s".format(list.length, list is _hover
            ? Lang.editorBarHover.transl : Lang.editorBarSelection.transl);
    immutable Point p = Point(
        list[].map!(oil => oil.occ(level).loc.x).reduce!min,
        list[].map!(oil => oil.occ(level).loc.y).reduce!min);
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

string describeSingle(in Occurrence occ)
{
    string ret;
    occ.tile.accept(new class TileVisitor {
        override void visit(const(TerrainTile) te) { ret = te.name; }
        override void visit(const(GadgetTile) ga) { ret = ga.name; }
        override void visit(const(TileGroup) group)
        {
            ret = format!"%d%s"(group.key.elements.len,
                                Lang.editorBarGroup.transl);
        }
    });
    if (! occ.can.rotate || ! occ.can.mirror)
        return ret;
    if (occ.rotCw == 0 && ! occ.mirrY)
        return ret;
    return ret ~ format!" [%s%s]"(
        occ.mirrY ? "f" : "",
        'r'.repeat(occ.rotCw));
}
