module mainloop.topscrn.game;

import optional;

import basics.globals : fileMusicMenu;
import file.filename;
import file.replay;
import game.argscrea;
import game.core.game;
import hardware.music;
import level.level;
import mainloop.topscrn.base;
import mainloop.topscrn.other;

enum AfterGameGoTo {
    singleBrowser,
    replayBrowser,
}

final class SingleplayerGameScreen : GameScreen {
private:
    Filename _fnOfPlayedLevel; // Is never null because we're singleplayer.

    /*
     * Prevent watched replays from saving duplicate replays: Remember what
     * replay we loaded last and pass that to program components that
     * save replays. Whenever you assign a replay to this, clone the replay
     * first. _lastLoaded should be treated like an immutable replay.
     */
    Optional!(immutable Replay) _lastLoaded;
    AfterGameGoTo _after;

public:
    this(ArgsToCreateGame args, AfterGameGoTo after)
    {
        super(new Game(args));
        _fnOfPlayedLevel = args.levelFilename;
        _lastLoaded = args.loadedReplay;
        _after = after;
    }

protected:
    override TopLevelScreen onNextTopLevelScreen()
    {
        if (game.replay.numPlayers > 1) {
            /*
             * As it stands, we use SinglePlayerGameScreen also for re-watching
             * old multiplayer replays, and we don't have a multiplayer outcome
             * screen. Don't re-autosave replays in the singleplayer outcome
             * screen. Long-term solution: A multiplayer outcome screen.
             */
            return new BrowserReplayScreen();
        }
        return new SinglePlayerOutcomeScreen(
            ArgsToCreateGame(game.level, _fnOfPlayedLevel, _lastLoaded),
            game.replay, game.halfTrophyOfLocalTribe, _after);
    }
}

final class MultiplayerGameScreen : GameScreen {
public:
    this(Game gameToTakeOwnershipOf) { super(gameToTakeOwnershipOf); }

protected:
    override TopLevelScreen onNextTopLevelScreen()
    {
        auto net = _game.loseOwnershipOfRichClient();
        assert (net, "A networking client should exist after multiplayer");
        return new LobbyScreen(net, game.level, game.replay);
    }
}

abstract class GameScreen : GuiElderTopLevelScreen {
private:
    Game _game; // We'll own this, we'll dispose it.

protected:
    this(Game gameToTakeOwnershipOf) {
        _game = gameToTakeOwnershipOf;
        super(_game);
    }

public:
    final bool done() const pure nothrow @safe @nogc
    {
        return _game.gotoMainMenu;
    }

    final TopLevelScreen nextTopLevelScreen()
    {
        suggestMusic(fileMusicMenu);
        return onNextTopLevelScreen();
    }

    final override string filenamePrefixForScreenshot() const
    {
        return _game.filenamePrefixForScreenshot;
    }

protected:
    abstract TopLevelScreen onNextTopLevelScreen();

    final inout(Game) game() inout
    {
        return _game;
    }

    final override void onDispose()
    {
        if (_game) {
            _game.dispose();
        }
    }
}
