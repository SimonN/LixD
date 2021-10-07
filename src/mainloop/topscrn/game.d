module mainloop.topscrn.game;

import optional;

import basics.globals : fileMusicMenu;
import file.filename;
import file.replay;
import game.core.game;
import hardware.music;
import mainloop.topscrn.base;
import mainloop.topscrn.other;

final class SingleplayerGameScreen : GameScreen {
private:
    Filename _fnOfPlayedLevel; // Is never null because we're singleplayer.

    /*
     * Prevent watched replays from saving duplicate replays: Remember what
     * replay we loaded last and pass that to program components that
     * save replays. Whenever you assign a replay to this, clone the replay
     * first. _lastLoaded should be treated like an immutable replay.
     */
    Optional!(const Replay) _lastLoaded;

public:
    this(
        Game gameToTakeOwnershipOf,
        Filename ofLevelPlayedInThatGame,
        Optional!(const Replay) lastLoaded, // see comment for _lastLoaded
    ) {
        super(gameToTakeOwnershipOf);
        _fnOfPlayedLevel = ofLevelPlayedInThatGame;
        _lastLoaded = lastLoaded;
    }

protected:
    override TopLevelScreen onNextTopLevelScreen()
    {
        return new SinglePlayerOutcomeScreen(game.level, game.replay,
            game.halfTrophyOfLocalTribe, _fnOfPlayedLevel, _lastLoaded);
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
