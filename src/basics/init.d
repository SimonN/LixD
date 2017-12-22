module basics.init;

import derelict.enet.enet;

import basics.alleg5;
import basics.cmdargs;
import basics.globconf;
import basics.resol;
import basics.user;
import file.language;
import file.filename;
import game.mask;
import graphic.color;
import hardware.keyboard;
import hardware.mouse;
import hardware.sound;
import hardware.music;
import hardware.tharsis;
import tile.tilelib;

static import file.log;

/*  void initialize(cmdargs);
 *  void deinitialize();
 *      Routines to initialize and deinitialize most things before/after
 *      the main loop runs. Some have module constructors (static this()),
 *      but modules using Allegro need to be initialized from here.
 */

void initialize(in Cmdargs cmdargs)
{
    // ph == need physics, may or may not need graphics.
    // gr == need graphics, may or may not need physics.
    immutable ia = cmdargs.mode == Runmode.INTERACTIVE;
    immutable ph = cmdargs.mode == Runmode.VERIFY || ia;
    immutable gr = cmdargs.mode == Runmode.EXPORT_IMAGES || ia;

    if (ia) basics.alleg5.initializeInteractive();
    else    basics.alleg5.initializeNoninteractive();

            file.filename.initialize(); // the virtual filesystem
            file.log.initialize();
    if (gr) basics.globconf.load();
    if (gr) basics.user.load();
    if (gr) loadUserLanguageAndIfNotExistSetUserOptionToEnglish();

            al_init_image_addon();
            al_init_font_addon();
            al_init_ttf_addon();
            al_init_primitives_addon();
            hardware.tharsis.initialize();
    if (ia) hardware.keyboard.initialize();
    if (ia) hardware.mouse.initialize();
    if (ia) hardware.sound.initialize();
            graphic.color.initialize();
    if (ph) game.mask.initialize();

    if (ia) changeResolutionBasedOnCmdargsThenUserFile(cmdargs); // inits tiles
    else    tile.tilelib.initialize(); // we need these in any case
}

/*
 * See also the resolution functions in basics.resol.
 * They initialize and deinitialize several other modules.
 */

void deinitialize()
{
    // We don't deinitialize much. It should be okay to leak at end of
    // application on any modern OS, it makes for faster exiting.
    hardware.tharsis.deinitialize();
    basics.user.save();
    basics.globconf.save();

    // If we don't abort music, Linux Lix crashes on exit.
    // Several places lead into basics.init.deinitialize: Clicking the X
    // in the windowmanager-window's corner, pressing Shift+ESC, exiting
    // from the main menu.
    // Sending sigint or sigterm to Lix doesn't go here, instead crashes.
    // Maybe I should register deinitialize by atexit or install signal
    // handlers?
    hardware.music.deinitialize();
}
