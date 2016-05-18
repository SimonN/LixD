module editor.io;

import std.algorithm;
import std.conv;
import std.string;

import basics.globconf;
import basics.user; // hotkeys for the popup dialogs
import editor.dragger;
import editor.editor;
import editor.gui.panel;
import editor.paninit;
import file.filename;
import file.language;
import graphic.map;
import gui;
import hardware.keyset;
import level.level;
import tile.gadtile;

package:

void implConstructor(Editor editor) { with (editor)
{
    _level = new Level(_loadedFrom);
    _levelToCompareAgainstToAskForDataLoss = new Level(_loadedFrom);

    Map newMap() { with (_level) return new Map(topology,
        Geom.screenXls.to!int, (Geom.screenYls - Geom.panelYls).to!int); }
    _map        = newMap();
    _mapTerrain = newMap();
    _map.centerOnAverage(
        _level.pos[GadType.HATCH].map!(h => h.screenCenter.x),
        _level.pos[GadType.HATCH].map!(h => h.screenCenter.y));
    _dragger = new MouseDragger();
    editor.makePanel();
}}

void implDestructor(Editor editor)
{
    if (editor._panel)
        rmElder(editor._panel);
}

void newLevel(Editor editor)
{
    editor.askForDataLossThenExecute(delegate void() {
        editor._hover = null;
        editor._selection = null;
        editor._loadedFrom = null;

        editor._level        = new Level;
        editor._level.author = basics.globconf.userName;
        editor._levelToCompareAgainstToAskForDataLoss        = new Level;
        editor._levelToCompareAgainstToAskForDataLoss.author = userName;
    });
}

MsgBox askForDataLossThenExecute(
    Editor editor,
    void delegate() unlessCancelledExecuteThis
) {
    assert (editor._level !is editor._levelToCompareAgainstToAskForDataLoss);
    if (editor._level == editor._levelToCompareAgainstToAskForDataLoss) {
        unlessCancelledExecuteThis();
        return null;
    }
    else {
        MsgBox box = new MsgBox(Lang.saveBoxTitleSave.transl);
        if (editor._loadedFrom) {
            box.addMsg(Lang.saveBoxQuestionUnsavedChangedLevel.transl);
            box.addMsg("%s %s".format(Lang.saveBoxFileName.transl,
                                      editor._loadedFrom.rootful));
        }
        else {
            box.addMsg(Lang.saveBoxQuestionUnsavedNewLevel.transl);
        }
        if (editor._level.name != null)
            box.addMsg("%s %s".format(Lang.saveBoxLevelName.transl,
                                      editor._level.name));
        // DTODO: add handling for 'yes'
        box.addButton("(not impl)", // Lang.saveBoxYesSave.transl
                      keyMenuOkay);
        box.addButton(Lang.saveBoxNoDiscard.transl, keyMenuDelete,
                      unlessCancelledExecuteThis);
        box.addButton(Lang.saveBoxNoCancel.transl,
                      KeySet(keyMenuExit, keyEditorExit));
        addFocus(box);
        return box;
    }
}
