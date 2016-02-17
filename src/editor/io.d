module editor.io;

import std.algorithm;
import std.conv;

import basics.user; // hotkeys, for button delegates
import editor.editor;
import editor.panel;
import file.filename;
import file.language; // adding delegates to editor buttons
import graphic.map;
import gui;
import level.level;
import tile.gadtile;

package:

void implConstructor(Editor editor, Filename fn) { with (editor)
{
    _loadedFrom = fn;
    _level = new Level(fn);

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

private:

void makePanel(Editor editor)
{
    editor._panel = new EditorPanel();
    addElder(editor._panel);
    with (editor._panel) {
        onExecute(Lang.editorButtonFileExit, keyEditorExit, () {
            editor._gotoMainMenu = true;
        });
    }
    /+
    editorButtonFileNew,
    editorButtonFileExit,
    editorButtonFileSave,
    editorButtonFileSaveAs,
    editorButtonGrid2,
    editorButtonGridCustom,
    editorButtonGrid16,
    editorButtonSelectAll,
    editorButtonSelectFrame,
    editorButtonSelectAdd,
    editorButtonSelectCopy,
    editorButtonSelectDelete,
    editorButtonSelectMinus,
    editorButtonSelectPlus,
    editorButtonSelectBack,
    editorButtonSelectFront,
    editorButtonSelectFlip,
    editorButtonSelectRotate,
    editorButtonSelectDark,
    editorButtonSelectNoow,
    editorButtonViewZoom,
    editorButtonHelp,
    editorButtonMenuSize,
    editorButtonMenuScroll,
    editorButtonMenuVars,
    editorButtonMenuSkill,
    editorButtonAddTerrain,
    editorButtonAddSteel,
    editorButtonAddHatch,
    editorButtonAddGoal,
    editorButtonAddDeco,
    editorButtonAddHazard,

    int keyEditorLeft        = ALLEGRO_KEY_S;
    int keyEditorRight       = ALLEGRO_KEY_F;
    int keyEditorUp          = ALLEGRO_KEY_E;
    int keyEditorDown        = ALLEGRO_KEY_D;
    int keyEditorCopy        = ALLEGRO_KEY_A;
    int keyEditorDelete      = ALLEGRO_KEY_G;
    int keyEditorGrid        = ALLEGRO_KEY_C;
    int keyEditorSelectAll   = ALLEGRO_KEY_ALT;
    int keyEditorSelectFrame = ALLEGRO_KEY_LSHIFT;
    int keyEditorSelectAdd   = ALLEGRO_KEY_V;
    int keyEditorBackground  = ALLEGRO_KEY_T;
    int keyEditorForeground  = ALLEGRO_KEY_B;
    int keyEditorMirror      = ALLEGRO_KEY_W;
    int keyEditorRotate      = ALLEGRO_KEY_R;
    int keyEditorDark        = ALLEGRO_KEY_N;
    int keyEditorNoow        = ALLEGRO_KEY_M;
    int keyEditorZoom        = ALLEGRO_KEY_Y;
    int keyEditorHelp        = ALLEGRO_KEY_H;
    int keyEditorMenuSize    = ALLEGRO_KEY_5;
    int keyEditorMenuVars    = ALLEGRO_KEY_Q;
    int keyEditorMenuSkills  = ALLEGRO_KEY_X;
    int keyEditorAddTerrain  = ALLEGRO_KEY_SPACE;
    int keyEditorAddSteel    = ALLEGRO_KEY_TAB;
    int keyEditorAddHatch    = ALLEGRO_KEY_1;
    int keyEditorAddGoal     = ALLEGRO_KEY_2;
    int keyEditorAddDeco     = ALLEGRO_KEY_3;
    int keyEditorAddHazard   = ALLEGRO_KEY_4;
    int keyEditorExit        = ALLEGRO_KEY_ESCAPE;
    +/
}
