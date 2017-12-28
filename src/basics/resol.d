module basics.resol;

/*
 * Call all modules that do something with resolution, so that those modules
 * do not have to depend on each other as much.
 */

import basics.cmdargs;
import basics.user; // don't always change resolution if already OK
import game.physdraw;
import graphic.internal;
import gui.context;
import gui.root;
import hardware.display;
import hardware.mousecur;
import tile.tilelib;

// //i means not called because not yet implemented. It should be implemented
// before we release changing resolution.

void changeResolutionBasedOnCmdargsThenUserFile(const(Cmdargs) cmdargs)
{
    hardware.mousecur.deinitialize();
    tile.tilelib.deinitialize();
    game.physdraw.deinitialize();
    graphic.internal.deinitialize();
    gui.root.deinitialize();
    gui.context.deinitialize();

    hardware.display.setScreenMode(cmdargs);

    gui.context.initialize(displayXl, displayYl);
    gui.root.initialize(displayXl, displayYl);
    graphic.internal.initialize(cmdargs.mode);
    graphic.internal.initializeScale(gui.stretchFactor);
    game.physdraw.initialize();
    tile.tilelib.initialize();
    hardware.mousecur.initialize();
}

void changeResolutionBasedOnUserFileAlone()
{
    if (weHaveAReasonToChange)
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
