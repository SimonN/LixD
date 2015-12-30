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

public override void calcSelf()
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

private void showGroup(in OptionGroup gr)
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

private void populateOptionGroups()
{
    enum optionsBeginY  = 100;
    enum checkboxRowX   =  20;
    enum longButtonRowX = 280;

    auto facLeft()  { return OptionFactory(checkboxRowX,   optionsBeginY,            longButtonRowX - checkboxRowX); }
    auto facRight() { return OptionFactory(longButtonRowX, optionsBeginY, this.xlg - longButtonRowX - checkboxRowX); }

    auto fac = facLeft();
    groups[OptionGroup.general] ~= [
        fac.factory!BoolOption(Lang.optionUserNameAsk.transl, &userNameAsk),
    ];

    fac = facRight();
    groups[OptionGroup.general] ~= [
        fac.factory!TextOption(Lang.optionUserName.transl, &userName),
    ];


    fac = facRight();
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

}
// end class OptionsMenu
