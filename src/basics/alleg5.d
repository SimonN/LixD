public import allegro5.allegro;
public import allegro5.allegro_primitives;
public import allegro5.allegro_image;
public import allegro5.allegro_font;
public import allegro5.allegro_ttf;
public import allegro5.allegro_color;

alias ALLEGRO_BITMAP* AlBit;
alias ALLEGRO_COLOR   AlCol;

void initialize_allegro_5();
void deinitialize_allegro_5();

AlBit albit_create(int xl, int yl);

ALLEGRO_DISPLAY*     display;
ALLEGRO_EVENT_QUEUE* queue;
ALLEGRO_TIMER*       timer;

int map_xl = 640;
int map_yl = 400;

int default_new_bitmap_flags;



void initialize_allegro_5()
{
    al_init();

    // set the timer to 60 Hz
    timer = al_create_timer(1.0 / 60.0);
    al_start_timer(timer);
    assert (timer);

    display    = al_create_display(map_xl, map_yl);
    queue      = al_create_event_queue();

    al_set_window_title(display, "Slowpoke likes A5.");

    al_install_keyboard();
    al_install_mouse();
    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();
    al_init_primitives_addon();

    default_new_bitmap_flags = al_get_new_bitmap_flags();

    al_register_event_source(queue, al_get_display_event_source(display));
    al_register_event_source(queue, al_get_keyboard_event_source());
    al_register_event_source(queue, al_get_mouse_event_source());
}



void deinitialize_allegro_5()
{
    al_stop_timer(timer);
    al_destroy_timer(timer);
    timer = null;
}



AlBit albit_create(int xl, int yl)
{
    al_set_new_bitmap_flags(default_new_bitmap_flags
     | ALLEGRO_VIDEO_BITMAP
     &~ ALLEGRO_MEMORY_BITMAP);
    scope (exit) al_set_new_bitmap_flags(default_new_bitmap_flags);

    AlBit ret = al_create_bitmap(xl, yl);

    assert (ret);
    assert (al_get_bitmap_width (ret) == xl);
    assert (al_get_bitmap_height(ret) == yl);

    return ret;
}



template temp_target(string bitmap)
{
    const char[] temp_target = "
    AlBit last_target_before_" ~ bitmap[0] ~ " = al_get_target_bitmap();
    scope (exit) al_set_target_bitmap(last_target_before_" ~ bitmap[0] ~ ");
    al_set_target_bitmap(" ~ bitmap  ~ ");";
}
