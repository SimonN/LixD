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

enum ScreenMode {
    windowed = 0,
    softwareFullscreen = 1,
    hardwareFullscreen = 2,
}

version (assert) {
    enum ScreenMode defaultScreenMode = ScreenMode.windowed;
}
else {
    enum ScreenMode defaultScreenMode = ScreenMode.softwareFullscreen;
}

struct DisplayTryMode {
    ScreenMode mode;
    int x, y;
}

@property DisplayTryMode displayTryMode()
{
    if (screenMode is null
        || screenMode.value == ScreenMode.softwareFullscreen
        || screenWindowedX is null
        || screenWindowedY is null
    ) {
        return DisplayTryMode(ScreenMode.softwareFullscreen, 0, 0);
    }
    return DisplayTryMode(userScreenModeOrDefault,
        screenWindowedX.value, screenWindowedY.value);
}

///////////////////////////////////////////////////////////////////////////////

private:

@property ScreenMode userScreenModeOrDefault()
{
    if (screenMode is null) {
        return defaultScreenMode;
    }
    ScreenMode ret = defaultScreenMode;
    try {
        ret = screenMode.value.to!ScreenMode;
    }
    catch (Exception) {
        ret = defaultScreenMode;
        screenMode.value = defaultScreenMode;
    }
    return ret;
}
