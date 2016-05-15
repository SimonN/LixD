module editor.io;

import std.algorithm;
import std.conv;
import std.string;

import basics.globconf;
import editor.dragger;
import editor.editor;
import editor.gui.panel;
import editor.paninit;
import file.filename;
import file.language;
import graphic.map;
import gui;
import level.level;
import tile.gadtile;

package:

void implConstructor(Editor editor) { with (editor)
{
    _level = new Level(_loadedFrom);
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
    Level blank = new Level;
    if (editor._level == blank)
        return;
    MsgBox box = editor.askForDataLoss();
    addFocus(box);

    editor._level = blank;
    editor._level.author = basics.globconf.userName;
    editor._hover = null;
    editor._selection = null;
    editor._loadedFrom = null;
}

MsgBox askForDataLoss(Editor editor)
{
    MsgBox box = new MsgBox(Lang.saveBoxTitleSave.transl);
    if (editor._loadedFrom) {
        box.addMsg(Lang.saveBoxQuestionUnsavedChangedLevel.transl);
        box.addMsg("%s %s".format(Lang.saveBoxFileName.transl,
                                  editor._loadedFrom));
    }
    else {
        box.addMsg(Lang.saveBoxQuestionUnsavedNewLevel.transl);
    }
    box.addMsg("%s %s".format(Lang.saveBoxLevelName.transl,
                              editor._level.name));
    box.addButton(Lang.saveBoxYesSave.transl);
    box.addButton(Lang.saveBoxNoDiscard.transl);
    box.addButton(Lang.saveBoxNoCancel.transl);
    return box;
}
