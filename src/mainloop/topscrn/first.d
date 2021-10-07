module mainloop.topscrn.first;

/*
 * The first screen that is produced for the main loop.
 *
 * All subsequent screens will be created from the previous screen.
 */

import optional;

import basics.cmdargs;
static import file.option.allopts;
import file.replay;
import mainloop.topscrn.other;
import mainloop.topscrn.game;
import mainloop.topscrn.base;
import menu.repmatch;

TopLevelScreen createFirstScreen()
{
    return (file.option.userName.length > 0)
        ? new MainMenuScreen()
        : new AskNameScreen();
}

TopLevelScreen createGameFromCmdargs(in Cmdargs cmdargs)
{
    assert (cmdargs.fileArgs.length > 0,
        "Call createFirstScreen instead");
    auto matcher = new ReplayToLevelMatcher(cmdargs.fileArgs[$-1]);
    if (cmdargs.preferPointedTo) {
        matcher.forcePointedTo();
    }
    else if (cmdargs.fileArgs.length == 2) {
        matcher.forceLevel(cmdargs.fileArgs[0]);
    }

    if (! matcher.mayCreateGame) {
        throw new Exception("Level or replay isn't playable.");
    }
    const args = matcher.argsToCreateGame;
    return new SingleplayerGameScreen(args, args.loadedReplay.empty
        ? AfterGameGoTo.singleBrowser : AfterGameGoTo.replayBrowser);
}
