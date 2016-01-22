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
import level.tilelib;
import lix;

static import file.log;

/*  void initialize(cmdargs);
 *  void deinitialize();
 *
 *      Routines to initialize and deinitialize most things before/after
 *      the main loop runs. Some have module constructors (static this()),
 *      but modules using Allegro need to be initialized from here.
 */

void initialize(in Cmdargs cmdargs)
{
    al_init();

    // set the timer to 60 Hz
    timer = al_create_timer(1.0 / basics.globals.ticksPerSecond);
    al_start_timer(timer);
    assert (timer);

    file.log.initialize();
    basics.globconf.load();
    basics.user.load();
    loadUserLanguageAndIfNotExistSetUserOptionToEnglish();

    hardware.display.setScreenMode(cmdargs);

    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();
    al_init_primitives_addon();

    defaultNewBitmapFlags = al_get_new_bitmap_flags();

    hardware.tharsis.initialize();
    hardware.keyboard.initialize();
    hardware.mouse.initialize();
    hardware.sound.initialize();

    graphic.color.initialize();
    graphic.textout.initialize();
    graphic.internal.initialize();
    game.physdraw.initialize(cmdargs.mode);

    hardware.mousecur.initialize();

    gui.initialize();

    level.tilelib.initialize();

    // comment this back in once we've built enet dynamically
    // DerelictENet.load();
}



void deinitialize()
{
    level.tilelib.deinitialize();

    gui.deinitialize();

    hardware.mousecur.deinitialize();

    core.memory.GC.collect();

    game.physdraw.deinitialize();
    graphic.internal.deinitialize();
    graphic.textout.deinitialize();
    graphic.color.deinitialize();

    core.memory.GC.collect();

    hardware.sound.deinitialize();
    hardware.mouse.deinitialize();
    hardware.keyboard.deinitialize();
    hardware.tharsis.deinitialize();

    al_shutdown_primitives_addon();
    al_shutdown_ttf_addon();
    al_shutdown_font_addon();
    al_shutdown_image_addon();

    hardware.display.deinitialize();

    basics.user.save();
    basics.globconf.save();
    file.log.deinitialize();

    al_stop_timer(timer);
    al_destroy_timer(timer);
    timer = null;

    al_uninstall_system();
}
