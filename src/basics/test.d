import alleg5;

void run_test();



void run_test()
{
    bool exit = false;
    while(!exit)
    {
        ALLEGRO_EVENT event;
        while(al_get_next_event(alleg5.queue, &event))
        {
            switch(event.type)
            {
                case ALLEGRO_EVENT_DISPLAY_CLOSE:
                {
                    exit = true;
                    break;
                }
                case ALLEGRO_EVENT_KEY_DOWN:
                {
                    switch(event.keyboard.keycode)
                    {
                        case ALLEGRO_KEY_ESCAPE:
                        {
                            exit = true;
                            break;
                        }
                        default:
                    }
                    break;
                }
                case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
                {
                    exit = true;
                    break;
                }
                default:
            }
        }

        al_clear_to_color(AlCol(0.5, 0.25, 0.125, 1));
        // al_draw_bitmap(bmp, 50, 50, 0);
        al_draw_triangle(20, 20, 300, 30, 200, 200, AlCol(1, 1, 1, 1), 4);
        // al_draw_text(font, ALLEGRO_COLOR(1, 1, 1, 1), 70, 40, ALLEGRO_ALIGN_CENTRE, "Hello!");
        al_flip_display();
    }
}
