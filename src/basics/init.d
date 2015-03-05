module basics.init;

import std.string : toStringz;

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

    display = al_create_display(screen_windowed_x, screen_windowed_y);
    queue_DTODO_split_up = al_create_event_queue();

    al_set_window_title(display, Lang["main_name_of_the_game"].toStringz);

    al_install_keyboard();
    al_install_mouse();
    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();
    al_init_primitives_addon();

    default_new_bitmap_flags = al_get_new_bitmap_flags();

    hardware.mouse.initialize();

    graphic.color.initialize();
    graphic.textout.initialize();

    al_register_event_source(queue_DTODO_split_up, al_get_display_event_source(display));
    al_register_event_source(queue_DTODO_split_up, al_get_keyboard_event_source());

}



void deinitialize()
{
    graphic.textout.deinitialize();
    graphic.color.deinitialize();

    hardware.mouse.deinitialize();

    al_shutdown_font_addon();
    al_shutdown_ttf_addon();

    // maybe destroy display here

    basics.globconf.save();
    file.log.Log.deinitialize();

    al_stop_timer(timer);
    al_destroy_timer(timer);
    timer = null;
}
