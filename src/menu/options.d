module menu.options;

/* OptionsMenu: Menu with several tabs to set user options and global options.
 * It's OK to exceed 80 chars in this file.
 */

import std.algorithm;

import enumap;

import basics.globconf;
import basics.user;
import file.language;
import gui;
import graphic.color;
import hardware.mouse; // RMB to OK the window away
import menu.opthelp;

class OptionsMenu : Window {

    @property bool gotoMainMenu() const { return _gotoMainMenu; }
//  this(); -- exists, see below

private:

    bool _gotoMainMenu;

    TextButton okay;
    TextButton cancel;
    Frame explainer;

    enum OptionGroup {
        general, graphics, controls, gameKeys, editorKeys, menuKeys
    }

    Enumap!(OptionGroup, TextButton) groupButtons;
    Enumap!(OptionGroup, Option[]) groups;

    // extra references to what's in the groups, to update color immediately
    NumPick guiRed, guiGreen, guiBlue;



public this()
{
    super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg));
    windowTitle = Lang.optionTitle.transl;

    Geom okayCancelGeom(in int x)
    {
        return new Geom(x, 20, 100, 20, From.BOTTOM);
    }
    okay   = new TextButton(okayCancelGeom(-60), Lang.commonOk.transl);
    cancel = new TextButton(okayCancelGeom( 60), Lang.commonCancel.transl);
    addChildren(okay, cancel);
    okay  .hotkey = basics.user.keyMenuOkay;
    cancel.hotkey = basics.user.keyMenuExit;

    explainer = new Frame(new Geom(0, 60, xlg - 40, 40, From.BOTTOM));
    addChild(explainer);

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

    try               showGroup(basics.user.optionGroup.to!OptionGroup);
    catch (Exception) showGroup(OptionGroup.general);
}

protected override void calcSelf()
{
    if (okay.execute || hardware.mouse.mouseClickRight) {
        foreach (enumVal, group; groups)
            group.each!(option => option.saveValue);
        basics.user    .save();
        basics.globconf.save();
        _gotoMainMenu = true;
    }
    else if (cancel.execute) {
        graphic.color.initialize(); // throw away just-in-time computed colors
        _gotoMainMenu = true;
    }
    else if (guiRed.execute || guiGreen.execute || guiBlue.execute) {
        computeColors(guiRed.number, guiGreen.number, guiBlue.number);
        reqDraw();
        guiRed.undrawColor = guiGreen.undrawColor
                           = guiBlue .undrawColor = color.guiM;
    }
}



private:

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
    auto fac = facLeft();
    groups[OptionGroup.general] ~= [
        fac.factory!BoolOption(Lang.optionUserNameAsk.transl, &userNameAsk),
    ];

    fac = facRight();
    groups[OptionGroup.general] ~= [
        fac.factory!TextOption(Lang.optionUserName.transl, &userName),
    ];
}

void populateGraphics()
{
    auto fac = facRight();
    groups[OptionGroup.graphics] ~= [
        fac.factory!ResolutionOption(Lang.optionScreenResolution.transl, &screenResolutionX, &screenResolutionY),
        fac.factory!ResolutionOption(Lang.optionScreenWindowedRes.transl, &screenWindowedX, &screenWindowedY),
    ];
    auto guiCol   = NumPickConfig();
    guiCol.max    = 240;
    guiCol.digits = 3;
    guiCol.hex    = true;
    guiCol.stepMedium = 0x10;
    guiCol.stepSmall  = 0x02;
    groups[OptionGroup.graphics] ~= [
        fac.factory!NumPickOption(guiCol, Lang.optionGuiColorRed.transl, &guiColorRed),
        fac.factory!NumPickOption(guiCol, Lang.optionGuiColorGreen.transl, &guiColorGreen),
        fac.factory!NumPickOption(guiCol, Lang.optionGuiColorBlue.transl, &guiColorBlue),
    ];
    guiRed   = (cast (NumPickOption) groups[OptionGroup.graphics][$-3]).num;
    guiGreen = (cast (NumPickOption) groups[OptionGroup.graphics][$-2]).num;
    guiBlue  = (cast (NumPickOption) groups[OptionGroup.graphics][$-1]).num;
}

void populateControls()
{
    auto fac = facLeft();
    groups[OptionGroup.controls] ~= [
        fac.factory!BoolOption(Lang.optionScrollEdge.transl, &scrollEdge),
        fac.factory!BoolOption(Lang.optionScrollRight.transl, &scrollRight),
        fac.factory!BoolOption(Lang.optionScrollMiddle.transl, &scrollMiddle),
        fac.factory!BoolOption(Lang.optionReplayCancel.transl, &replayCancel),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.controls] ~= [
        fac.factory!BoolOption(Lang.optionAvoidBuilderQueuing.transl,   &avoidBuilderQueuing),
        fac.factory!BoolOption(Lang.optionAvoidBatterToExploder.transl, &avoidBatterToExploder),
        fac.factory!BoolOption(Lang.optionPriorityInvertRight.transl,   &priorityInvertRight),
        fac.factory!BoolOption(Lang.optionPriorityInvertMiddle.transl,  &priorityInvertMiddle),
    ];
    fac = facRight();
    auto cfg = NumPickConfig();
    cfg.max = 80;
    cfg.min =  1;
    groups[OptionGroup.controls] ~= [
        fac.factory!NumPickOption(cfg, Lang.optionMouseSpeed.transl, &mouseSpeed),
        fac.factory!NumPickOption(cfg, Lang.optionScrollSpeedEdge.transl, &scrollSpeedEdge),
        fac.factory!NumPickOption(cfg, Lang.optionScrollSpeedClick.transl, &scrollSpeedClick),
    ];
    cfg.min = 0;
    groups[OptionGroup.controls]
        ~=fac.factory!NumPickOption(cfg, Lang.optionReplayCancelAt.transl, &replayCancelAt);
}

void populateGameKeys()
{
    immutable float skillXl = (xlg - 40) / skillSort.length;
    foreach (x, ac; skillSort)
        groups[OptionGroup.gameKeys] ~= new SkillHotkeyOption(new Geom(
            20 + x * skillXl, 90, skillXl, 70), ac, &keySkill[ac]);

    auto fac = facKeys!0;
    fac.y += 80;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyForceLeft.transl, &keyForceLeft),
        fac.factory!HotkeyOption(Lang.optionKeyForceRight.transl, &keyForceRight),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.gameKeys] ~=
        fac.factory!HotkeyOption(Lang.optionKeyPause.transl, &keyPause);
    fac.y += fac.incrementY;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyRestart.transl, &keyRestart),
        fac.factory!HotkeyOption(Lang.optionKeyStateLoad.transl, &keyStateLoad),
        fac.factory!HotkeyOption(Lang.optionKeyStateSave.transl, &keyStateSave),
    ];

    fac = facKeys!1;
    fac.y += 80;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeySpawnintSlower.transl, &keySpawnintSlower),
        fac.factory!HotkeyOption(Lang.optionKeySpawnintFaster.transl, &keySpawnintFaster),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyFrameBackMany.transl, &keyFrameBackMany),
        fac.factory!HotkeyOption(Lang.optionKeyFrameBackOne.transl, &keyFrameBackOne),
        fac.factory!HotkeyOption(Lang.optionKeyFrameAheadOne.transl, &keyFrameAheadOne),
        fac.factory!HotkeyOption(Lang.optionKeyFrameAheadMany.transl, &keyFrameAheadMany),
        fac.factory!HotkeyOption(Lang.optionKeySpeedFast.transl, &keySpeedFast),
        fac.factory!HotkeyOption(Lang.optionKeySpeedTurbo.transl, &keySpeedTurbo),
    ];

    fac = facKeys!2;
    fac.y += 80;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyNuke.transl, &keyNuke),
        fac.factory!HotkeyOption(Lang.winGameTitle.transl, &keyGameExit),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyZoom.transl, &keyZoom),
        fac.factory!HotkeyOption(Lang.optionKeyChat.transl, &keyChat),
        fac.factory!HotkeyOption(Lang.optionKeySpecTribe.transl, &keySpecTribe),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.gameKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyScroll.transl, &keyScroll),
        fac.factory!HotkeyOption(Lang.optionKeyPriorityInvert.transl, &keyPriorityInvert),
    ];
}

void populateEditorKeys()
{
    auto fac = facKeys!0;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionEdLeft.transl, &keyEditorLeft),
        fac.factory!HotkeyOption(Lang.optionEdRight.transl, &keyEditorRight),
        fac.factory!HotkeyOption(Lang.optionEdUp.transl, &keyEditorUp),
        fac.factory!HotkeyOption(Lang.optionEdDown.transl, &keyEditorDown),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionEdCopy.transl, &keyEditorCopy),
        fac.factory!HotkeyOption(Lang.optionEdDelete.transl, &keyEditorDelete),
        fac.factory!HotkeyOption(Lang.optionEdGrid.transl, &keyEditorGrid),
        fac.factory!HotkeyOption(Lang.optionEdZoom.transl, &keyEditorZoom),
        fac.factory!HotkeyOption(Lang.optionEdHelp.transl, &keyEditorHelp),
    ];
    fac.y += fac.incrementY;
    fac.xl = this.xlg - 40;
    auto cfg = NumPickConfig();
    cfg.max = 96;
    cfg.min =  1;
    groups[OptionGroup.editorKeys] ~=
        fac.factory!NumPickOption(cfg, Lang.optionEdGridCustom.transl, &editorGridCustom);

    fac = facKeys!1;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionEdSelectAll.transl, &keyEditorSelectAll),
        fac.factory!HotkeyOption(Lang.optionEdSelectFrame.transl, &keyEditorSelectFrame),
        fac.factory!HotkeyOption(Lang.optionEdSelectAdd.transl, &keyEditorSelectAdd),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionEdBackground.transl, &keyEditorBackground),
        fac.factory!HotkeyOption(Lang.optionEdForeground.transl, &keyEditorForeground),
        fac.factory!HotkeyOption(Lang.optionEdMirror.transl, &keyEditorMirror),
        fac.factory!HotkeyOption(Lang.optionEdRotate.transl, &keyEditorRotate),
        fac.factory!HotkeyOption(Lang.optionEdDark.transl, &keyEditorDark),
        fac.factory!HotkeyOption(Lang.optionEdNoow.transl, &keyEditorNoow),
    ];

    fac = facKeys!2;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionEdMenuSize.transl, &keyEditorMenuSize),
        fac.factory!HotkeyOption(Lang.optionEdMenuVars.transl, &keyEditorMenuVars),
        fac.factory!HotkeyOption(Lang.optionEdMenuSkills.transl, &keyEditorMenuSkills),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionEdAddTerrain.transl, &keyEditorAddTerrain),
        fac.factory!HotkeyOption(Lang.optionEdAddSteel.transl, &keyEditorAddSteel),
        fac.factory!HotkeyOption(Lang.optionEdAddHatch.transl, &keyEditorAddHatch),
        fac.factory!HotkeyOption(Lang.optionEdAddGoal.transl, &keyEditorAddGoal),
        fac.factory!HotkeyOption(Lang.optionEdAddDeco.transl, &keyEditorAddDeco),
        fac.factory!HotkeyOption(Lang.optionEdAddHazard.transl, &keyEditorAddHazard),
    ];
    fac.y += fac.incrementY;
    groups[OptionGroup.editorKeys] ~=
        fac.factory!HotkeyOption(Lang.commonExit.transl, &keyEditorExit);
}

void populateMenuKeys()
{
    auto fac = facKeys!0;
    groups[OptionGroup.menuKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyMenuOkay.transl, &keyMenuOkay),
        fac.factory!HotkeyOption(Lang.optionKeyMenuEdit.transl, &keyMenuEdit),
        fac.factory!HotkeyOption(Lang.optionKeyMenuExport.transl, &keyMenuExport),
        fac.factory!HotkeyOption(Lang.optionKeyMenuDelete.transl, &keyMenuDelete),
        fac.factory!HotkeyOption(Lang.optionKeyMenuExit.transl, &keyMenuExit),
    ];
    fac = facKeys!1;
    groups[OptionGroup.menuKeys] ~= [
        fac.factory!HotkeyOption(Lang.optionKeyMenuUpDir.transl, &keyMenuUpDir),
        fac.factory!HotkeyOption(Lang.optionKeyMenuUpBy5.transl, &keyMenuUpBy5),
        fac.factory!HotkeyOption(Lang.optionKeyMenuUpBy1.transl, &keyMenuUpBy1),
        fac.factory!HotkeyOption(Lang.optionKeyMenuDownBy1.transl, &keyMenuDownBy1),
        fac.factory!HotkeyOption(Lang.optionKeyMenuDownBy5.transl, &keyMenuDownBy5),
    ];
    fac = facKeys!2;
    groups[OptionGroup.menuKeys] ~= [
        fac.factory!HotkeyOption(Lang.browserSingleTitle.transl, &keyMenuMainSingle),
        fac.factory!HotkeyOption(Lang.winLobbyTitle.transl, &keyMenuMainNetwork),
        fac.factory!HotkeyOption(Lang.browserReplayTitle.transl, &keyMenuMainReplays),
        fac.factory!HotkeyOption(Lang.optionTitle.transl, &keyMenuMainOptions),
    ];
}

}
// end class OptionsMenu
