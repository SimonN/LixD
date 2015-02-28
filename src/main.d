import alleg5;
import test;

void main()
{
	al_run_allegro(
	{
        initialize_allegro_5();
        run_test();
        deinitialize_allegro_5();
        return 0;
    });
}
