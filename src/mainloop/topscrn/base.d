module mainloop.topscrn.base;

/*
 * A TopLevelScreen is a part of the program.
 * It can be directly hung into the main loop.
 *
 * There is only one TopLevelScreen active at a time, but it can suggest
 * that the main loop dispose it and propose the next TopLevelScreen.
 *
 * In the derived classes, we'll choose this design A:
 *      Main loop has a TopLevelScreen
 *      GameTopLevelScreen has a Game and proposes BrowserTopLevelScreen
 *      Game has all the game logic
 *
 * ...over design B:
 *      Main loop has a TopLevelScreen
 *      Game is a TopLevelScreen
 *
 * ...because the Game's logic shouldn't be concerned with generating
 * other TopLevelScreens based on how we got to the game. The Game's logic
 * is complex enough already. It's OK that we get another layer of OO lasagna.
 */

import gui;

interface TopLevelScreen {
    void dispose();

    const pure nothrow @safe @nogc {
        bool done();
        bool proposesToExitApp();
        bool proposesToDrawMouseCursor();
    }
    TopLevelScreen nextTopLevelScreen();

    void emergencySave();
    string filenamePrefixForScreenshot() const;
}

abstract class GuiElderTopLevelScreen : TopLevelScreen {
private:
    IRoot _theElder;

public:
    this(IRoot e)
    in { assert(e); }
    do {
        _theElder = e;
        gui.addElder(_theElder);
    }

    final void dispose()
    {
        if (_theElder is null) {
            return;
        }
        gui.rmElder(_theElder);
        onDispose();
        _theElder = null;
    }

    // Some defaults that nearly every child will want >_>
    const pure nothrow @safe @nogc {
        bool proposesToExitApp() { return false; }
        bool proposesToDrawMouseCursor() { return true; }
    }
    void emergencySave() {}
    string filenamePrefixForScreenshot() const
    {
        return "screenshot";
    }

protected:
    void onDispose() {} // In case you want to dispose in the child,
        // or within _theElder that the child must then separately track.
}
