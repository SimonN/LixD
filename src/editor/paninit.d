module editor.paninit;

import std.algorithm;
import std.range;
import std.string;

import basics.globals;
import basics.rect;
import file.option;
import editor.editor;
import editor.group;
import editor.io;
import editor.select;
import editor.mirrtile;
import editor.gui.browter;
import editor.gui.constant;
import editor.gui.panel;
import editor.gui.skills;
import editor.gui.topology;
import editor.undoable.clone;
import editor.undoable.compound;
import editor.undoable.zorder;
import file.language;
import file.filename;
import gui;
import hardware.keyset;
import level.level;
import level.oil;

package:

void makePanel(Editor editor)
{
    editor._panel = new EditorPanel();
    addDrawingOnlyElder(editor._panel);

    with (editor._panel) {
        onExecute(Lang.editorButtonFileNew, KeySet(), () {
            editor.setLevelAndCreateUndoStack(newEmptyLevel, null);
        });
        onExecute(Lang.editorButtonFileExit, keyEditorExit, () {
            editor.askForDataLossThenExecute(() {
                editor._gotoMainMenuOnceAllWindowsAreClosed = true;
            });
        });
        onExecute(Lang.editorButtonFileSave, keyEditorSave, () {
            editor.saveToExistingFile();
        });
        onExecute(Lang.editorButtonFileSaveAs, keyEditorSaveAs, () {
            editor.openSaveAsBrowser();
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
        onExecute(Lang.editorButtonUndo, keyEditorUndo, () {
            editor.undoOne();
        }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonRedo, keyEditorRedo, () {
            editor.redoOne();
        }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonGroup, keyEditorGroup, () {
            editor.createGroup();
        });
        onExecute(Lang.editorButtonUngroup, keyEditorUngroup, () {
            editor.ungroup();
        });
        onExecute(Lang.editorButtonSelectCopy, keyEditorCopy, () {
            if (editor._selection.empty)
                return;
            editor.apply(new CopyPaste(
                editor.levelRefacme,
                editor._selection.clone.assumeUnique,
                editor._dragger.clonedShouldMoveBy));
            // editor._dragger.startRecordingCopyMove(); -- unimplemented;
        });
        onExecute(Lang.editorButtonSelectDelete, keyEditorDelete, () {
            editor.removeFromLevelTheSelection();
            if (editor._dragger.moving)
                editor._dragger.stop();
        });
        onExecute(Lang.editorButtonBackground, keyEditorBackground, () {
            // see "Comment on correct zOrdering calls" in editor.hover.
            editor.zOrderSelectionTowards(FgBg.bg);
            }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonForeground, keyEditorForeground, () {
            editor.zOrderSelectionTowards(FgBg.fg);
            }, Button.WhenToExecute.whenMouseClickAllowingRepeats);

        // Zoom execute is handled in Editor.calc()
        buttonZoom.hotkey = keyZoomIn;
        buttonZoom.hotkeyRight = keyZoomOut;

        onExecute(Lang.editorButtonMirrorHorizontally, keyEditorMirror, () {
            editor.mirrorSelectionHorizontally;
        });
        onExecute(Lang.editorButtonSelectRotate, keyEditorRotate, () {
            editor.rotateSelectionClockwise;
        });
        onExecute(Lang.editorButtonSelectDark, keyEditorDark, () {
            editor.toggleDarkTheSelection();
        });
        template mkSubwin(string forWhat) {
            enum string mkSubwin = q{
                onExecuteText(Lang.editorButtonMenu%s, Lang.win%sTitle,
                    keyEditorMenu%s, () {
                        if (! editor.mainUIisActive)
                            return;
                        editor._dragger.stop();
                        editor._hover.clear();
                        editor._okCancelWindow = new %sWindow(
                            editor.levelRefacme);
                        addFocus(editor._okCancelWindow);
                        button(Lang.editorButtonMenu%s).on = true;
                    });
                }.format(forWhat, forWhat, forWhat, forWhat, forWhat);
        }
        mixin (mkSubwin!"Constants");
        mixin (mkSubwin!"Topology");
        mixin (mkSubwin!"Skills");
        template mkBrowser(string name, string constructorArgs) {
            enum string mkBrowser = q{
                    onExecute(Lang.editorButtonAdd%s, keyEditorAdd%s, () {
                        if (! editor.mainUIisActive)
                            return;
                        editor._terrainBrowser = new TerrainBrowser(%s);
                        addFocus(editor._terrainBrowser);
                        button(Lang.editorButtonAdd%s).on = true;
                        editor._dragger.stop();
                        editor._hover.clear();
                    });
                }.format(name, name, constructorArgs, name);
        }
        // We pass editor._selection here.
        // I don't go through chain(_selection, _hover) because I believe that
        // will irritate users. If you don't click something, you haven't done
        // anything, you shouldn't affect the browser's starting directory.
        enum edMap = "editor._selection[].map!(o => o.occ(editor.level).tile)";
        mixin (mkBrowser!("Terrain",
            "[0], editorLastDirTerrain, MergeDirs.depthTwo, " ~ edMap));
        mixin (mkBrowser!("Steel", "[preExtSteel], editorLastDirSteel,"
            ~ " MergeDirs.allIntoRoot, " ~ edMap));
        mixin (mkBrowser!("Hatch", "[preExtHatch], editorLastDirHatch"));
        mixin (mkBrowser!("Goal", "[preExtGoal], editorLastDirGoal"));
        mixin (mkBrowser!("Hazard", "['W','T','F'], editorLastDirHazard"));
    }
}

void zOrderSelectionTowards(Editor editor, FgBg fgbg) { with (editor)
{
    auto uOrNull = zOrderingTowardsOrNull(levelRefacme, _selection, fgbg);
    if (uOrNull !is null)
        apply(uOrNull);
}}
