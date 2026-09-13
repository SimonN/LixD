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

class OptionsMenu : Window {
private:
    bool _gotoMainMenu;

    TextButton okay;
    TextButton cancel;
    Explainer explainer;

    enum OptionGroup {
        general, graphics, controls, gameControls,
        gameKeys, editorKeys, menuKeys
    }

    Enumap!(OptionGroup, TextButton) groupButtons;
    Enumap!(OptionGroup, Option[]) groups;

    // extra references to what's in the groups, to update color immediately,
    // and to check user name to not be empty
    NumPick guiRed, guiGreen, guiBlue;
    Texttype _userName;

    KeyDuplicationWatcher waGame;
    KeyDuplicationWatcher waEdit;
    KeyDuplicationWatcher waMenu;
    KeyDuplicationWatcher waMainMenu;
    KeyDuplicationWatcher waEndOfLevel;

public bool gotoMainMenu() const pure nothrow @safe @nogc
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
    mkGrpButton(OptionGroup.general, Lang.optionGroupGeneral);
    mkGrpButton(OptionGroup.graphics, Lang.optionGroupGraphics);
    mkGrpButton(OptionGroup.controls, Lang.optionGroupControls);
    mkGrpButton(OptionGroup.gameControls, Lang.optionGroupGameControls);
    mkGrpButton(OptionGroup.gameKeys, Lang.optionGroupGameKeys);
    mkGrpButton(OptionGroup.editorKeys, Lang.optionGroupEditorKeys);
    mkGrpButton(OptionGroup.menuKeys, Lang.optionGroupMenuKeys);

    waGame = new KeyDuplicationWatcher();
    waEdit = new KeyDuplicationWatcher();
    waMenu = new KeyDuplicationWatcher();
    waMainMenu = new KeyDuplicationWatcher();
    waEndOfLevel = new KeyDuplicationWatcher();

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
            explainer.explainNothing();
            return;
        }
    }
    catch (Exception)
        return;
    foreach (opt; group)
        if (opt.isMouseHere) {
            explainer.explain(opt.lang);
            return;
        }
    explainer.explainNothing();
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
    populateGameControls();
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
    return OptionFactory(20 + xl*column, 100, xl, 0);
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

    fac = facRight();
    grp ~= fac.factory!TextOption(userNameOption);
    _userName = (cast (TextOption) grp[$-1]).texttype;
    grp ~= fac.factory!LanguageOption(100f);

    fac = facLeft();
    fac.y  = 250;
    fac.xl = xlg - 20;
    immutable xOfSecondOption = facRight().x - facLeft().x;
    grp ~= fac.factory!VolumePreviewingOption(xOfSecondOption,
        soundEnabled, soundDecibels, new SoundEffectExamplePlayer);
    grp ~= fac.factory!VolumePreviewingOption(xOfSecondOption,
        musicEnabled, musicDecibels, new MusicExamplePlayer);
}

void populateGraphics()
{
    Option[] grp;
    scope (exit)
        groups[OptionGroup.graphics] = grp;
    auto fac = facLeft();
    grp ~= [
        fac.factory!RadioIntOption(screenType,
            Lang.optionScreenWindowed,
            Lang.optionScreenSoftwareFullscreen,
            Lang.optionScreenHardwareFullscreen),
        fac.factory!BoolOption(allowBlurryZoom),
    ];
    immutable bottomHalfY = 250f;
    fac.y = bottomHalfY;
    grp ~= [
        fac.factory!BoolOption(paintTorusSeams),
        fac.factory!BoolOption(showFPS),
    ];
    fac = facRight();
    grp ~= [
        fac.factory!ResolutionOption(screenWindowedX, screenWindowedY),
    ];
    fac.y += 10;
    grp ~= [
        fac.factory!ResolutionOption(screenHardwareFullscreenX,
            screenHardwareFullscreenY),
    ];
}

void populateControls()
{
    auto fac = facLeft();
    groups[OptionGroup.controls] ~= [
        fac.factory!HotkeyOption(keyZoomIn, waGame, waEdit),
        fac.factory!HotkeyOption(keyZoomOut, waGame, waEdit),
        fac.factory!HotkeyOption(keyScroll, waGame, waEdit),
        fac.factory!HotkeyOption(keyPriorityInvert, waGame, waEdit),
        fac.factory!HotkeyOption(keyScreenshot,
            waGame, waEdit, waMenu, waMainMenu, waEndOfLevel),
    ];
    fac.y += 30f;
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

void populateGameControls()
{
    auto fac = facLeft();
    groups[OptionGroup.gameControls] ~= [
        fac.factory!RadioBoolOption(replayAfterFrameBack,
            Lang.optionRewindIsBrowse, true,
            Lang.optionRewindIsUndo, false),
        fac.factory!HeadingAndBoolOptions(Lang.optionWhenTweakerHidden,
            airClicksCutWhenTweakerHidden,
            insertAssignmentsWhenTweakerHidden),
        fac.factory!HeadingAndBoolOptions(Lang.optionWhenTweakerShown,
            airClicksCutWhenTweakerShown,
            insertAssignmentsWhenTweakerShown),
    ];
    fac.y += 30;
    groups[OptionGroup.gameControls] ~=
        fac.factory!BoolOption(ingameTooltips);

    fac = facRight();
    groups[OptionGroup.gameControls] ~= [
        fac.factory!BoolOption(unpauseOnAssign),
        fac.factory!BoolOption(avoidBuilderQueuing),
        fac.factory!BoolOption(avoidBatterToExploder),
    ];
    {
        auto cfg = NumPickConfig();
        cfg.min = -8;
        cfg.max = 8;
        cfg.signAlways = true;
        groups[OptionGroup.gameControls] ~=
            fac.factory!NumPickOption(cfg, rewindToAssignmentPlusTicks);
    }

    fac.y += 30;
    groups[OptionGroup.gameControls] ~=
        fac.factory!RadioIntOption(splatRulerDesign,
            Lang.optionSplatRulerDesign2Bars,
            Lang.optionSplatRulerDesign094,
            Lang.optionSplatRulerDesign3Bars);
    {
        auto cfg = NumPickConfig();
        cfg.digits = 3;
        cfg.min = 0;
        cfg.max = 300;
        cfg.stepSmall = 2;
        cfg.stepMedium = 20;
        groups[OptionGroup.gameControls] ~=
            fac.factory!NumPickOption(cfg, splatRulerSnapPixels);
    }
}

void populateGameKeys()
{
    immutable float skillXl = (xlg - 40) / skillSort.length;
    foreach (x, ac; skillSort)
        groups[OptionGroup.gameKeys] ~= new SkillHotkeyOption(new Geom(
            20 + x * skillXl, 75, skillXl, 85), ac, keySkill[ac],
            waGame);

    enum plusBelowSkills = 70f;
    auto fac = facKeys!0;
    fac.y += plusBelowSkills;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyPause, waGame),
        fac.factory!HotkeyOption(keyRestart, waGame),
        fac.factory!HotkeyOption(keyStateLoad, waGame),
        fac.factory!HotkeyOption(keyStateSave, waGame),
    ];
    fac.y += 10f;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyForceLeft, waGame),
        fac.factory!HotkeyOption(keyForceRight, waGame),
    ];

    fac = facKeys!1;
    fac.y += plusBelowSkills;
    immutable xForBoolOptionsBelowHotkeys = fac.x;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keySpeedFast, waGame),
        fac.factory!HotkeyOption(keySpeedTurbo, waGame),
    ];
    fac.y += 10f;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyRewindPrevPly, waGame),
        fac.factory!HotkeyOption(keyRewindOneSecond, waGame),
        fac.factory!HotkeyOption(keyRewindOneTick, waGame),
        fac.factory!HotkeyOption(keySkipOneTick, waGame),
        fac.factory!HotkeyOption(keySkipTenSeconds, waGame),
    ];

    fac = facKeys!2;
    fac.y += plusBelowSkills;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyNuke, waGame),
        fac.factory!HotkeyOption(keyGameExit, waGame),
    ];
    fac.y += 10f;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyChat, waGame),
        fac.factory!HotkeyOption(keyHighlightGoals, waGame),
        fac.factory!HotkeyOption(keyShowSplatRuler, waGame),
        fac.factory!HotkeyOption(keyShowTweaker, waGame),
    ];
}

void populateEditorKeys()
{
    auto fac = facKeys!0;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorLeft, waEdit),
        fac.factory!HotkeyOption(keyEditorRight, waEdit),
        fac.factory!HotkeyOption(keyEditorUp, waEdit),
        fac.factory!HotkeyOption(keyEditorDown, waEdit),
    ];
    fac.y += 10f;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorUndo, waEdit),
        fac.factory!HotkeyOption(keyEditorRedo, waEdit),
    ];
    fac.y += 10f;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorCopy, waEdit),
        fac.factory!HotkeyOption(keyEditorDelete, waEdit),
        fac.factory!HotkeyOption(keyEditorGrid, waEdit),
    ];
    fac.y += 40f;
    fac.xl = this.xlg - 40;
    auto cfg = NumPickConfig();
    cfg.max = 96;
    cfg.min =  1;
    groups[OptionGroup.editorKeys] ~=
        fac.factory!NumPickOption(cfg, editorGridCustom);

    fac = facKeys!1;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorSelectAll, waEdit),
        fac.factory!HotkeyOption(keyEditorSelectFrame, waEdit),
        fac.factory!HotkeyOption(keyEditorSelectAdd, waEdit),
    ];
    fac.y += 10f;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorGroup, waEdit),
        fac.factory!HotkeyOption(keyEditorUngroup, waEdit),
        fac.factory!HotkeyOption(keyEditorBackground, waEdit),
        fac.factory!HotkeyOption(keyEditorForeground, waEdit),
        fac.factory!HotkeyOption(keyEditorMirrorHorizontally, waEdit),
        fac.factory!HotkeyOption(keyEditorFlipVertically, waEdit),
        fac.factory!HotkeyOption(keyEditorRotate, waEdit),
        fac.factory!HotkeyOption(keyEditorDark, waEdit),
    ];

    fac = facKeys!2;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorAddTerrain, waEdit),
        fac.factory!HotkeyOption(keyEditorAddSteel, waEdit),
        fac.factory!HotkeyOption(keyEditorAddHatch, waEdit),
        fac.factory!HotkeyOption(keyEditorAddGoal, waEdit),
        fac.factory!HotkeyOption(keyEditorAddHazard, waEdit),
    ];
    fac.y += 10f;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorMenuConstants, waEdit),
        fac.factory!HotkeyOption(keyEditorMenuTopology, waEdit),
        fac.factory!HotkeyOption(keyEditorMenuSkills, waEdit),
    ];
    fac.y += 10f;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorSave, waEdit),
        fac.factory!HotkeyOption(keyEditorSaveAs, waEdit),
        fac.factory!HotkeyOption(keyEditorExit, waEdit),
    ];
}

void populateMenuKeys()
{
    Option[] grp;
    scope (exit)
        groups[OptionGroup.menuKeys] = grp;
    auto fac = facKeys!0;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuOkay, waMenu),
        fac.factory!HotkeyOption(keyMenuEdit, waMenu),
        fac.factory!HotkeyOption(keyMenuNewLevel, waMenu),
        fac.factory!HotkeyOption(keyMenuRepForLev, waMenu),
        fac.factory!HotkeyOption(keyMenuExport, waMenu),
        fac.factory!HotkeyOption(keyMenuDelete, waMenu),
        fac.factory!HotkeyOption(keyMenuSearch, waMenu),
    ];
    fac = facKeys!1;
    grp ~= fac.factory!HotkeyOption(keyMenuExit,
        waMenu, waMainMenu, waEndOfLevel);
    fac.y += 20;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuUpDir, waMenu),
        fac.factory!HotkeyOption(keyMenuUpBy5, waMenu),
        fac.factory!HotkeyOption(keyMenuUpBy1, waMenu),
        fac.factory!HotkeyOption(keyMenuDownBy1, waMenu),
        fac.factory!HotkeyOption(keyMenuDownBy5, waMenu),
    ];

    fac = facKeys!2;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuMainSingle, waMainMenu),
        fac.factory!HotkeyOption(keyMenuMainNetwork, waMainMenu),
        fac.factory!HotkeyOption(keyMenuMainReplays, waMainMenu),
        fac.factory!HotkeyOption(keyMenuMainOptions, waMainMenu),
    ];

    fac.y += 20;
    grp ~= [
        fac.factory!HotkeyOption(keyOutcomeSaveReplay, waEndOfLevel),
        fac.factory!HotkeyOption(keyOutcomeOldLevel, waEndOfLevel),
        fac.factory!HotkeyOption(keyOutcomeNextLevel, waEndOfLevel),
        fac.factory!HotkeyOption(keyOutcomeNextUnsolved, waEndOfLevel),
    ];

    auto guiCol   = NumPickConfig();
    guiCol.max    = 240;
    guiCol.digits = 3;
    guiCol.hex    = true;
    guiCol.stepMedium = 0x10;
    guiCol.stepSmall  = 0x02;
    fac = facKeys!0;
    fac.y = 260;
    fac.spaceBelow = 10;
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
