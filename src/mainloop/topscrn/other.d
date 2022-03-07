module mainloop.topscrn.other;

import optional;

import basics.globals : fileMusicMenu;
import basics.resol;
import file.filename;
import file.replay;
import file.trophy;
import editor.editor;
import game.argscrea;
import game.core.game;
import mainloop.topscrn.base;
import mainloop.topscrn.game;
import hardware.music;
import level.level;
import menu.askname;
import menu.browser.replay;
import menu.browser.single;
import menu.lobby.lobby;
import menu.options;
import menu.outcome.single;
import menu.rep4lev;
import menu.mainmenu;
import net.client.richcli;

private T crashInsteadOfReturningAny(T)()
{
    assert (false, "Illegal code path, we won't return a " ~ T.stringof);
}

class MainMenuScreen : GuiElderTopLevelScreen {
private:
    MainMenu _menu;

public:
    this()
    {
        suggestMusic(fileMusicMenu);
        _menu = new MainMenu();
        super(_menu);
    }

    bool done() const pure nothrow @safe @nogc
    {
        with (_menu) return gotoSingle
            || gotoNetwork
            || gotoReplays
            || gotoOptions
            || exitProgram;
    }

    override bool proposesToExitApp() const pure nothrow @safe @nogc
    {
        return _menu.exitProgram;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        return _menu.gotoSingle ? new BrowserSingleScreen()
            : _menu.gotoNetwork ? new LobbyScreen()
            : _menu.gotoReplays ? new BrowserReplayScreen()
            : _menu.gotoOptions ? new OptionsMenuScreen()
            : crashInsteadOfReturningAny!TopLevelScreen;
    }
}

class SinglePlayerOutcomeScreen : GuiElderTopLevelScreen {
private:
    SinglePlayerOutcome _singleOut;
    AfterGameGoTo _after;

public:
    this(ArgsToCreateGame previous,
        const(Replay) replayJustPlayed,
        in HalfTrophy whatTheReplayAchieved,
        in AfterGameGoTo after,
    ) {
        Trophy tro = Trophy(previous.level.built, previous.levelFilename);
        tro.copyFrom(whatTheReplayAchieved);
        _singleOut = new SinglePlayerOutcome(previous, replayJustPlayed, tro);
        super(_singleOut);
        _after = after;
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _singleOut.exitWith != SinglePlayerOutcome.ExitWith.notYet;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        final switch (_singleOut.exitWith) {
        case SinglePlayerOutcome.ExitWith.notYet:
            return crashInsteadOfReturningAny!TopLevelScreen;
        case SinglePlayerOutcome.ExitWith.gotoLevel:
            return new SingleplayerGameScreen(ArgsToCreateGame(
                _singleOut.nextLevel.level,
                _singleOut.nextLevel.fn,
                no!(immutable Replay)),
                /*
                 * Deliberately deviating from _after.
                 * If we play more than one map, I think we'll forget which
                 * browser we came from. It feels like singleplayer, not like
                 * replay watching, then.
                 */
                AfterGameGoTo.singleBrowser);
        case SinglePlayerOutcome.ExitWith.gotoBrowser:
            with (AfterGameGoTo) final switch (_after) {
                case singleBrowser: return new BrowserSingleScreen();
                case replayBrowser: return new BrowserReplayScreen();
            }
        }
    }

protected:
    override void onDispose()
    {
        if (_singleOut) {
            _singleOut.dispose();
        }
    }
}

class BrowserSingleScreen : GuiElderTopLevelScreen {
private:
    BrowserSingle _browSin;

public:
    this()
    {
        _browSin = new BrowserSingle();
        super (_browSin);
    }

    bool done() const pure nothrow @safe @nogc
    {
        assert (_browSin);
        return _browSin.gotoGame
            || _browSin.gotoRepForLev
            || _browSin.gotoEditorNewLevel
            || _browSin.gotoEditorLoadFileRecent
            || _browSin.gotoMainMenu;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        if (_browSin.gotoGame) {
            return new SingleplayerGameScreen(ArgsToCreateGame(
                _browSin.levelRecent,
                _browSin.fileRecent,
                no!(immutable Replay)),
                AfterGameGoTo.singleBrowser);
        }
        return _browSin.gotoRepForLev
            ? new RepForLevScreen(_browSin.fileRecent, _browSin.levelRecent)
            : _browSin.gotoEditorNewLevel
            ? new EditorScreen(null)
            : _browSin.gotoEditorLoadFileRecent
            ? new EditorScreen(_browSin.fileRecent)
            : _browSin.gotoMainMenu
            ? new MainMenuScreen()
            : crashInsteadOfReturningAny!TopLevelScreen;
    }

protected:
    override void onDispose()
    {
        if (_browSin) {
            _browSin.dispose();
        }
    }
}

class BrowserReplayScreen : GuiElderTopLevelScreen {
private:
    BrowserReplay _browRep;

public:
    this()
    {
        _browRep = new BrowserReplay();
        super (_browRep);
    }

    bool done() const pure nothrow @safe @nogc
    {
        assert (_browRep);
        return _browRep.gotoGame || _browRep.gotoMainMenu;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        if (_browRep.gotoGame) {
            return new SingleplayerGameScreen(
                _browRep.matcher.argsToCreateGame(),
                AfterGameGoTo.replayBrowser);
        }
        else if (_browRep.gotoMainMenu) {
            return new MainMenuScreen();
        }
        assert (false);
    }

protected:
    override void onDispose()
    {
        if (_browRep) {
            _browRep.dispose();
        }
    }
}

class EditorScreen : GuiElderTopLevelScreen {
private:
    Editor _editor;

public:
    this(Filename fn)
    {
        _editor = new Editor(fn);
        super(_editor);
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _editor.gotoMainMenu;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        return new BrowserSingleScreen();
    }

protected:
    override void onDispose()
    {
        if (_editor) {
            _editor.dispose();
        }
    }
}

class OptionsMenuScreen : GuiElderTopLevelScreen {
private:
    OptionsMenu _opmen;

public:
    this()
    {
        _opmen = new OptionsMenu;
        super(_opmen);
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _opmen.gotoMainMenu;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        changeResolutionBasedOnUserFileAlone();
        return new MainMenuScreen();
    }
}

class RepForLevScreen : GuiElderTopLevelScreen {
private:
    RepForLev _repForLev;

public:
    this(T...)(T args)
    {
        _repForLev = new RepForLev(args);
        super(_repForLev);
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _repForLev.gotoGame || _repForLev.gotoBrowSin;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        if (_repForLev.gotoGame) {
            return new SingleplayerGameScreen(
                _repForLev.matcher.argsToCreateGame(),
                AfterGameGoTo.singleBrowser);
        }
        else if (_repForLev.gotoBrowSin) {
            return new BrowserSingleScreen();
        }
        assert (false);
    }
}

class AskNameScreen : GuiElderTopLevelScreen {
private:
    MenuAskName _askName;

public:
    this()
    {
        suggestMusic(fileMusicMenu);
        _askName = new MenuAskName;
        super(_askName);
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _askName.gotoMainMenu || _askName.gotoExitApp;
    }

    override bool proposesToExitApp() const pure nothrow @safe @nogc
    {
        return _askName.gotoExitApp;
    }

    override bool proposesToDrawMouseCursor() const pure nothrow @safe @nogc
    {
        return false;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        changeResolutionBasedOnUserFileAlone();
        return new MainMenuScreen;
    }
}

class LobbyScreen : GuiElderTopLevelScreen {
private:
    Lobby _lobby;

public:
    this()
    {
        _lobby = new Lobby();
        super(_lobby);
    }

    this(RichClient richClient,
        in Level oldLevel,
        in Replay justPlayed,
    ) {
        justPlayed.saveAsAutoReplay(oldLevel);
        _lobby = new Lobby(richClient);
        super(_lobby);
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _lobby.gotoGame || _lobby.gotoMainMenu;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        if (_lobby.gotoGame) {
            return new MultiplayerGameScreen(
                new Game(_lobby.loseOwnershipOfRichClient()));
        }
        else if (_lobby.gotoMainMenu) {
            return new MainMenuScreen;
        }
        assert (false);
    }

protected:
    override void onDispose()
    {
        if (_lobby) {
            _lobby.disconnect();
        }
    }

}
