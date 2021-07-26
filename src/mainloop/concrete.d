module mainloop.concrete;

import optional;

import basics.globals : fileMusicMenu;
import basics.resol;
import file.filename;
import file.replay;
import editor.editor;
import game.core.game;
import game.harvest;
import mainloop.topscrn;
import hardware.music;
import menu.askname;
import menu.browser.replay;
import menu.browser.single;
import menu.lobby.lobby;
import menu.options;
import menu.outcome.single;
import menu.rep4lev;
import menu.mainmenu;

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

class ZockerScreen : GuiElderTopLevelScreen {
private:
    Game _game; // We'll own this, we'll dispose it.
    AfterwardsGoto _after;

    // Prevent harvests from saving duplicate replays: Remember what replay
    // we loaded last and pass that to program components that handle harvests.
    // Whenever you assign a replay to this, clone the replay first.
    // _lastLoaded should be treated like an immutable replay.
    // Either _lastLoaded contains exactly one replay
    Optional!(const Replay) _lastLoaded;

public:
    enum AfterwardsGoto {
        browSin,
        browRep,
        lobby,
        mainMenu, // because we loaded directly from the command line?
    }

    this(
        Game gameToTakeOwnershipOf,
        Optional!(const Replay) lastLoaded, // see comment for _lastLoaded
        AfterwardsGoto after
    ) {
        _game = gameToTakeOwnershipOf;
        _lastLoaded = lastLoaded;
        _after = after;
        super(_game);
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _game.gotoMainMenu;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        suggestMusic(fileMusicMenu);
        auto net = _game.loseOwnershipOfRichClient();
        return net !is null
            ? new LobbyScreen(net, _game.harvest)
            : new SinglePlayerOutcomeScreen(_game.harvest, _after);
    }

    override string filenamePrefixForScreenshot() const
    {
        return _game.filenamePrefixForScreenshot;
    }

protected:
    override void onDispose()
    {
        if (_game) {
            _game.dispose();
        }
    }
}

class SinglePlayerOutcomeScreen : GuiElderTopLevelScreen {
private:
    SinglePlayerOutcome _singleOut;
    ZockerScreen.AfterwardsGoto _browserToExitToIfExitIsChosen;

public:
    this(Harvest harvest, ZockerScreen.AfterwardsGoto after)
    {
        _singleOut = new SinglePlayerOutcome(harvest);
        _browserToExitToIfExitIsChosen = after;
        super(_singleOut);
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
            return new ZockerScreen(new Game(
                _singleOut.nextLevel.level,
                _singleOut.nextLevel.fn, no!Replay),
                no!(const Replay), ZockerScreen.AfterwardsGoto.browSin);
        case SinglePlayerOutcome.ExitWith.gotoBrowser:
            final switch (_browserToExitToIfExitIsChosen) {
            case ZockerScreen.AfterwardsGoto.browSin:
                return new BrowserSingleScreen();
            case ZockerScreen.AfterwardsGoto.browRep:
                return new BrowserReplayScreen();
            case ZockerScreen.AfterwardsGoto.lobby:
                assert (false, "We shouldn't have gone to SinglePlayerOutcome"
                    ~ " when the suggested going to Lobby afterwards");
            case ZockerScreen.AfterwardsGoto.mainMenu:
                return new MainMenuScreen();
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
            return new ZockerScreen(new Game(
                _browSin.levelRecent,
                _browSin.fileRecent, no!Replay),
                no!(const Replay), ZockerScreen.AfterwardsGoto.browSin);
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
            return new ZockerScreen(_browRep.matcher.createGame(),
                some!(const Replay)(_browRep.matcher.replay.clone),
                ZockerScreen.AfterwardsGoto.browRep);
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
            return new ZockerScreen(_repForLev.matcher.createGame(),
                some!(const Replay)(_repForLev.matcher.replay.clone),
                ZockerScreen.AfterwardsGoto.browSin);
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
    this(T...)(T args)
    {
        _lobby = new Lobby(args);
        super(_lobby);
    }

    bool done() const pure nothrow @safe @nogc
    {
        return _lobby.gotoGame || _lobby.gotoMainMenu;
    }

    TopLevelScreen nextTopLevelScreen()
    {
        if (_lobby.gotoGame) {
            return new ZockerScreen(
                new Game(_lobby.loseOwnershipOfRichClient()),
                no!(const Replay),
                ZockerScreen.AfterwardsGoto.lobby);
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
