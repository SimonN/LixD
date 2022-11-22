module menu.options;

/* OptionsMenu: Menu with several tabs to set user options and global options.
 */

import std.algorithm;
import std.string;
import std.conv;

import enumap;

import file.option;
import file.option;
import file.language;
import file.option; // only to name the type for addNumPick
import gui;
import gui.option;
import graphic.color;
import hardware.mouse; // RMB to OK the window away
import hardware.music; // reapplyVolumeMusic

class OptionsMenu : Window {
private:
    bool _gotoMainMenu;

    TextButton okay;
    TextButton cancel;
    Explainer explainer;

    enum OptionGroup {
        general, graphics, controls, gameKeys, editorKeys, menuKeys
    }

    Enumap!(OptionGroup, TextButton) groupButtons;
    Enumap!(OptionGroup, Option[]) groups;

    // extra references to what's in the groups, to update color immediately,
    // and to check user name to not be empty
    NumPick guiRed, guiGreen, guiBlue;
    Texttype _userName;

public @property bool gotoMainMenu() const pure nothrow @safe @nogc
{
    return _gotoMainMenu;
}

public this()
{
    super(new Geom(0, 0, gui.screenXlg, gui.screenYlg));
    windowTitle = Lang.optionTitle.transl;

    okay   = newOkay  (new Geom(-60, 20, 100, 20, From.BOTTOM));
    cancel = newCancel(new Geom( 60, 20, 100, 20, From.BOTTOM));
    explainer = new Explainer(new Geom(0, 60, xlg - 40, 40, From.BOTTOM));
    addChildren(okay, cancel, explainer);

    void mkGrpButton(OptionGroup grp, Lang cap)
    {
        immutable grpButXl = (this.xlg - 40f) / (1+OptionGroup.max);
        groupButtons[grp] = new TextButton(
            new Geom((-OptionGroup.max * 0.5f + grp) * grpButXl,
            40, grpButXl, 20, From.TOP), cap.transl);
        groupButtons[grp].onExecute = () { this.showGroup(grp); };
        addChild(groupButtons[grp]);
    }
    mkGrpButton(OptionGroup.general,    Lang.optionGroupGeneral);
    mkGrpButton(OptionGroup.graphics,   Lang.optionGroupGraphics);
    mkGrpButton(OptionGroup.controls,   Lang.optionGroupControls);
    mkGrpButton(OptionGroup.gameKeys,   Lang.optionGroupGameKeys);
    mkGrpButton(OptionGroup.editorKeys, Lang.optionGroupEditorKeys);
    mkGrpButton(OptionGroup.menuKeys,   Lang.optionGroupMenuKeys);

    populateOptionGroups();
    foreach (enumVal, group; groups) {
        foreach (option; group) {
            addChild(option);
            option.loadValue();
        }
    }
    try
        showGroup(file.option.optionGroup.value.to!OptionGroup);
    catch (Exception)
        showGroup(OptionGroup.general);
}

protected override void calcSelf()
{
    explainOptions();

    if (_userName.on == false && _userName.text.strip.length == 0) {
        _userName.text = file.option.userName;
    }
    if (okay.execute || hardware.mouse.mouseClickRight) {
        saveEverything();
        reapplyVolumeMusic(); // ideally, do this on all music numpick changes
        _gotoMainMenu = true; // main menu will change resolution if necessary
    }
    else if (cancel.execute) {
        graphic.color.initialize(); // throw away just-in-time computed colors
        _gotoMainMenu = true;
    }
    else if (guiRed.execute || guiGreen.execute || guiBlue.execute) {
        computeColors(guiRed.number, guiGreen.number, guiBlue.number);
        reqDraw();
        explainer.undrawColor = guiRed.undrawColor = guiGreen.undrawColor
            = guiBlue.undrawColor = color.gui.m;
    }
}



private:

void explainOptions()
{
    Option[] group;
    try {
        group = groups[file.option.optionGroup.value.to!OptionGroup];
        // DTODOLANGUAGE: The editor relies on the enum range of editor buttons
        // to be connected. The UserOptions rely on the enum range of options
        // to be interspersed with their explanations. DRY demands that I
        // design one solution to accomodate both. Until then, the options
        // menu won't explain editor options.
        if (group is groups[OptionGroup.editorKeys]) {
            explainer.explain(null);
            return;
        }
    }
    catch (Exception)
        return;
    foreach (opt; group)
        if (opt.isMouseHere) {
            explainer.explain(opt);
            return;
        }
    explainer.explain(null);
}

void showGroup(in OptionGroup gr)
{
    file.option.optionGroup = gr;
    reqDraw();
    foreach (enumVal, group; groups) {
        if (enumVal == gr) {
            group.each!(opt => opt.show);
            groupButtons[enumVal].on = true;
        }
        else {
            group.each!(opt => opt.hide);
            groupButtons[enumVal].on = false;
        }
    }
}

void saveEverything()
{
    foreach (enumVal, group; groups)
        group.each!(option => option.saveValue);
    saveUserOptions();
}

void populateOptionGroups()
{
    populateGeneral();
    populateGraphics();
    populateControls();
    populateGameKeys();
    populateEditorKeys();
    populateMenuKeys();
}

auto facLeft()  { return OptionFactory( 20, 100,       280 - 20); }
auto facRight() { return OptionFactory(280, 100, xlg - 280 - 20); }

auto facKeys(int column)()
    if (column >= 0 && column < 3)
{
    immutable float xl = (this.xlg - 40f) / 3;
    return OptionFactory(20 + xl*column, 100, xl, 20, 20);
}

void populateGeneral()
{
    Option[] grp;
    scope (exit)
        groups[OptionGroup.general] = grp;
    auto fac = facLeft();
    fac.y += 30;
    grp ~= fac.factory!BoolOption(replayAutoSolutions);
    grp ~= fac.factory!BoolOption(replayAutoMulti);

    fac.y = 250;
    grp ~= fac.factory!BoolOption(soundEnabled);
    grp ~= fac.factory!BoolOption(musicEnabled);

    fac = facRight();
    grp ~= fac.factory!TextOption(userNameOption);
    _userName = (cast (TextOption) grp[$-1]).texttype;

    fac.yl = 100;
    grp ~= fac.factory!LanguageOption();

    fac.yl = 20;
    fac.y  = 250;
    auto cfg = NumPickConfig();
    cfg.digits = 3;
    cfg.signAlways = true;
    cfg.min = -50;
    cfg.max = 20;
    grp ~= fac.factory!NumPickOption(cfg, soundDecibels);
    grp ~= fac.factory!NumPickOption(cfg, musicDecibels);
}

void populateGraphics()
{
    Option[] grp;
    scope (exit)
        groups[OptionGroup.graphics] = grp;
    auto fac = facLeft();
    grp ~= [
        fac.factory!RadioButtonsOption(screenType,
            Lang.optionScreenWindowed.transl,
            Lang.optionScreenSoftwareFullscreen.transl,
            Lang.optionScreenHardwareFullscreen.transl),
    ];
    fac.y += fac.incrementY + 40; // 40 = 20+20 for the 2 extra radio buttons
    immutable bottomHalfY = fac.y;
    grp ~= [
        fac.factory!BoolOption(paintTorusSeams),
        fac.factory!BoolOption(ingameTooltips),
        fac.factory!BoolOption(showFPS),
    ];
    fac = facRight();
    grp ~= [
        fac.factory!ResolutionOption(screenWindowedX, screenWindowedY),
    ];
    fac.y = bottomHalfY;
    grp ~= [
        fac.factory!RadioButtonsOption(splatRulerDesign,
            Lang.optionSplatRulerDesignTwoBars.transl,
            Lang.optionSplatRulerDesign094.transl,
            Lang.optionSplatRulerDesignSuperSnap.transl),
    ];
}

void populateControls()
{
    auto fac = facLeft();
    groups[OptionGroup.controls] ~= [
        fac.factory!HotkeyOption(keyZoomIn),
        fac.factory!HotkeyOption(keyZoomOut),
        fac.factory!HotkeyOption(keyScroll),
        fac.factory!HotkeyOption(keyPriorityInvert),
        fac.factory!HotkeyOption(keyScreenshot),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.controls] ~= [
        fac.factory!BoolOption(holdToScrollInvert),
        fac.factory!BoolOption(fastMovementFreesMouse),
    ];
    fac = facRight();
    void addNumPick(UserOption!int uo, in int minVal)
    {
        auto cfg = NumPickConfig();
        cfg.max = 80;
        cfg.min = minVal;
        groups[OptionGroup.controls] ~= fac.factory!NumPickOption(cfg, uo);
    }
    addNumPick(mouseSpeed, 1);
    addNumPick(scrollSpeedEdge, 0);
    addNumPick(holdToScrollSpeed, 1);
}

void populateGameKeys()
{
    KeyDuplicationWatcher watcher = new KeyDuplicationWatcher();
    scope (success)
        watcher.checkForDuplicateBindings();

    immutable float skillXl = (xlg - 40) / skillSort.length;
    foreach (x, ac; skillSort)
        groups[OptionGroup.gameKeys] ~= new SkillHotkeyOption(new Geom(
            20 + x * skillXl, 75, skillXl, 85), ac, keySkill[ac], watcher);

    enum plusBelowSkills = 70f;
    auto fac = facKeys!0;
    fac.y += plusBelowSkills;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyForceLeft, watcher),
        fac.factory!HotkeyOption(keyForceRight, watcher),
    ];
    fac.y += fac.incrementY / 2;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyRestart, watcher),
        fac.factory!HotkeyOption(keyStateLoad, watcher),
        fac.factory!HotkeyOption(keyStateSave, watcher),
        fac.factory!HotkeyOption(keyShowTweaker, watcher),
    ];

    fac = facKeys!1;
    fac.y += plusBelowSkills;
    immutable xForBoolOptionsBelowHotkeys = fac.x;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keySpeedFast, watcher),
        fac.factory!HotkeyOption(keySpeedTurbo, watcher),
    ];
    fac.y += fac.incrementY / 2;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyFrameBackMany, watcher),
        fac.factory!HotkeyOption(keyFrameBackOne, watcher),
        fac.factory!HotkeyOption(keyFrameAheadOne, watcher),
        fac.factory!HotkeyOption(keyFrameAheadMany, watcher),
    ];

    fac = facKeys!2;
    fac.y += plusBelowSkills;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyPause, watcher),
        fac.factory!HotkeyOption(keyNuke, watcher),
        fac.factory!HotkeyOption(keyGameExit, watcher),
    ];
    fac.y += fac.incrementY / 2;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyChat, watcher),
        fac.factory!HotkeyOption(keyHighlightGoals, watcher),
        fac.factory!HotkeyOption(keyShowSplatRuler, watcher),
    ];

    enum belowAllGameKeys = 310f;
    fac = facLeft();
    fac.y = belowAllGameKeys;
    fac.xl = fac.xl - 10; // Mouse hover area shouldn't obscure other options
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!BoolOption(unpauseOnAssign),
        fac.factory!BoolOption(replayAfterFrameBack),
    ];
    fac = facRight();
    fac.x = xForBoolOptionsBelowHotkeys + keyButtonXl - 20f;
    fac.y = belowAllGameKeys;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!BoolOption(avoidBuilderQueuing),
        fac.factory!BoolOption(avoidBatterToExploder),
    ];
}

void populateEditorKeys()
{
    KeyDuplicationWatcher watcher = new KeyDuplicationWatcher();
    scope (success)
        watcher.checkForDuplicateBindings();

    auto fac = facKeys!0;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorLeft, watcher),
        fac.factory!HotkeyOption(keyEditorRight, watcher),
        fac.factory!HotkeyOption(keyEditorUp, watcher),
        fac.factory!HotkeyOption(keyEditorDown, watcher),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorUndo, watcher),
        fac.factory!HotkeyOption(keyEditorRedo, watcher),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorCopy, watcher),
        fac.factory!HotkeyOption(keyEditorDelete, watcher),
        fac.factory!HotkeyOption(keyEditorGrid, watcher),
    ];
    fac.y += fac.incrementY;
    fac.xl = this.xlg - 40;
    auto cfg = NumPickConfig();
    cfg.max = 96;
    cfg.min =  1;
    groups[OptionGroup.editorKeys] ~=
        fac.factory!NumPickOption(cfg, editorGridCustom);

    fac = facKeys!1;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorSelectAll, watcher),
        fac.factory!HotkeyOption(keyEditorSelectFrame, watcher),
        fac.factory!HotkeyOption(keyEditorSelectAdd, watcher),
    ];
    fac.y += fac.incrementY / 2;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorGroup, watcher),
        fac.factory!HotkeyOption(keyEditorUngroup, watcher),
        fac.factory!HotkeyOption(keyEditorBackground, watcher),
        fac.factory!HotkeyOption(keyEditorForeground, watcher),
        fac.factory!HotkeyOption(keyEditorMirrorHorizontally, watcher),
        fac.factory!HotkeyOption(keyEditorFlipVertically, watcher),
        fac.factory!HotkeyOption(keyEditorRotate, watcher),
        fac.factory!HotkeyOption(keyEditorDark, watcher),
    ];

    fac = facKeys!2;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorAddTerrain, watcher),
        fac.factory!HotkeyOption(keyEditorAddSteel, watcher),
        fac.factory!HotkeyOption(keyEditorAddHatch, watcher),
        fac.factory!HotkeyOption(keyEditorAddGoal, watcher),
        fac.factory!HotkeyOption(keyEditorAddHazard, watcher),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorMenuConstants, watcher),
        fac.factory!HotkeyOption(keyEditorMenuTopology, watcher),
        fac.factory!HotkeyOption(keyEditorMenuSkills, watcher),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorSave, watcher),
        fac.factory!HotkeyOption(keyEditorSaveAs, watcher),
        fac.factory!HotkeyOption(keyEditorExit, watcher),
    ];
}

void populateMenuKeys()
{
    KeyDuplicationWatcher watcher = new KeyDuplicationWatcher();
    scope (success)
        watcher.checkForDuplicateBindings();

    Option[] grp;
    scope (exit)
        groups[OptionGroup.menuKeys] = grp;
    auto fac = facKeys!0;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuOkay, watcher),
        fac.factory!HotkeyOption(keyMenuEdit, watcher),
        fac.factory!HotkeyOption(keyMenuNewLevel, watcher),
        fac.factory!HotkeyOption(keyMenuRepForLev, watcher),
        fac.factory!HotkeyOption(keyMenuExport, watcher),
        fac.factory!HotkeyOption(keyMenuDelete, watcher),
        fac.factory!HotkeyOption(keyMenuSearch, watcher),
    ];
    fac = facKeys!1;
    grp ~= fac.factory!HotkeyOption(keyMenuExit, watcher);
    fac.y += 20;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuUpDir, watcher),
        fac.factory!HotkeyOption(keyMenuUpBy5, watcher),
        fac.factory!HotkeyOption(keyMenuUpBy1, watcher),
        fac.factory!HotkeyOption(keyMenuDownBy1, watcher),
        fac.factory!HotkeyOption(keyMenuDownBy5, watcher),
    ];

    KeyDuplicationWatcher wat2 = new KeyDuplicationWatcher();
    fac = facKeys!2;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuMainSingle, wat2),
        fac.factory!HotkeyOption(keyMenuMainNetwork, wat2),
        fac.factory!HotkeyOption(keyMenuMainReplays, wat2),
        fac.factory!HotkeyOption(keyMenuMainOptions, wat2),
    ];

    KeyDuplicationWatcher wat3 = new KeyDuplicationWatcher();
    scope (success)
        wat2.checkForDuplicateBindings();
    fac.y += 20;
    grp ~= [
        fac.factory!HotkeyOption(keyOutcomeSaveReplay, wat3),
        fac.factory!HotkeyOption(keyOutcomeOldLevel, wat3),
        fac.factory!HotkeyOption(keyOutcomeNextLevel, wat3),
        fac.factory!HotkeyOption(keyOutcomeNextUnsolved, wat3),
    ];

    auto guiCol   = NumPickConfig();
    guiCol.max    = 240;
    guiCol.digits = 3;
    guiCol.hex    = true;
    guiCol.stepMedium = 0x10;
    guiCol.stepSmall  = 0x02;
    fac = facKeys!0;
    fac.y = 260;
    fac.incrementY = 30;
    grp ~= [
        fac.factory!NumPickOption(guiCol, guiColorRed),
        fac.factory!NumPickOption(guiCol, guiColorGreen),
        fac.factory!NumPickOption(guiCol, guiColorBlue),
    ];
    guiRed   = (cast (NumPickOption) grp[$-3]).num;
    guiGreen = (cast (NumPickOption) grp[$-2]).num;
    guiBlue  = (cast (NumPickOption) grp[$-1]).num;
}

}
// end class OptionsMenu
