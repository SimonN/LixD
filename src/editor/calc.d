module editor.calc;

import std.algorithm;
import std.format;
import std.range;

import optional;

import basics.help;
import basics.topology;
import opt = file.option.allopts;
import editor.editor;
import editor.guiapply;
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
    _map.calcZoomAndScrolling();
    if (aboutToTrash) {
        mouseCursor.want(MouseCursor.Shape.trashcan);
    }
    else if (_map.isHoldScrolling) {
        mouseCursor.want(MouseCursor.Arrows.scroll);
    }
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
        on = hotkey.isHeld || _dragger.framing ? true
           : hotkey.wasReleased ? false : on;
    with (_panel.buttonSelectAdd)
        on = hotkey.isHeld ? true : hotkey.wasReleased ? false : on;
}}

void selectGrid(Editor editor)
{
    int g = opt.editorGridSelected.value;
    scope (exit)
        opt.editorGridSelected = g;
    g = (g == 1 || g == 2 || g == 16
        || g == opt.editorGridCustom.value) ? g : 1;
    assert (editor._panel.button(Lang.editorButtonGrid2));
    if (opt.keyEditorGrid.wasTapped)
        g = () { switch (g) {
            case 16: return 1;
            case  1: return 2;
            case  2: return opt.editorGridCustom.value;
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
            check(button(Lang.editorButtonGridCustom),
                opt.editorGridCustom.value);
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

    // Prevent the tile from entering beyond the top/left sides of the level.
    occ.loc = level.topology.clamp(occ.loc);
    // Prevent from entering beyond the bottom/right sides of the level.
    {
        immutable Point padding = Point(
            max(tile.cb.len.x, opt.editorGridSelected.value),
            max(tile.cb.len.y, opt.editorGridSelected.value));
        occ.loc = level.topology.clamp(occ.loc + padding) - padding;
    }
    occ.loc = occ.loc.roundTo(opt.editorGridSelected.value);
    /*
     * Satisfy TileMove's requirement that TileMove's ctor can't assert:
     * On torus maps, all coordinates must be nicely wrapped before and after
     * moving.
     */
    occ.loc = level.topology.wrap(occ.loc);
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
