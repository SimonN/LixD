public import allegro5.allegro;
public import allegro5.allegro_primitives;
public import allegro5.allegro_image;
public import allegro5.allegro_font;
public import allegro5.allegro_ttf;
public import allegro5.allegro_color;

alias ALLEGRO_COLOR AlCol;

ALLEGRO_DISPLAY*     display;
ALLEGRO_EVENT_QUEUE* queue;

int map_xl = 640;
int map_yl = 400;

void initialize_allegro_5();
void deinitialize_allegro_5();



void initialize_allegro_5()
{
    al_init();

    display = al_create_display(map_xl, map_yl);
    queue   = al_create_event_queue();

    al_install_keyboard();
    al_install_mouse();
    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();
    al_init_primitives_addon();

    al_register_event_source(queue, al_get_display_event_source(display));
    al_register_event_source(queue, al_get_keyboard_event_source());
    al_register_event_source(queue, al_get_mouse_event_source());
}



void deinitialize_allegro_5()
{
}
