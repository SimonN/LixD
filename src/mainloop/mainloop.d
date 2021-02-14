module mainloop.mainloop;

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

import basics.cmdargs;
import basics.alleg5;
import basics.globals;
import file.filename; // running levels from the command-line
import file.log; // logging uncaught Exceptions
import hardware.display;
import hardware.keyboard;
import mainloop.topscrn;

static import gui;
static import hardware.keyboard;
static import hardware.mouse;
static import hardware.mousecur;
static import hardware.sound;
static import mainloop.firstscr;

class MainLoop {
private:
    TopLevelScreen screen;

public:
    this(in Cmdargs cmdargs)
    {
        auto args = cmdargs.fileArgs;
        if (args.length == 0) {
            screen = mainloop.firstscr.createFirstScreen();
        }
        else {
            screen = mainloop.firstscr.createGameFromCmdargs(cmdargs);
        }
    }

    void mainLoop()
    {
        try while (true) {
            immutable lastTick = timerTicks;
            if (calc_returnsTrueIfWeShouldExitApp()) {
                break;
            }
            draw();
            while (lastTick == timerTicks)
                al_rest(0.001);
        }
        catch (Throwable firstThr) {
            // Uncaught exceptions, assert errors, and assert (false) should
            // fly straight out of main and terminate the program. Since
            // Windows users won't run the game from a shell, they should
            // retrieve the error message from the logfile, in addition.
            // In a release build, assert (false) crashes instead of throwing.
            for (Throwable thr = firstThr; thr !is null; thr = thr.next) {
                logf("%s:%d:", thr.file, thr.line);
                log(thr.msg);
                log(thr.info.toString());
            }
            if (screen !is null)
                screen.emergencySave();
            throw firstThr;
        }
        kill();
    }

    private void kill()
    {
        if (screen) {
            screen.dispose();
            screen = null;
        }
        core.memory.GC.collect();
        core.memory.GC.minimize();
    }

    private bool calc_returnsTrueIfWeShouldExitApp()
    {
        hardware.mousecur.mouseCursor.xf = 0;
        hardware.mousecur.mouseCursor.yf = 0;

        hardware.display .calc();
        hardware.mouse   .calc();
        hardware.keyboard.calcCallThisAfterMouseCalc();

        if (hardware.display.displayCloseWasClicked()
            || shiftHeld() && keyTapped(ALLEGRO_KEY_ESCAPE)
        ) {
            return true;
        }
        gui.calc(); // Will also calc the screen that is registered as Elder
        if (screen.done) {
            if (screen.proposesToExitApp) {
                return true;
            }
            auto temp = screen.nextTopLevelScreen;
            kill();
            screen = temp;
        }
        return false;
    }

    private void draw()
    {
        gui.draw(); // Will also draw the screen that is registered as Elder
        if (screen.proposesToDrawMouseCursor)
            hardware.mousecur.draw();
        hardware.sound.draw();
        flip_display();
        takeScreenshot();
    }

    private void takeScreenshot()
    {
        import file.option;
        import hardware.scrshot;
        if (! keyScreenshot.keyTapped)
            return;
        hardware.scrshot.takeScreenshot(screen.filenamePrefixForScreenshot);
    }
}
// end class MainLoop
