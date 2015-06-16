/* Lix
 *
 * An interactive rodent simulation, i.e., a game like Lemmings.
 *
 * Written by Simon N., released to the public domain via the CC0 puplic
 * domain dedication. Read doc/copying.txt for further information.
 *
 * To build, run dub. If you don't have dub installed, read doc/build.txt
 * for a detailed explanation of the build process. The game is written in
 * the D Programming Language and it uses the Allegro 5 library.
 */

import basics.alleg5;
import basics.cmdargs;
import basics.init;
import basics.mainloop;

void main(string[] args)
{
    Cmdargs cmdargs = new Cmdargs(args);

    if (cmdargs.mode == Runmode.PRINT_AND_EXIT) {
        cmdargs.print_noninteractive_output();
    }
    else al_run_allegro({
        basics.init.initialize(cmdargs);

        MainLoop ml = new MainLoop();
        ml.main_loop();
        destroy(ml);

        basics.init.deinitialize();
        return 0;
    });
}
