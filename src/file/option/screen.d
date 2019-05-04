module file.option.screen;

/*
 * The mutable screen options themselves are in file.option.allopts!
 *
 * This module (file.option.screen) merely has the enumerations
 * and convenience access functions for screen modes.
 */

import std.conv;

import file.option.allopts;

nothrow:

enum ScreenType {
    windowed = 0,
    softwareFullscreen = 1,
    hardwareFullscreen = 2,
}

version (assert) {
    enum ScreenType defaultScreenType = ScreenType.windowed;
}
else {
    enum ScreenType defaultScreenType = ScreenType.softwareFullscreen;
}

struct ScreenChoice {
    ScreenType type;
    int x, y;
}

@property ScreenChoice screenChoice()
in { assertOptionsExist(); }
body {
    /*
     * See comment in hardware.display.cmdArgModes:
     * Even with software fullscreen (that takes the desktop res),
     * we must pass some x > 0, y > 0 to entice A5 to take desktop res.
     * With x == 0, y == 0, A5 won't create a software fullscreen display.
     */
    immutable int x = screenWindowedX.value > 0 ? screenWindowedX.value : 640;
    immutable int y = screenWindowedY.value > 0 ? screenWindowedY.value : 480;
    return ScreenChoice(userScreenTypeOrCompilationDefault, x, y);
}

@property void screenChoice(ScreenChoice a)
in { assertOptionsExist(); }
body {
    screenType.value = a.type;
    screenWindowedX.value = a.x;
    screenWindowedY.value = a.y;
}

///////////////////////////////////////////////////////////////////////////////

private:

void assertOptionsExist()
{
    assert (screenType !is null, "Initialize options first (screenType)");
    assert (screenWindowedX !is null, "Initialize options first (scrWinX)");
    assert (screenWindowedY !is null, "Initialize options first (scrWinY)");
    assert (screenType.value == ScreenType.windowed
        ||  screenType.value != ScreenType.windowed,
        "Error while dereferencing and comparing screenType?!");
}

@property ScreenType userScreenTypeOrCompilationDefault()
in { assertOptionsExist(); }
body {
    ScreenType ret = defaultScreenType;
    try {
        ret = screenType.value.to!ScreenType;
    }
    catch (Exception) {
        ret = defaultScreenType;
        screenType.value = defaultScreenType;
    }
    return ret;
}
