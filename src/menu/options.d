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
import menu.opthelp;

class OptionsMenu : Window {

    @property bool gotoMainMenu() const { return _gotoMainMenu; }
//  this(); -- exists, see below

private:

    bool _gotoMainMenu;

    enum : float {
        checkX   =  20,
        checkNx  =  60,
        otherX   = 300,
        otherNx  = 460,

        buttonXl = 140,
        keyXl    =  70,
        frameY   = 320,
        frameYl  = 100,

        keyB1    =  20,
        keyT1    =  40 + keyXl,
        keyB2    = 220,
        keyT2    = 240 + keyXl,
        keyB3    = 420,
        keyT3    = 440 + keyXl,
    }

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
    if (okay.execute) {
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

private void populateOptionGroups()
{
    auto fac = OptionFactory(20, 100, 200, 20);
    fac.incrementY = 30;

    groups[OptionGroup.general] = [
        fac.factory!CheckboxOption(Lang.optionUserNameAsk.transl, &userNameAsk),
    ];
}

}
// end class OptionsMenu
