module basics.mainloop;

/* This class supervises all the major menus and browsers, game, and editor,
 * which are members of this class.
 *
 * To kill the game at any time, hit Shift + ESC.
 * This breaks straight out of the main loop. Unsaved data is lost.
 *
 * How to use this class: Instantiate, run mainLoop() once, and then
 * exit the program when that function is done.
 */

import core.memory;

import basics.alleg5;
import basics.bench;
import basics.demo;
import game.game;
import file.log; // logging uncaught Exceptions
import hardware.display;
import hardware.keyboard;
import menu.mainmenu;
import menu.browsin;

static import gui;
static import hardware.mousecur;
static import hardware.sound;

class MainLoop {

public:

    void mainLoop()
    {
        try while (true) {
            immutable last_tick = al_get_timer_count(basics.alleg5.timer);
            calc();
            if (exit) break;
            draw();

            while (last_tick == al_get_timer_count(basics.alleg5.timer))
                al_rest(0.001);
        }
        catch (Throwable thr) {
            // Uncaught exceptions, assert errors, and assert (false) should
            // fly straight out of main and terminate the program. Since
            // Windows users won't run the game from a shell, they should
            // retrieve the error message from the logfile, in addition.
            // In a release build, assert (false) crashes instead of throwing.
            logf("%s:%d:", thr.file, thr.line);
            log(thr.msg);
            log(thr.info.toString());
            throw thr;
        }
        kill();
    }

private:

    bool exit;

    MainMenu mainMenu;
    BrowserSingle browSin;

    Game game;

    Demo demo;
    Benchmark bench;



void
kill()
{
    if (game) {
        destroy(game);
        game = null;
    }
    if (mainMenu) {
        gui.rmElder(mainMenu);
        mainMenu = null;
    }
    if (browSin) {
        gui.rmElder(browSin);
        destroy(browSin); // DTODO: check what is best here. There is a
                           // Torbit to be destroyed in the browser's preview.
        browSin = null;
    }
    if (demo) {
        demo = null;
    }
    if (bench) {
        bench = null;
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
        || hardware.display.displayCloseWasClicked()
        || shiftHeld() && keyTapped(ALLEGRO_KEY_ESCAPE);

    if (exit) {
        return;
    }
    else if (mainMenu) {
        // no need to calc the menu, it's a GUI elder
        if (mainMenu.gotoSingle) {
            kill();
            browSin = new BrowserSingle;
            gui.addElder(browSin);
        }
        else if (mainMenu.gotoNetwork) {
            // DTODO: as long as networking isn't developed, this goes to demo
            kill();
            demo = new Demo;
        }
        else if (mainMenu.gotoBench) {
            kill();
            bench = new Benchmark;
        }
        else if (mainMenu.exitProgram) {
            exit = true;
        }
    }
    else if (browSin) {
        if (browSin.gotoGame) {
            auto lv = browSin.level;
            auto fn = browSin.filename;
            kill();
            game = new Game(lv, fn);
        }
        else if (browSin.gotoMainMenu) {
            kill();
            mainMenu = new MainMenu;
            gui.addElder(mainMenu);
        }
    }
    else if (game) {
        game.calc();
        if (game.gotoMenu) {
            kill();
            browSin = new BrowserSingle;
            gui.addElder(browSin);
        }
    }
    else if (demo) {
        demo.calc();
    }
    else if (bench) {
        bench.calc();
        if (bench.exit) {
            kill();
            mainMenu = new MainMenu;
            gui.addElder(mainMenu);
        }
    }
    else {
        // program has just started, nothing exists yet
        mainMenu = new MainMenu;
        gui.addElder(mainMenu);
    }

}



void
draw()
{
    // mainMenu etc. are GUI Windows. Those have been added as elders and
    // are therefore supervised by module gui.root.

    if (game) game.draw();
    if (demo) demo.draw();
    if (bench) bench.draw();

    gui              .draw();
    hardware.mousecur.draw();
    hardware.sound   .draw();

    flip_display();
}

}
// end class
