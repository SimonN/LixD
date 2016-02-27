module editor.io;

import std.algorithm;
import std.conv;

import editor.editor;
import editor.panel;
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
    Map newMap() { with (_level) return new Map(xl, yl, torusX, torusY,
        Geom.screenXls.to!int, (Geom.screenYls - Geom.panelYls).to!int); }
    _map        = newMap();
    _mapTerrain = newMap();
    _map.centerOnAverage(_level.pos[GadType.HATCH].map!(h => h.centerOnX),
                         _level.pos[GadType.HATCH].map!(h => h.centerOnY));
    editor.makePanel();
}}

void implDestructor(Editor editor)
{
    if (editor._panel)
        rmElder(editor._panel);
}
