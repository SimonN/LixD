/*
 * Lix
 * An interactive rodent simulation, i.e., a game like
 *
 * This is written in the D Programming Language with the Allegro 5 library.
 * The build is manged by the dub build system.
 *
 * See doc/build.txt for information about how to build from source.
 *
 * See doc/copying.txt for the public domain dedication of Lix via CC0.
 */

import basics.alleg5;
import basics.init;
import basics.mainloop;

void main()
{
    al_run_allegro(
    {
        basics.init.initialize();

        MainLoop ml = new MainLoop();
        ml.main_loop();
        clear(ml);

        basics.init.deinitialize();
        return 0;
    });
}
