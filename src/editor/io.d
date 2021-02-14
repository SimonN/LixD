module editor.io;

import std.algorithm;
import std.conv;
import std.string;

import basics.globals;
import file.option;
import editor.dragger;
import editor.editor;
import editor.gui.panel;
import editor.paninit;
import file.filename;
import file.date;
import file.language;
import graphic.camera.mapncam;
import gui;
import hardware.keyset;
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
    MapAndCamera newMap() { with (level) return new MapAndCamera(topology,
        gui.screenXls.to!int, (gui.screenYls - gui.panelYls).to!int); }
    _map        = newMap();
    _mapTerrain = newMap();
    _map.centerOnAverage(
        level.gadgets[GadType.HATCH].map!(h => h.screenCenter.x),
        level.gadgets[GadType.HATCH].map!(h => h.screenCenter.y));
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
    l.author = file.option.userName;
    l.overtimeSeconds = 30; // Level discards this if saved as 1-pl
    return l;
};

void saveToExistingFile(Editor editor) {
    with (editor)
{
    if (Filename fn = _panel.currentFilenameOrNull) {
        file.option.singleLastLevel = fn;
        if (level != _levelToCompareForDataLoss)
            levelRefacme.built = Date.now();
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
        Filename single = singleLastLevel;
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
        box.addButton(Lang.saveBoxYesSave.transl, keyMenuOkay, () {
            _askForDataLoss = null;
            editor.saveToExistingFile();
            unlessCancelledExecuteThis();
        });
        box.addButton(Lang.saveBoxNoDiscard.transl, keyMenuDelete, () {
            _askForDataLoss = null;
            unlessCancelledExecuteThis();
        });
        box.addButton(Lang.saveBoxNoCancel.transl,
                      KeySet(keyMenuExit, keyEditorExit), () {
            _askForDataLoss = null;
        });
        addFocus(box);
        _askForDataLoss = box;
    }
}}
