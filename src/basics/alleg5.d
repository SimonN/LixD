module basics.alleg5;

public import allegro5.allegro;
public import allegro5.allegro_primitives;
public import allegro5.allegro_image;
public import allegro5.allegro_font;
public import allegro5.allegro_ttf;
public import allegro5.allegro_color;

import file.log;
import graphic.color;
import graphic.textout;

alias ALLEGRO_BITMAP* AlBit;
alias ALLEGRO_COLOR   AlCol;
alias ALLEGRO_FONT*   AlFont;

void initialize_allegro_5();
void deinitialize_allegro_5();

AlBit albit_create(int xl, int yl);

bool equals(AlCol lhs, AlCol rhs);

ALLEGRO_DISPLAY*     display;
ALLEGRO_EVENT_QUEUE* queue;
ALLEGRO_TIMER*       timer;

double timer_per_sec = 60.0;

int map_xl = 640;
int map_yl = 400;

int default_new_bitmap_flags;



void initialize_allegro_5()
{
    al_init();

    // set the timer to 60 Hz
    timer = al_create_timer(1.0 / timer_per_sec);
    al_start_timer(timer);
    assert (timer);

    file.log.Log.initialize();

    display    = al_create_display(map_xl, map_yl);
    queue      = al_create_event_queue();

    al_set_window_title(display, "Nagetier, Allegro 5.");

    al_install_keyboard();
    al_install_mouse();
    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();
    al_init_primitives_addon();

    default_new_bitmap_flags = al_get_new_bitmap_flags();

    graphic.color.initialize();
    graphic.textout.initialize();

    al_register_event_source(queue, al_get_display_event_source(display));
    al_register_event_source(queue, al_get_keyboard_event_source());
    al_register_event_source(queue, al_get_mouse_event_source());
}



void deinitialize_allegro_5()
{
    graphic.textout.deinitialize();
    graphic.color.deinitialize();

    al_shutdown_font_addon();
    al_shutdown_ttf_addon();

    // maybe destroy display here

    file.log.Log.deinitialize();

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



bool equals(AlCol lhs, AlCol rhs)
{
    ubyte lr, lg, lb, la, rr, rg, rb, ra;
    al_unmap_rgba(lhs, &lr, &lg, &lb, &la);
    al_unmap_rgba(rhs, &rr, &rg, &rb, &ra);
    return lr == rr && lg == rg && lb == rb && la == ra;
}



template temp_target(string bitmap)
{
    // set the bitmap as target, and reset the target back to what it was
    // at the end of the caller's current scope
    const char[] temp_target = "
    AlBit last_target_before_" ~ bitmap[0] ~ " = al_get_target_bitmap();
    scope (exit) al_set_target_bitmap(last_target_before_" ~ bitmap[0] ~ ");
    al_set_target_bitmap(" ~ bitmap  ~ ");";
}



template temp_lock(string bitmap)
{
    // lock the bitmap; if locking was succesful, unlock at end of scope
    const char[] temp_lock = "
    ALLEGRO_LOCKED_REGION* lock_" ~ bitmap[0] ~ " = al_lock_bitmap("
     ~ bitmap ~ ", al_get_bitmap_format("
     ~ bitmap ~ "), ALLEGRO_LOCK_READWRITE);
    scope (exit) if (lock_" ~ bitmap[0] ~ ") al_unlock_bitmap(" ~bitmap~ ");";
}
