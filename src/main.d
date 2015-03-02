/*
 * Lix
 *
 * This is written in the D Programming Language with the Allegro 5 library.
 *
 * See doc/build.txt for information about how to build from source.
 */

import basics.alleg5;
import basics.mainloop;

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
