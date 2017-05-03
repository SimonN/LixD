module basics.init;

import derelict.enet.enet;

import basics.alleg5;
import basics.cmdargs;
import basics.globals;
import basics.globconf;
import basics.user;
import file.language;
import file.filename;
import game.mask;
import game.physdraw;
import graphic.color;
import graphic.internal;
import gui.context;
import gui.root;
import hardware.display;
import hardware.keyboard;
import hardware.mouse;
import hardware.mousecur;
import hardware.sound;
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
    if (ia) hardware.display.setScreenMode(cmdargs);
    if (ia) hardware.keyboard.initialize();
    if (ia) hardware.mouse.initialize();
    if (ia) hardware.sound.initialize();

            graphic.color.initialize();
            graphic.internal.initialize(cmdargs.mode);
    if (ph) game.mask.initialize();

    if (ia) game.physdraw.initialize();
    if (ia) hardware.mousecur.initialize();
    if (ia) initializeGUI();
            tile.tilelib.initialize();
}

void deinitialize()
{
    // We don't deinitialize much. It should be okay to leak at end of
    // application on any modern OS, it makes for faster exiting.
    hardware.tharsis.deinitialize();
    basics.user.save();
    basics.globconf.save();
}

private void initializeGUI()
{
    assert (display);
    immutable xl = al_get_display_width(display);
    immutable yl = al_get_display_height(display);
    gui.context.initialize(xl, yl);
    gui.root.initialize(xl, yl);
    graphic.internal.initializeScale(gui.stretchFactor);
}
