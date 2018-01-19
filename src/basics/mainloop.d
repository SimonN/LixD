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
import basics.globals;
import basics.resol;
import editor.editor;
import game.core.game;
import game.replay; // ReplayToLevelMatcher
import file.filename; // running levels from the command-line
import file.log; // logging uncaught Exceptions
import hardware.display;
import hardware.keyboard;
import hardware.music;
import menu.askname;
import menu.browser.replay;
import menu.browser.single;
import menu.lobby.lobby;
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
        auto args = cmdargs.fileArgs;
        if (args.length == 0) {
            // let calc() decide what menu to spawn
            return;
        }

        auto matcher = new ReplayToLevelMatcher(args[$-1]);
        if (cmdargs.preferPointedTo)
            matcher.forcePointedTo();
        else if (args.length == 2)
            matcher.forceLevel(args[0]);

        if (matcher.preferredLevel.good)
            this.game = matcher.createGame(Runmode.INTERACTIVE);
        else
            throw new Exception("Level or replay isn't playable.");
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
        kill();
    }

    private void kill()
    {
        if (game) {
            game.dispose();
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
                lobby = new Lobby(null);
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
            if (browSin && browSin.gotoGame) {
                auto fn = browSin.fileRecent;
                auto lv = browSin.levelRecent;
                _afterGameGoto = AfterGameGoto.single;
                kill();
                game = new Game(Runmode.INTERACTIVE, lv, fn, null, true);
            }
            else if (browRep && browRep.gotoGame) {
                auto matcher = browRep.matcher;
                _afterGameGoto = AfterGameGoto.replays;
                kill();
                game = matcher.createGame(Runmode.INTERACTIVE);
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
            else if ((browSin && browSin.gotoMainMenu)
                ||   (browRep && browRep.gotoMainMenu)
            ) {
                kill();
                mainMenu = new MainMenu;
                gui.addElder(mainMenu);
            }
        }
        else if (lobby) {
            if (lobby.gotoGame) {
                auto net = lobby.loseOwnershipOfRichClient();
                kill();
                game = new Game(net);
            }
            else if (lobby.gotoMainMenu) {
                kill();
                mainMenu = new MainMenu;
                gui.addElder(mainMenu);
            }
        }
        else if (optionsMenu) {
            if (optionsMenu.gotoMainMenu)
                toMainMenuWithResChange();
        }
        else if (askName) {
            if (askName.gotoMainMenu)
                toMainMenuWithResChange();
            else if (askName.gotoExitApp)
                exit = true;
        }
        else if (game) {
            game.calc();
            if (game.gotoMainMenu) {
                suggestMusic(fileMusicMenu);
                auto net = game.loseOwnershipOfRichClient();
                kill();
                if (net) {
                    lobby = new Lobby(net);
                    gui.addElder(lobby);
                }
                else if (_afterGameGoto == AfterGameGoto.replays) {
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
                suggestMusic(fileMusicMenu);
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
            suggestMusic(fileMusicMenu);
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
        takeScreenshot();
    }

    /*
     * The options menu reinitializes many modules itself, but
     * it's a GUI dialog, therefore it feels safer to change resolution
     * outside of that dialog. Let's do it here.
     */
    private void toMainMenuWithResChange()
    {
        kill();
        changeResolutionBasedOnUserFileAlone();
        mainMenu = new MainMenu;
        gui.addElder(mainMenu);
    }

    private void takeScreenshot()
    {
        import basics.user;
        import hardware.scrshot;
        if (! keyScreenshot.keyTapped)
            return;
        hardware.scrshot.takeScreenshot(
            game ? game.filenamePrefixForScreenshot : "screenshot");
    }
}
// end class MainLoop
