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
import basics.globconf;
import editor.editor;
import game.core.game;
import file.filename; // running levels from the command-line
import file.log; // logging uncaught Exceptions
import hardware.display;
import hardware.keyboard;
import menu.askname;
import menu.browser.replay;
import menu.browser.single;
import menu.lobby;
import menu.mainmenu;
import menu.options;

static import gui;
static import hardware.keyboard;
static import hardware.mouse;
static import hardware.mousecur;
static import hardware.sound;

class MainLoop {
    bool exit;

    MainMenu mainMenu;
    BrowserSingle browSin;
    Lobby lobby;
    BrowserReplay browRep;
    OptionsMenu optionsMenu;
    MenuAskName askName;

    Game   game;
    Editor editor;

    enum AfterGameGoto { single, replays }
    AfterGameGoto _afterGameGoto;

public:
    this(in Cmdargs cmdargs)
    {
        // I don't like this function. This takes 1 or 2 arguments, finds out
        // which level and replay to run, and creates a game with that.
        // Maybe the replay should be responsibile for finding the level?
        auto args = cmdargs.fileArgs;
        if (args.length >= 1) {
            import level.level;
            import game.replay;
            auto rp = Replay.loadFromFile(args[$-1]);
            if (! cmdargs.preferPointedTo) {
                auto lv = new Level(args[0]);
                if (lv.good) {
                    this.game = new Game(Runmode.INTERACTIVE, lv, args[0],
                        rp.empty ? null : rp);
                    return;
                }
            }
            // The level in the replay file was bad or unwanted.
            auto lv = new Level(rp.levelFilename);
            if (lv.good)
                this.game = new Game(Runmode.INTERACTIVE, lv,
                                     rp.levelFilename, rp.empty ? null : rp);
            // DTODO: render an error on the graphical screen
        }
        // if no fileArgs, let calc() decide what menu to spawn
    }

    void mainLoop()
    {
        try while (true) {
            immutable lastTick = timerTicks;
            calc();
            if (exit) break;
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
            if (editor)
                editor.emergencySave();
            throw firstThr;
        }
        kill(true);
    }

    // The network connection isn't global, but we use the same connection
    // in several application parts. It must survive past a kill(), but
    // it should be disconnected at program termination in kill(true).
    private void kill(bool killPersistentThingsLikeNetworkToo = false)
    {
        if (game) {
            destroy(game);
            game = null;
        }
        if (editor) {
            gui.rmElder(editor);
            destroy(editor);
            editor = null;
        }
        if (mainMenu) {
            gui.rmElder(mainMenu);
            mainMenu = null;
        }
        if (browSin) {
            gui.rmElder(browSin);
            destroy(browSin); // DTODO: check what is best here. There is a
                              // Torbit to be destroyed in browser's preview.
            browSin = null;
        }
        if (lobby) {
            if (killPersistentThingsLikeNetworkToo)
                lobby.disconnect();
            gui.rmElder(lobby);
            lobby = null;
        }
        if (browRep) {
            gui.rmElder(browRep);
            destroy(browRep); // see comment for destroy(browSin)
            browRep = null;
        }
        if (optionsMenu) {
            gui.rmElder(optionsMenu);
            optionsMenu = null;
        }
        if (askName) {
            gui.rmElder(askName);
            askName = null;
        }
        core.memory.GC.collect();
    }

    private void calc()
    {
        hardware.mousecur.mouseCursor.xf = 0;
        hardware.mousecur.mouseCursor.yf = 0;

        hardware.display .calc();
        hardware.mouse   .calc();
        hardware.keyboard.calcCallThisAfterMouseCalc();
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
                kill();
                lobby = new Lobby;
                gui.addElder(lobby);
            }
            else if (mainMenu.gotoReplays) {
                kill();
                browRep = new BrowserReplay;
                gui.addElder(browRep);
            }
            else if (mainMenu.gotoOptions) {
                kill();
                optionsMenu = new OptionsMenu;
                gui.addElder(optionsMenu);
            }
            else if (mainMenu.exitProgram) {
                exit = true;
            }
        }
        else if (browSin || browRep) {
            auto brow = (browSin !is null ? browSin : browRep);
            if (brow.gotoGame) {
                auto fn = brow.fileRecent;
                auto lv = brow.levelRecent;
                auto rp = brow.replayRecent;
                _afterGameGoto = (brow is browSin ? AfterGameGoto.single
                                                  : AfterGameGoto.replays);
                kill();
                game = new Game(Runmode.INTERACTIVE, lv, fn, rp);
            }
            else if (browSin && (browSin.gotoEditorNewLevel
                             ||  browSin.gotoEditorLoadFileRecent)
            ) {
                auto fn = browSin.gotoEditorLoadFileRecent
                        ? browSin.fileRecent : null;
                kill();
                editor = new Editor(fn);
                gui.addElder(editor);
            }
            else if (brow.gotoMainMenu) {
                kill();
                mainMenu = new MainMenu;
                gui.addElder(mainMenu);
            }
        }
        else if (lobby) {
            if (lobby.gotoMainMenu) {
                kill();
                mainMenu = new MainMenu;
                gui.addElder(mainMenu);
            }
        }
        else if (optionsMenu) {
            if (optionsMenu.gotoMainMenu) {
                kill();
                mainMenu = new MainMenu;
                gui.addElder(mainMenu);
            }
        }
        else if (askName) {
            if (askName.gotoMainMenu) {
                kill();
                mainMenu = new MainMenu;
                gui.addElder(mainMenu);
            }
            else if (askName.gotoExitApp)
                exit = true;
        }
        else if (game) {
            game.calc();
            if (game.gotoMainMenu) {
                kill();
                if (_afterGameGoto == AfterGameGoto.replays) {
                    browRep = new BrowserReplay;
                    gui.addElder(browRep);
                }
                else {
                    browSin = new BrowserSingle;
                    gui.addElder(browSin);
                }
            }
        }
        else if (editor) {
            // editor is a GUI elder, thus already calced
            if (editor.gotoMainMenu) {
                kill();
                browSin = new BrowserSingle();
                gui.addElder(browSin);
            }
        }
        else {
            // program has just started, nothing exists yet
            if (basics.globconf.userName.length) {
                mainMenu = new MainMenu;
                gui.addElder(mainMenu);
            }
            else {
                askName = new MenuAskName;
                gui.addElder(askName);
            }
        }

    }

    private void draw()
    {
        // mainMenu etc. are GUI Windows. Those have been added as elders and
        // are therefore supervised by module gui.root.
        // Even the editor is a gui elder.
        if (game)
            game.draw();
        gui.draw();
        if (! askName)
            hardware.mousecur.draw();
        hardware.sound.draw();
        flip_display();
    }
}
// end class MainLoop
