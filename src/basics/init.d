module basics.init;

import basics.alleg5;
import basics.globals;
import basics.globconf;
import file.language;
import graphic.color;
import hardware.mouse;

// routines to initialize and deinitialize most things before/after
// the main loop runs

void initialize();
void deinitialize();



void initialize()
{
    al_init();

    // set the timer to 60 Hz
    timer = al_create_timer(1.0 / basics.globals.ticks_per_sec);
    al_start_timer(timer);
    assert (timer);

    file.log.Log.initialize();
    basics.globconf.load();
    // load user config here
    Lang.switch_to_language(Lang.Language.ENGLISH); // DTODO: read user file

    hardware.display.set_screen_mode(true);

    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();
    al_init_primitives_addon();

    default_new_bitmap_flags = al_get_new_bitmap_flags();

    hardware.keyboard.initialize();
    hardware.mouse.initialize();

    graphic.color.initialize();
    graphic.textout.initialize();

    // load all graphics here, because we can print text already
}



void deinitialize()
{
    graphic.textout.deinitialize();
    graphic.color.deinitialize();

    hardware.mouse.deinitialize();
    hardware.keyboard.deinitialize();

    al_shutdown_primitives_addon();
    al_shutdown_ttf_addon();
    al_shutdown_font_addon();
    al_shutdown_image_addon();

    hardware.display.deinitialize();

    basics.globconf.save();
    file.log.Log.deinitialize();

    al_stop_timer(timer);
    al_destroy_timer(timer);
    timer = null;

    al_uninstall_system();
}
