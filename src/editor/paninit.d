module editor.paninit;

import std.algorithm;
import std.string;

import basics.globals;
import basics.user;
import editor.editor;
import editor.hover;
import editor.gui.browter;
import editor.gui.panel;
import editor.gui.skillset;
import editor.gui.visuals;
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
            import file.filename; // debugging
            editor._level.saveToFile(
                new Filename(dirLevels.dirRootless ~ "editor-test.txt"));
        });
        // Changing the grid is done manually in Editor.calc, not with a
        // delegate passed to these buttons.
        onExecute(Lang.editorButtonGrid2,      keyEditorGrid, null);
        onExecute(Lang.editorButtonGridCustom, keyEditorGrid, null);
        onExecute(Lang.editorButtonGrid16,     keyEditorGrid, null);
        onExecute(Lang.editorButtonSelectAll, keyEditorSelectAll, () {
            editor.selectAll();
        });
        onExecute(Lang.editorButtonSelectFrame, keyEditorSelectFrame, () {
            buttonFraming.on = ! buttonFraming.on;
        });
        onExecute(Lang.editorButtonSelectAdd, keyEditorSelectAdd, () {
            buttonSelectAdd.on = ! buttonSelectAdd.on;
        });
        onExecute(Lang.editorButtonSelectCopy, keyEditorCopy, () {
            foreach (sel; editor._selection) {
                sel.cloneThenPointToClone();
                sel.moveBy(editor._dragger.clonedShouldMoveBy);
            }
            // editor._dragger.startRecordingCopyMove();
        });
        onExecute(Lang.editorButtonSelectDelete, keyEditorDelete, () {
            editor._selection.each!(s => s.removeFromLevel());
            editor._selection = null;
        });
        onExecute(Lang.editorButtonBackground, keyEditorBackground, () {
            editor._selection.each!(s => s.moveTowards(Hover.FgBg.bg));
        });
        onExecute(Lang.editorButtonForeground, keyEditorForeground, () {
            editor._selection.each!(s => s.moveTowards(Hover.FgBg.fg));
        });
        onExecute(Lang.editorButtonViewZoom, keyEditorZoom, () {
            editor._map.zoom = editor._map.zoom >= 4 ? 1 :
                               editor._map.zoom * 2;
        });
        onExecute(Lang.editorButtonMenuScroll, 0, () {
            editor._okCancelWindow = new VisualsWindow(editor._level);
            addFocus(editor._okCancelWindow);
            button(Lang.editorButtonMenuScroll).on = true;
        });
        onExecute(Lang.editorButtonMenuSkill, keyEditorMenuSkills, () {
            editor._okCancelWindow = new SkillsetWindow(editor._level);
            addFocus(editor._okCancelWindow);
            button(Lang.editorButtonMenuSkill).on = true;
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
    editorButtonFileSave,
    editorButtonFileSaveAs,
    editorButtonUndo,
    editorButtonRedo,
    editorButtonSelectFlip,
    editorButtonSelectRotate,
    editorButtonSelectDark,
    editorButtonSelectNoow,
    editorButtonHelp,
    editorButtonMenuSize,
    editorButtonMenuScroll,
    editorButtonMenuVars,

    int keyEditorLeft        = ALLEGRO_KEY_S;
    int keyEditorRight       = ALLEGRO_KEY_F;
    int keyEditorUp          = ALLEGRO_KEY_E;
    int keyEditorDown        = ALLEGRO_KEY_D;
    int keyEditorDelete      = ALLEGRO_KEY_G;
    int keyEditorMirror      = ALLEGRO_KEY_W;
    int keyEditorRotate      = ALLEGRO_KEY_R;
    int keyEditorDark        = ALLEGRO_KEY_N;
    int keyEditorNoow        = ALLEGRO_KEY_M;
    int keyEditorHelp        = ALLEGRO_KEY_H;
    int keyEditorMenuSize    = ALLEGRO_KEY_5;
    int keyEditorMenuVars    = ALLEGRO_KEY_Q;
    +/
