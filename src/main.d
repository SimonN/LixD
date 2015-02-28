import alleg5;
import mainloop;

void main()
{
	al_run_allegro(
	{
        initialize_allegro_5();

        MainLoop ml = new MainLoop();
        ml.main_loop();

        deinitialize_allegro_5();
        return 0;
    });
}
