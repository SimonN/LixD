module mainloop.firstscr;

/*
 * The first screen that is produced for the main loop.
 *
 * All subsequent screens will be created from the previous screen.
 */

import optional;

import basics.cmdargs;
static import file.option.allopts;
import file.replay;
import mainloop.concrete;
import mainloop.topscrn;
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
    return new ZockerScreen(
        matcher.createGame(),
        some!(const Replay)(matcher.replay.clone),
        ZockerScreen.AfterwardsGoto.browRep);
}
