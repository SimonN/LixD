module editor.paninit;

import std.algorithm;
import std.range;
import std.string;

import basics.globals;
import basics.rect;
import basics.user;
import editor.editor;
import editor.group;
import editor.hover;
import editor.io;
import editor.select;
import editor.gui.browter;
import editor.gui.constant;
import editor.gui.looks;
import editor.gui.panel;
import editor.gui.skills;
import editor.gui.topology;
import file.language;
import file.filename;
import gui;
import hardware.keyset;
import level.level;

package:

void makePanel(Editor editor)
{
    editor._panel = new EditorPanel();
    editor._panel.currentFilename = editor._loadedFrom;
    addDrawingOnlyElder(editor._panel);

    with (editor._panel) {
        onExecute(Lang.editorButtonFileNew, KeySet(), () {
            editor.newLevel();
        });
        onExecute(Lang.editorButtonFileExit, keyEditorExit, () {
            editor.askForDataLossThenExecute(() {
                editor._gotoMainMenu = true;
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
        onExecute(Lang.editorButtonGroup, keyEditorGroup, () {
            editor.createGroup();
        });
        onExecute(Lang.editorButtonUngroup, keyEditorUngroup, () {
            editor.ungroup();
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
            // see "Comment on correct zOrdering calls" in editor.hover.
            foreach (sel; editor._selection)
                sel.zOrderTowardsButIgnore(Hover.FgBg.bg, editor._selection);
            }, Button.WhenToExecute.whenMouseClickAllowingRepeats);
        onExecute(Lang.editorButtonForeground, keyEditorForeground, () {
            foreach (sel; editor._selection.retro)
                sel.zOrderTowardsButIgnore(Hover.FgBg.fg, editor._selection);
            }, Button.WhenToExecute.whenMouseClickAllowingRepeats);

        // Zoom execute is handled in Editor.calc()
        buttonZoom.hotkey = keyZoomIn;
        buttonZoom.hotkeyRight = keyZoomOut;

        onExecute(Lang.editorButtonSelectFlip, keyEditorMirror, () {
            immutable box = editor.smallestRectContainingSelection();
            editor._selection.each!(sel => sel.mirrorHorizontallyWithin(box));
        });
        onExecute(Lang.editorButtonSelectRotate, keyEditorRotate, () {
            immutable box = editor.smallestRectContainingSelection();
            editor._selection.each!(sel => sel.rotateCwWithin(box));
        });
        onExecute(Lang.editorButtonSelectDark, keyEditorDark, () {
            editor._selection.each!(sel => sel.toggleDark());
        });
        template mkSubwin(string forWhat) {
            enum string mkSubwin = q{
                onExecuteText(Lang.editorButtonMenu%s, Lang.win%sTitle,
                    keyEditorMenu%s, () {
                        if (! editor.noWindowsOpen)
                            return;
                        editor._dragger.stop();
                        editor._hover = null;
                        editor._okCancelWindow = new %sWindow(editor._level);
                        addFocus(editor._okCancelWindow);
                        button(Lang.editorButtonMenu%s).on = true;
                    });
                }.format(forWhat, forWhat, forWhat, forWhat, forWhat);
        }
        mixin (mkSubwin!"Constants");
        mixin (mkSubwin!"Topology");
        mixin (mkSubwin!"Looks");
        mixin (mkSubwin!"Skills");
        template mkBrowser(string name, string constructorArgs) {
            enum string mkBrowser = q{
                    onExecute(Lang.editorButtonAdd%s, keyEditorAdd%s, () {
                        if (! editor.noWindowsOpen)
                            return;
                        editor._terrainBrowser = new TerrainBrowser(%s);
                        addFocus(editor._terrainBrowser);
                        button(Lang.editorButtonAdd%s).on = true;
                        editor._dragger.stop();
                        editor._hover = null;
                    });
                }.format(name, name, constructorArgs, name);
        }
        mixin (mkBrowser!("Terrain",
            "[0], editorLastDirTerrain, MergeAllDirs.no, editor.overrideCurrentDirectoryWithTileFilename"));
        mixin (mkBrowser!("Steel", "[preExtSteel], editorLastDirSteel, MergeAllDirs.no, null"));
        mixin (mkBrowser!("Hatch", "[preExtHatch], editorLastDirHatch, MergeAllDirs.yes, null"));
        mixin (mkBrowser!("Goal", "[preExtGoal], editorLastDirGoal, MergeAllDirs.yes, null"));
        mixin (mkBrowser!("Hazard", "['W','T','F'], editorLastDirHazard, MergeAllDirs.yes, null"));
    }
}

private:

Rect smallestRectContainingSelection(in Editor editor)
{
    return editor._selection.empty ? Rect()
        :  editor._selection.map   !(hov => hov.occ.selboxOnMap)
                            .reduce!(Rect.smallestContainer);
}

Filename overrideCurrentDirectoryWithTileFilename(in Editor editor)
{
    // I don't go through chain(_selection, _hover), because I believe that
    // will irritate users. If you don't click something, you haven't done
    // anything, you shouldn't affect the browser's starting directory.
    foreach (const(Hover) hov; editor._selection)
        if (hov.occ.tile.name != "")
            return new VfsFilename(dirImages.rootless ~ hov.occ.tile.name);
    return null;
}
