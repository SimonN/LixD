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
AlBit                pre_screen;

ALLEGRO_EVENT_QUEUE* queue;

int map_xl = 640;
int map_yl = 400;

int default_new_bitmap_flags;



void initialize_allegro_5()
{
    al_init();

    display    = al_create_display(map_xl, map_yl);
    pre_screen = albit_create     (map_xl, map_yl);
    queue      = al_create_event_queue();

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
}



AlBit albit_create(int xl, int yl)
{
    al_set_new_bitmap_flags(default_new_bitmap_flags
     | ALLEGRO_VIDEO_BITMAP
     &~ ALLEGRO_MEMORY_BITMAP);
    scope (exit) al_set_new_bitmap_flags(default_new_bitmap_flags);

    return al_create_bitmap(xl, yl);
}
