module editor.paninit;

import std.string;

import basics.globals;
import basics.user;
import editor.editor;
import editor.gui.browter;
import editor.gui.panel;
import editor.select;
import file.language;
import gui;

package:

void makePanel(Editor editor)
{
    editor._panel = new EditorPanel();
    addElder(editor._panel);
    with (editor._panel) {
        onExecute(Lang.editorButtonFileExit, keyEditorExit, () {
            editor._gotoMainMenu = true;
        });
        onExecute(Lang.editorButtonSelectAll, keyEditorSelectAll, () {
            editor.selectAll();
        });
        onExecute(Lang.editorButtonSelectFrame, keyEditorSelectFrame, () {
            buttonFraming.on = ! buttonFraming.on;
        });
        onExecute(Lang.editorButtonSelectAdd, keyEditorSelectAdd, () {
            buttonSelectAdd.on = ! buttonSelectAdd.on;
        });
        onExecute(Lang.editorButtonSelectDelete, keyEditorDelete, () {
            foreach (sel; editor._selection)
                sel.removeFromLevel();
            editor._selection = null;
        });
        onExecute(Lang.editorButtonViewZoom, keyEditorZoom, () {
            editor._map.zoom = editor._map.zoom >= 4 ? 1 :
                               editor._map.zoom * 2;
        });
        template OnExecuteBrowser(string name, string exts) {
            enum string OnExecuteBrowser = "
                    onExecute(Lang.editorButtonAdd%s, keyEditorAdd%s, () {
                        editor._terrainBrowser = new TerrainBrowser(%s);
                        addFocus(editor._terrainBrowser);
                        button(Lang.editorButtonAdd%s).on = true;
                    });
                ".format(name, name, exts, name);
        }
        mixin (OnExecuteBrowser!("Terrain", "[0]"));
        mixin (OnExecuteBrowser!("Steel", "[preExtSteel]"));
        mixin (OnExecuteBrowser!("Hatch", "[preExtHatch]"));
        mixin (OnExecuteBrowser!("Goal", "[preExtGoal]"));
        mixin (OnExecuteBrowser!("Deco", "[preExtDeco]"));
        mixin (OnExecuteBrowser!("Hazard", "['W', 'T', 'F']"));
    }
}
    /+
    editorButtonFileNew,
    editorButtonFileExit,
    editorButtonFileSave,
    editorButtonFileSaveAs,
    editorButtonGrid2,
    editorButtonGridCustom,
    editorButtonGrid16,
    editorButtonSelectCopy,
    editorButtonSelectMinus,
    editorButtonSelectPlus,
    editorButtonSelectBack,
    editorButtonSelectFront,
    editorButtonSelectFlip,
    editorButtonSelectRotate,
    editorButtonSelectDark,
    editorButtonSelectNoow,
    editorButtonHelp,
    editorButtonMenuSize,
    editorButtonMenuScroll,
    editorButtonMenuVars,
    editorButtonMenuSkill,
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
    int keyEditorBackground  = ALLEGRO_KEY_T;
    int keyEditorForeground  = ALLEGRO_KEY_B;
    int keyEditorMirror      = ALLEGRO_KEY_W;
    int keyEditorRotate      = ALLEGRO_KEY_R;
    int keyEditorDark        = ALLEGRO_KEY_N;
    int keyEditorNoow        = ALLEGRO_KEY_M;
    int keyEditorHelp        = ALLEGRO_KEY_H;
    int keyEditorMenuSize    = ALLEGRO_KEY_5;
    int keyEditorMenuVars    = ALLEGRO_KEY_Q;
    int keyEditorMenuSkills  = ALLEGRO_KEY_X;
    int keyEditorAddSteel    = ALLEGRO_KEY_TAB;
    int keyEditorAddHatch    = ALLEGRO_KEY_1;
    int keyEditorAddGoal     = ALLEGRO_KEY_2;
    int keyEditorAddDeco     = ALLEGRO_KEY_3;
    int keyEditorAddHazard   = ALLEGRO_KEY_4;
    int keyEditorExit        = ALLEGRO_KEY_ESCAPE;
    +/
