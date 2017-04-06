module menu.options;

/* OptionsMenu: Menu with several tabs to set user options and global options.
 */

import std.algorithm;
import std.string;
import std.conv;

import enumap;

import basics.globconf;
import basics.user;
import file.language;
import file.useropt; // only to name the type for addNumPick
import gui;
import gui.option;
import graphic.color;
import hardware.mouse; // RMB to OK the window away

class OptionsMenu : Window {

    @property bool gotoMainMenu() const { return _gotoMainMenu; }
//  this(); -- exists, see below

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



public this()
{
    super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg));
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
        showGroup(basics.user.optionGroup.value.to!OptionGroup);
    catch (Exception)
        showGroup(OptionGroup.general);
}

protected override void calcSelf()
{
    if (_userName.on == false && _userName.text.strip.length == 0) {
        _userName.text = basics.globconf.userName;
    }
    if (okay.execute || hardware.mouse.mouseClickRight) {
        saveEverything();
        _gotoMainMenu = true;
    }
    else if (cancel.execute) {
        graphic.color.initialize(); // throw away just-in-time computed colors
        _gotoMainMenu = true;
    }
    else if (guiRed.execute || guiGreen.execute || guiBlue.execute) {
        computeColors(guiRed.number, guiGreen.number, guiBlue.number);
        reqDraw();
        explainer.undrawColor = guiRed.undrawColor = guiGreen.undrawColor
            = guiBlue.undrawColor = color.guiM;
    }
    explainOptions();
}



private:

void explainOptions()
{
    Option[] group;
    try {
        group = groups[basics.user.optionGroup.value.to!OptionGroup];
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
    basics.user.optionGroup = gr;
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
    string oldUser = userName;
    foreach (enumVal, group; groups)
        group.each!(option => option.saveValue);

    if (oldUser != userName) {
        basics.user.load();
        basics.user.optionGroup = OptionGroup.general;
    }
    basics.user    .save();
    basics.globconf.save();
    // On user switch, why load, then save?
    // If the user is new:
    //      Then loading doesn't overwrite any values at all, so the
    //      values set by the options menu are applied to the new user.
    //      The previous user isn't affected. In practice, the new user
    //      takes over the previous user's options as defaults. I don't
    //      know whether this is best.
    // If the changed-to user already exists:
    //      Then everything set in the options is discarded completely,
    //      even on hitting OK, and is replaced with the changed-to user's
    //      disk-saved settings. They're written to disk again, which
    //      shouldn't change the existing file on disk.
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
    fac.y = 250;
    grp ~= fac.factory!BoolOption(replayAutoSolutions);
    grp ~= fac.factory!BoolOption(replayAutoMulti);

    fac = facRight();
    grp ~= fac.factory!TextOption(Lang.optionUserName.transl, &userName);
    _userName = (cast (TextOption) grp[$-1]).texttype;

    fac.yl = 100;
    grp ~= fac.factory!LanguageOption(Lang.optionLanguage.transl);

    fac.yl = 20;
    fac.y  = 250;
    auto cfg = NumPickConfig();
    cfg.max = 20;
    cfg.min =  0;
    grp ~= fac.factory!NumPickOption(cfg, soundVolume);
}

void populateGraphics()
{
    Option[] grp;
    scope (exit)
        groups[OptionGroup.graphics] = grp;
    auto fac = facLeft();
    grp ~= [
        fac.factory!BoolOption(screenWindowed),
    ];
    fac.y += fac.incrementY;
    grp ~= [
        fac.factory!BoolOption(paintTorusSeams),
        fac.factory!BoolOption(showButtonHotkeys),
        fac.factory!BoolOption(showFPS),
    ];
    fac = facRight();
    grp ~= fac.factory!ResolutionOption(screenWindowedX, screenWindowedY);
}

void populateControls()
{
    auto fac = facLeft();
    groups[OptionGroup.controls] ~= [
        fac.factory!HotkeyOption(keyZoomIn),
        fac.factory!HotkeyOption(keyZoomOut),
        fac.factory!HotkeyOption(keyScroll),
        fac.factory!HotkeyOption(keyPriorityInvert),
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
    addNumPick(scrollSpeedClick, 1);
}

void populateGameKeys()
{
    immutable float skillXl = (xlg - 40) / skillSort.length;
    foreach (x, ac; skillSort)
        groups[OptionGroup.gameKeys] ~= new SkillHotkeyOption(new Geom(
            20 + x * skillXl, 80, skillXl, 70), ac, keySkill[ac]);

    enum plusBelowSkills = 70f;
    auto fac = facKeys!0;
    fac.y += plusBelowSkills;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyForceLeft),
        fac.factory!HotkeyOption(keyForceRight),
    ];
    fac.y += fac.incrementY / 2;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyPause),
        fac.factory!HotkeyOption(keyRestart),
        fac.factory!HotkeyOption(keyStateLoad),
        fac.factory!HotkeyOption(keyStateSave),
    ];

    fac = facKeys!1;
    fac.y += plusBelowSkills;
    immutable xForBoolOptionsBelowHotkeys = fac.x;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keySpeedFast),
        fac.factory!HotkeyOption(keySpeedTurbo),
    ];
    fac.y += fac.incrementY / 2;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyFrameBackMany),
        fac.factory!HotkeyOption(keyFrameBackOne),
        fac.factory!HotkeyOption(keyFrameAheadOne),
        fac.factory!HotkeyOption(keyFrameAheadMany),
    ];

    fac = facKeys!2;
    fac.y += plusBelowSkills;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyNuke),
        fac.factory!HotkeyOption(keyGameExit),
    ];
    fac.y += fac.incrementY / 2;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(keyChat),
        fac.factory!HotkeyOption(keySpecTribe),
    ];

    enum belowAllGameKeys = 310f;
    fac = facLeft();
    fac.y = belowAllGameKeys;
    fac.xl = fac.xl - 10; // Mouse hover area shouldn't obscure other options
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!BoolOptionOneOrTwo(pausedAssign),
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
    auto fac = facKeys!0;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorLeft),
        fac.factory!HotkeyOption(keyEditorRight),
        fac.factory!HotkeyOption(keyEditorUp),
        fac.factory!HotkeyOption(keyEditorDown),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorSave),
        fac.factory!HotkeyOption(keyEditorSaveAs),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorCopy),
        fac.factory!HotkeyOption(keyEditorDelete),
        fac.factory!HotkeyOption(keyEditorGrid),
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
        fac.factory!HotkeyOption(keyEditorSelectAll),
        fac.factory!HotkeyOption(keyEditorSelectFrame),
        fac.factory!HotkeyOption(keyEditorSelectAdd),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorGroup),
        fac.factory!HotkeyOption(keyEditorUngroup),
        fac.factory!HotkeyOption(keyEditorBackground),
        fac.factory!HotkeyOption(keyEditorForeground),
        fac.factory!HotkeyOption(keyEditorMirror),
        fac.factory!HotkeyOption(keyEditorRotate),
        fac.factory!HotkeyOption(keyEditorDark),
    ];

    fac = facKeys!2;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorAddTerrain),
        fac.factory!HotkeyOption(keyEditorAddSteel),
        fac.factory!HotkeyOption(keyEditorAddHatch),
        fac.factory!HotkeyOption(keyEditorAddGoal),
        fac.factory!HotkeyOption(keyEditorAddHazard),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(keyEditorMenuConstants),
        fac.factory!HotkeyOption(keyEditorMenuTopology),
        fac.factory!HotkeyOption(keyEditorMenuLooks),
        fac.factory!HotkeyOption(keyEditorMenuSkills),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~=
        fac.factory!HotkeyOption(keyEditorExit);
}

void populateMenuKeys()
{
    Option[] grp;
    scope (exit)
        groups[OptionGroup.menuKeys] = grp;
    auto fac = facKeys!0;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuOkay),
        fac.factory!HotkeyOption(keyMenuEdit),
        fac.factory!HotkeyOption(keyMenuNewLevel),
        fac.factory!HotkeyOption(keyMenuExport),
        fac.factory!HotkeyOption(keyMenuDelete),
    ];
    fac.y += 20;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuExit),
    ];
    fac = facKeys!1;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuUpDir),
        fac.factory!HotkeyOption(keyMenuUpBy5),
        fac.factory!HotkeyOption(keyMenuUpBy1),
        fac.factory!HotkeyOption(keyMenuDownBy1),
        fac.factory!HotkeyOption(keyMenuDownBy5),
    ];
    fac = facKeys!2;
    grp ~= [
        fac.factory!HotkeyOption(keyMenuMainSingle),
        fac.factory!HotkeyOption(keyMenuMainNetwork),
        fac.factory!HotkeyOption(keyMenuMainReplays),
        fac.factory!HotkeyOption(keyMenuMainOptions),
    ];

    auto guiCol   = NumPickConfig();
    guiCol.max    = 240;
    guiCol.digits = 3;
    guiCol.hex    = true;
    guiCol.stepMedium = 0x10;
    guiCol.stepSmall  = 0x02;
    fac = facLeft();
    fac.xl = this.xlg - 40;
    fac.y  = 260;
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
