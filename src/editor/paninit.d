module editor.paninit;

import std.algorithm;
import std.range;
import std.string;

import basics.globals;
import basics.rect;
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
import opt = file.option.allopts;
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
        onExecute(
            Lang.editorButtonFileNew,
            KeySet(),
            () {
                editor.askForDataLossThenExecute(() {
                    editor.setLevelAndCreateUndoStack(newEmptyLevel, null);
                });
            }
        );
        onExecute(Lang.editorButtonFileExit, opt.keyEditorExit.value, () {
            editor.askForDataLossThenExecute(() {
                editor._gotoMainMenuOnceAllWindowsAreClosed = true;
            });
        });
        onExecute(Lang.editorButtonFileSave, opt.keyEditorSave.value, () {
            editor.saveToExistingFile();
        });
        onExecute(Lang.editorButtonFileSaveAs, opt.keyEditorSaveAs.value, () {
            editor.openSaveAsBrowser();
        });
        // Changing the grid is done manually in Editor.calc, not with a
        // delegate passed to these buttons.
        onExecute(Lang.editorButtonGrid2,      opt.keyEditorGrid.value, null);
        onExecute(Lang.editorButtonGridCustom, opt.keyEditorGrid.value, null);
        onExecute(Lang.editorButtonGrid16,     opt.keyEditorGrid.value, null);
        onExecute(Lang.editorButtonSelectAll, opt.keyEditorSelectAll.value, () {
            editor.selectAll();
        });
        onExecute(Lang.editorButtonSelectFrame, opt.keyEditorSelectFrame.value, () {
            buttonFraming.on = ! buttonFraming.on;
        });
        onExecute(Lang.editorButtonSelectAdd, opt.keyEditorSelectAdd.value, () {
            buttonSelectAdd.on = ! buttonSelectAdd.on;
        });
        onExecute(Lang.editorButtonUndo, opt.keyEditorUndo.value, () {
            editor.undoOne();
        }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonRedo, opt.keyEditorRedo.value, () {
            editor.redoOne();
        }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonGroup, opt.keyEditorGroup.value, () {
            editor.createGroup();
        });
        onExecute(Lang.editorButtonUngroup, opt.keyEditorUngroup.value, () {
            editor.ungroup();
        });
        onExecute(Lang.editorButtonSelectCopy, opt.keyEditorCopy.value, () {
            if (editor._selection.empty)
                return;
            editor.apply(new CopyPaste(
                editor.levelRefacme,
                editor._selection.clone.assumeUnique,
                editor._dragger.clonedShouldMoveBy));
            // editor._dragger.startRecordingCopyMove(); -- unimplemented;
        });
        onExecute(Lang.editorButtonSelectDelete, opt.keyEditorDelete.value, () {
            editor.removeFromLevelTheSelection();
            if (editor._dragger.moving)
                editor._dragger.stop();
        });
        onExecute(Lang.editorButtonBackground, opt.keyEditorBackground.value, () {
            // see "Comment on correct zOrdering calls" in editor.hover.
            editor.zOrderSelectionTowards(FgBg.bg);
            }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonForeground, opt.keyEditorForeground.value, () {
            editor.zOrderSelectionTowards(FgBg.fg);
            }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonMirrorHorizontally,
            opt.keyEditorMirrorHorizontally.value, () {
                editor.mirrorSelectionHorizontally;
            });
        onExecute(Lang.editorButtonFlipVertically,
            opt.keyEditorFlipVertically.value, () {
                editor.flipSelectionVertically;
            });
        onExecute(Lang.editorButtonSelectRotate, opt.keyEditorRotate.value, () {
            editor.rotateSelectionClockwise;
        });
        onExecute(Lang.editorButtonSelectDark, opt.keyEditorDark.value, () {
            editor.toggleDarkTheSelection();
        });
        template mkSubwin(string forWhat) {
            enum string mkSubwin = q{
                onExecuteText(Lang.editorButtonMenu%s, Lang.win%sTitle,
                    opt.keyEditorMenu%s.value, () {
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
                onExecute(
                    Lang.editorButtonAdd%s,
                    opt.keyEditorAdd%s.value,
                    () {
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
            "[0], opt.editorLastDirTerrain, MergeDirs.depthTwo, " ~ edMap));
        mixin (mkBrowser!("Steel", "[preExtSteel], opt.editorLastDirSteel,"
            ~ " MergeDirs.allIntoRoot, " ~ edMap));
        mixin (mkBrowser!("Hatch", "[preExtHatch], opt.editorLastDirHatch"));
        mixin (mkBrowser!("Goal", "[preExtGoal], opt.editorLastDirGoal"));
        mixin (mkBrowser!("Hazard", "['W','T','F'], opt.editorLastDirHazard"));
    }
}

void zOrderSelectionTowards(Editor editor, FgBg fgbg) { with (editor)
{
    auto uOrNull = zOrderingTowardsOrNull(levelRefacme, _selection, fgbg);
    if (uOrNull !is null)
        apply(uOrNull);
}}
