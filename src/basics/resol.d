module basics.resol;

/*
 * Call all modules that do something with resolution, so that those modules
 * do not have to depend on each other as much.
 */

import basics.cmdargs;
import file.option; // don't always change resolution if already OK
import graphic.internal;
import gui.context;
import gui.root;
import hardware.display;
import hardware.mouse;
import hardware.mousecur;
import physics.physdraw;
import tile.tilelib;

private bool _cmdargsForcedResolutionThusNeverChangeThat = false;

void changeResolutionBasedOnCmdargsThenUserFile(const(Cmdargs) cmdargs)
{
    hardware.mousecur.deinitialize();
    hardware.mouse.deinitialize();
    tile.tilelib.deinitialize();
    physics.physdraw.deinitialize();
    graphic.internal.deinitialize();
    gui.root.deinitialize();
    gui.context.deinitialize();

    hardware.display.setScreenMode(cmdargs);
    if (cmdargs.forceSomeDisplayMode)
        _cmdargsForcedResolutionThusNeverChangeThat = true;

    gui.context.initialize(displayXl, displayYl);
    gui.root.initialize(displayXl, displayYl);
    graphic.internal.initialize(cmdargs.mode);
    graphic.internal.initializeScale(gui.stretchFactor);
    physics.physdraw.initialize();
    hardware.mouse.initialize();
    hardware.mousecur.initialize();
}

void changeResolutionBasedOnUserFileAlone()
{
    if (weHaveAReasonToChange && ! _cmdargsForcedResolutionThusNeverChangeThat)
        changeResolutionBasedOnCmdargsThenUserFile(new Cmdargs([]));
}

private bool weHaveAReasonToChange()
{
    if (! display)
        return true;
    if (displayTryMode.mode == ScreenMode.softwareFullscreen
        && currentMode.mode == ScreenMode.softwareFullscreen)
        return false;
    return displayTryMode != currentMode;
}
