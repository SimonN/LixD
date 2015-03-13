module basics.init;

import basics.alleg5;
import basics.globals;
import basics.globconf;
import file.language;
import graphic.color;
import graphic.gralib;
import hardware.display;
import hardware.mouse;

// routines to initialize and deinitialize most things before/after
// the main loop runs. Some things have module constructors (static this()),
// but modules using Allegro need to be initialized from here.

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

    import graphic.textout;
    al_draw_text(djvu_m, color.white, 20, 20, ALLEGRO_ALIGN_LEFT,
     "Loading images. This may take 5 to 10 seconds.");
    al_flip_display();

    graphic.gralib.initialize();
}



void deinitialize()
{
    graphic.gralib.deinitialize();

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
