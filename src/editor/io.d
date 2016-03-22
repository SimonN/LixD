module editor.io;

import std.algorithm;
import std.conv;

import editor.dragger;
import editor.editor;
import editor.gui.panel;
import editor.paninit;
import file.filename;
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
