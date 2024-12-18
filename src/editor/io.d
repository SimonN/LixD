module editor.io;

import std.algorithm;
import std.conv;
import std.string;

import enumap;

import basics.globals;
import opt = file.option.allopts;
import editor.dragger;
import editor.editor;
import editor.gui.panel;
import editor.paninit;
import file.filename;
import file.date;
import file.language;
import graphic.camera.mapncam;
import gui;
import file.key.set;
import hardware.sound;
import level.level;
import level.oil;
import menu.browser.saveas;
import tile.gadtile;

package:

void implConstructor(
    Editor editor,
    Level delegate() toLoad,
    Filename fnOrNull, // null iff we start with a blank level
) { with (editor)
{
    editor.makePanel();
    setLevelAndCreateUndoStack(toLoad, fnOrNull);
    MapAndCamera newMap() {
        auto onlyOneCamsize = Point(gui.screenXls.to!int,
            (gui.screenYls - gui.panelYls).to!int);
        return new MapAndCamera(level.topology, enumap.enumap(
            MapAndCamera.CamSize.fullWidth, onlyOneCamsize,
            MapAndCamera.CamSize.withTweaker, onlyOneCamsize));
    }
    _map        = newMap();
    _mapTerrain = newMap();
    _map.centerOnAverage(
        level.gadgets[GadType.hatch].map!(h => h.screenCenter.x),
        level.gadgets[GadType.hatch].map!(h => h.screenCenter.y));
    _dragger = new MouseDragger();
}}

void onNewLevelButtonExecuted(Editor editor)
{
    editor.askForDataLossThenExecute(delegate void() {
        editor.setLevelAndCreateUndoStack(
            delegate Level() { return newEmptyLevel(); }, null);
    });
}

auto newEmptyLevel = delegate Level()
{
    Level l = new Level;
    l.md.author = opt.userName;
    l.overtimeSeconds = 30; // Level discards this if saved as 1-pl
    return l;
};

void saveToExistingFile(Editor editor) {
    with (editor)
{
    if (Filename fn = _panel.currentFilenameOrNull) {
        opt.singleLastLevel = fn;
        if (level != _levelToCompareForDataLoss) {
            levelRefacme.md.touch();
        }
        level.saveToFile(fn);
        _levelToCompareForDataLoss = new Level(fn);
        playQuiet(Sound.DISKSAVE);
    }
    else
        editor.openSaveAsBrowser();
}}

void openSaveAsBrowser(Editor editor) {
    with (editor)
{
    assert (mainUIisActive);
    _saveBrowser = new SaveBrowser(dirLevels);
    {
        Filename fn = _panel.currentFilenameOrNull;
        Filename single = opt.singleLastLevel.value;
        _saveBrowser.highlight(fn ? fn : single);
    }
    addFocus(_saveBrowser);
}}

void askForDataLossThenExecute(
    Editor editor,
    void delegate() unlessCancelledExecuteThis
) {
    with (editor)
{
    assert (mainUIisActive);
    assert (level !is _levelToCompareForDataLoss);
    if     (level  == _levelToCompareForDataLoss) {
        unlessCancelledExecuteThis();
    }
    else {
        MsgBox box = new MsgBox(Lang.saveBoxTitleSave.transl);
        if (_panel.currentFilenameOrNull) {
            box.addMsg(Lang.saveBoxQuestionUnsavedChangedLevel.transl);
            box.addMsg("%s %s".format(Lang.saveBoxFileName.transl,
                _panel.currentFilenameOrNull.rootless));
        }
        else {
            box.addMsg(Lang.saveBoxQuestionUnsavedNewLevel.transl);
        }
        if (level.name != null)
            box.addMsg("%s %s".format(Lang.saveBoxLevelName.transl,
                                      level.name));
        box.addButton(Lang.saveBoxYesSave.transl, opt.keyMenuOkay.value, () {
            _askForDataLoss = null;
            editor.saveToExistingFile();
            unlessCancelledExecuteThis();
        });
        box.addButton(Lang.saveBoxNoDiscard.transl, opt.keyMenuDelete.value, () {
            _askForDataLoss = null;
            unlessCancelledExecuteThis();
        });
        box.addButton(Lang.saveBoxNoCancel.transl,
            KeySet(opt.keyMenuExit.value, opt.keyEditorExit.value),
            () { _askForDataLoss = null; });
        addFocus(box);
        _askForDataLoss = box;
    }
}}
