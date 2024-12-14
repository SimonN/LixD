module basics.init;

import derelict.enet.enet;

import basics.alleg5;
import basics.cmdargs;
import file.option;
import basics.resol;
import file.option;
import file.language;
import file.filename;
import file.trophy;
import gui.context;
import graphic.color;
import graphic.internal;
import hardware.keyboard;
import hardware.sound;
import hardware.music;
import hardware.tharsis;
import physics.mask;
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
    try {
        file.filename.initialize(); // The virtual filesystem. For logging.
        file.log.initialize(); // Even without init, you may call log methods.

        initializeEverythingExceptLogfileAndDisplay(cmdargs.mode);
        if (cmdargs.mode == Runmode.INTERACTIVE) {
            // This initializes tiles, GUI context, many other things.
            changeResolutionBasedOnCmdargsThenUserFile(cmdargs);
        }
    }
    catch (Throwable uncaught) {
        if (cmdargs.mode == Runmode.INTERACTIVE) {
            file.log.showMessageBoxOnWindows(uncaught);
        }
        file.log.logThenRethrowToTerminate(uncaught);
    }
}

void initializeForUnittest()
{
    file.filename.initialize();
    initializeEverythingExceptLogfileAndDisplay(Runmode.VERIFY);
    // The log file isn't used during unittest. Logging lands in stdout.
}

private void initializeEverythingExceptLogfileAndDisplay(in Runmode mode)
{
    // ph == need physics, may or may not need graphics.
    // gr == need graphics, may or may not need physics.
    immutable ia = mode == Runmode.INTERACTIVE;
    immutable ph = mode == Runmode.VERIFY || ia;
    immutable gr = mode == Runmode.EXPORT_IMAGES || ia;

    if (ia) basics.alleg5.initializeInteractive();
    else    basics.alleg5.initializeNoninteractive();

    loadUserOptions();
    loadTrophies();

    // We need the language (at least English) in every runmode:
    // Verifier explains results, image export prints lixes and spawn interval.
    loadUserLanguageAndIfNotExistSetUserOptionToEnglish();

    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();
    al_init_primitives_addon();
    hardware.tharsis.initialize();

    if (ia) {
        hardware.keyboard.initialize();
        // Mouse will be (re)initialized whenever we change resolution.
    }
    graphic.color.initialize();
    if (ph) {
        physics.mask.initialize();
        // Sound will be lazily initialized when required.
    }

    if (! ia) {
        // We need tiles and some graphics in any case
        graphic.internal.initialize(mode);
        if (gr) {
            assert (mode == Runmode.EXPORT_IMAGES);
            // For the export-image unittest. This keeps all init here.
            gui.context.initialize(640, 480);
        }
    }
}

/*
 * See also the resolution functions in basics.resol.
 * They initialize and deinitialize several other modules.
 */
void deinitialize()
{
    // If we don't abort music, Linux Lix crashes on exit.
    // Several places lead into basics.init.deinitialize: Clicking the X
    // in the windowmanager-window's corner, pressing Shift+ESC, exiting
    // from the main menu.
    // Sending sigint or sigterm to Lix doesn't go here, instead crashes.
    // Maybe I should register deinitialize by atexit or install signal
    // handlers?
    hardware.music.deinitialize();

    // We don't deinitialize much. It should be okay to leak at end of
    // application on any modern OS, it makes for faster exiting.
    hardware.tharsis.deinitialize();
    saveUserOptions();
    saveTrophies();
}

void deinitializeAfterUnittest()
{
    gui.context.deinitialize();
    tile.tilelib.deinitialize();
    graphic.internal.deinitialize();
    hardware.tharsis.deinitialize();
}
