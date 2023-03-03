module file.option.screen;

/*
 * What's _not_ here:
 *
 *  - The mutable screen options themselves are in file.option.allopts.
 *  - The calls into Allegro 5 to create a display are in hardware.display.
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

enum ScreenType defaultScreenType = ScreenType.windowed;

struct ScreenChoice {
    ScreenType type;
    int x, y;
}

ScreenChoice screenChoiceInUserOptions()
in { assertOptionsExist(); }
do {
    ScreenChoice ret;
    ret.type = userScreenTypeOrCompilationDefault;
    final switch (ret.type) {
    case ScreenType.windowed:
        ret.x = screenWindowedX.value;
        ret.y = screenWindowedY.value;
        break;
    case ScreenType.softwareFullscreen: // Yes, reusing hardware fullscreen xy!
    case ScreenType.hardwareFullscreen:
        /*
         * Allegro 5.2.8 has a bug on Linux where software fullscreen fails to
         * deduce the desktop resolution, even when we pass nonzero xy.
         * Thus, workaround: The Lix user can enter his hardware fullscreen
         * resolution, and we reuse that for software fullscreen.
         *
         * https://github.com/liballeg/allegro5/issues/1349
         */
        ret.x = screenHardwareFullscreenX.value;
        ret.y = screenHardwareFullscreenY.value;
        break;
    }
    /*
     * See comment in hardware.display.cmdArgModes:
     * Even with software fullscreen (that takes the desktop res),
     * we must pass some x > 0, y > 0 to entice A5 to take desktop res.
     * With x == 0, y == 0, A5 won't create a software fullscreen display.
     */
    ret.x = ret.x > 0 ? ret.x : 640;
    ret.y = ret.y > 0 ? ret.y : 480;
    return ret;
}

void screenChoiceInUserOptions(ScreenChoice a)
in { assertOptionsExist(); }
do {
    screenType = a.type;
    final switch (a.type) {
    case ScreenType.windowed:
        screenWindowedX = a.x;
        screenWindowedY = a.y;
        break;
    case ScreenType.softwareFullscreen:
        break;
    case ScreenType.hardwareFullscreen:
        screenHardwareFullscreenX = a.x;
        screenHardwareFullscreenY = a.y;
        break;
    }
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

ScreenType userScreenTypeOrCompilationDefault()
in { assertOptionsExist(); }
do {
    ScreenType ret = defaultScreenType;
    try {
        ret = screenType.value.to!ScreenType;
    }
    catch (Exception) {
        ret = defaultScreenType;
        screenType = defaultScreenType;
    }
    return ret;
}
