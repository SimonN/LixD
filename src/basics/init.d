module basics.init;

import core.memory;

import derelict.enet.enet;

import basics.alleg5;
import basics.cmdargs;
import basics.globals;
import basics.globconf;
import basics.user;
import file.language;
import graphic.color;
import graphic.internal;
import gui;
import hardware.display;
import hardware.mouse;
import tile.tilelib;
import lix;

static import file.log;

/*  void initialize(cmdargs);
 *  void deinitialize();
 *      Routines to initialize and deinitialize most things before/after
 *      the main loop runs. Some have module constructors (static this()),
 *      but modules using Allegro need to be initialized from here.
 */

void initialize(in Cmdargs cmdargs)
{
    immutable ia = cmdargs.mode == Runmode.INTERACTIVE;
    if (ia) basics.alleg5.initializeInteractive();
    else    basics.alleg5.initializeVerify();

            file.log.initialize();
    if (ia) basics.globconf.load();
    if (ia) basics.user.load();
    if (ia) loadUserLanguageAndIfNotExistSetUserOptionToEnglish();
    if (ia) hardware.display.setScreenMode(cmdargs);

            al_init_image_addon();
            al_init_font_addon();
            al_init_ttf_addon();
            al_init_primitives_addon();
            hardware.tharsis.initialize();
    if (ia) hardware.keyboard.initialize();
    if (ia) hardware.mouse.initialize();
    if (ia) hardware.sound.initialize();

            graphic.color   .initialize();
    if (ia) graphic.textout .initialize();
            graphic.internal.initialize(cmdargs.mode);
            game   .physdraw.initialize(cmdargs.mode);

    if (ia) hardware.mousecur.initialize();
    if (ia) gui.initialize();
            tile.tilelib.initialize();
    // comment this back in once we've built enet dynamically
    // DerelictENet.load();
}

void deinitialize()
{
    hardware.tharsis.deinitialize();
    basics.user.save();
    basics.globconf.save();
}
