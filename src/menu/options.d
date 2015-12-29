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
import hardware.mouse; // RMB to OK the window away
import menu.opthelp;

class OptionsMenu : Window {

    @property bool gotoMainMenu() const { return _gotoMainMenu; }
//  this(); -- exists, see below

private:

    bool _gotoMainMenu;

    TextButton okay;
    TextButton cancel;

    enum OptionGroup {
        general, graphics, sound, controls, gameKeys, editorKeys, menuKeys
    }

    Enumap!(OptionGroup, Option[]) groups;



public this()
{
    super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg), Lang.optionTitle.transl);
    okay   = new TextButton(new Geom(-60, 20, 100, 20, From.BOTTOM), Lang.commonOk.transl);
    cancel = new TextButton(new Geom( 60, 20, 100, 20, From.BOTTOM), Lang.commonCancel.transl);
    addChildren(okay, cancel);

    populateOptionGroups();
    foreach (enumVal, group; groups)
        foreach (option; group) {
            addChild(option);
            option.loadValue();
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
        _gotoMainMenu = true;
    }
}

private void showGroup(in OptionGroup gr)
{
    basics.user.optionGroup = gr;
    foreach (enumVal, group; groups) {
        if (enumVal == gr) group.each!(opt => opt.show);
        else               group.each!(opt => opt.hide);
    }
}

int debugging = 5;

private void populateOptionGroups()
{
    enum optionsBeginY  = 100;
    enum checkboxRowX   =  20;
    enum longButtonRowX = 280;

    auto fac = OptionFactory(checkboxRowX, optionsBeginY,
                longButtonRowX - checkboxRowX);
    groups[OptionGroup.general] ~= [
        fac.factory!BoolOption(Lang.optionUserNameAsk.transl, &userNameAsk),
    ];

    fac = OptionFactory(longButtonRowX, optionsBeginY,
            this.xlg - longButtonRowX - checkboxRowX);
    groups[OptionGroup.general] ~= [
        fac.factory!TextOption(Lang.optionUserName.transl, &userName),
    ];

    // DTODO: move this to different OptionGroup once tabs are implemented
    groups[OptionGroup.general] ~= [
        fac.factory!ResolutionOption(Lang.optionScreenResolution.transl,
            &screenResolutionX, &screenResolutionY),
        fac.factory!ResolutionOption(Lang.optionScreenWindowedRes.transl,
            &screenWindowedX, &screenWindowedY),
        fac.factory!NumberOption("wurst Test", &debugging),
    ];

}

}
// end class OptionsMenu
