module basics.mainloop;

/* This class supervises all the major menus and browsers, game, and editor,
 * which are members of this class.
 *
 * To kill the game at any time, hit Shift + ESC.
 * This breaks straight out of the main loop. Unsaved data is lost.
 *
 * How to use this class: Instantiate, run main_loop() once, and then
 * exit the program when that function is done.
 */

import core.memory;

import basics.alleg5;
import basics.demo;
import hardware.display;
import hardware.keyboard;
import menu.mainmenu;
import menu.browsin;

static import gui;
static import hardware.mousecur;
static import hardware.sound;

class MainLoop {

public:

    void main_loop()
    {
        while (true) {
            immutable last_tick = al_get_timer_count(basics.alleg5.timer);
            calc();
            if (exit) break;
            draw();

            while (last_tick == al_get_timer_count(basics.alleg5.timer))
                al_rest(0.001);
        }
    }

private:

    bool exit;

    MainMenu main_menu;
    BrowserSingle brow_sin;

    Demo demo;



void
kill()
{
    if (main_menu) {
        gui.rm_elder(main_menu);
        main_menu = null;
    }
    if (brow_sin) {
        gui.rm_elder(brow_sin);
        brow_sin = null;
    }
    if (demo) {
        demo = null;
    }
    core.memory.GC.collect();
}



void
calc()
{
    hardware.display .calc();
    hardware.keyboard.calc();
    hardware.mouse   .calc();
    gui              .calc();

    exit = exit
     || hardware.display.get_display_close_was_clicked()
     || get_shift() && key_once(ALLEGRO_KEY_ESCAPE);

    if (exit) {
        kill();
    }
    else if (main_menu) {
        // no need to calc the menu, it's a GUI elder
        if (main_menu.goto_single) {
            kill();
            brow_sin = new BrowserSingle;
            gui.add_elder(brow_sin);
        }
        else if (main_menu.goto_network) {
            // DTODO: as long as networking isn't developed, this goes to demo
            kill();
            demo = new Demo;
        }
        else if (main_menu.exit_program) {
            kill();
            exit = true;
        }
    }
    else if (brow_sin) {
        if (brow_sin.goto_main_menu) {
            kill();
            main_menu = new MainMenu;
            gui.add_elder(main_menu);
        }
    }
    else if (demo) {
        demo.calc();
    }
    else {
        // program has just started, nothing exists yet
        main_menu = new MainMenu;
        gui.add_elder(main_menu);
    }

}



void
draw()
{
    // main_menu etc. are GUI Windows. Those have been added as elders and
    // are therefore supervised by module gui.root.

    if (demo) demo.draw();

    gui              .draw();
    hardware.mousecur.draw();
    hardware.sound   .draw();

    al_flip_display();
}

}
// end class
