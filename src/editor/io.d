module editor.io;

import std.conv;

import editor.editor;
import file.filename;
import graphic.map;
import gui.geometry;
import level.level;

void implConstructor(Editor editor, Filename fn) { with (editor)
{
    _loadedFrom = fn;
    _level = new Level(fn);
    _map   = new Map(_level.xl, _level.yl, _level.torusX, _level.torusY,
        Geom.screenXls.to!int, (Geom.screenYls - Geom.panelYls).to!int);
}}
