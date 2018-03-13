module basics.user;

/* User settings read from the user config file. This file differs from the
 * global config file, see globconf.d. Whenever the user file doesn't exist,
 * the default values from static this() are used.
 */

import std.typecons; // rebindable
import std.algorithm; // sort filenames before outputting them
import std.conv;

import enumap;
import optional;

import basics.alleg5;
import basics.globals;
import basics.globconf;
import basics.help;
import basics.trophy;
import file.filename;
import file.io;
import file.language;
import file.log; // when writing to disk fails
import file.useropt;
import hardware.keynames;
import hardware.keyset;
import net.ac;
import net.style;

private Trophy[Filename] _trophies;

// These is only for iteration during option saving/loading.
// Outside of this module, refer to options by their static variable name.
private AbstractUserOption[string] _optvecLoad;
private AbstractUserOption[] _optvecSave;

private auto newOpt(T)(string fileKey, Lang lang, T defaultVal)
{
    assert (fileKey !in _optvecLoad);
    static if (is (T == Filename))
        auto ret = new UserOptionFilename(fileKey, lang, defaultVal);
    else
        auto ret = new UserOption!T(fileKey, lang, defaultVal);
    _optvecLoad[fileKey] = ret;
    _optvecSave ~= ret;
    return ret;
}
private auto newOpt(T)(string fileKey, T defaultVal)
{
    return newOpt(fileKey, Lang.min, defaultVal);
}

@property bool languageIsEnglish()
{
    assert (fileLanguage !is null);
    assert (fileLanguage.value !is null);
    return fileLanguage.value == basics.globals.fileLanguageEnglish;
}

enum ScreenMode {
    windowed = 0,
    softwareFullscreen = 1,
    hardwareFullscreen = 2,
}

struct DisplayTryMode {
    ScreenMode mode;
    int x, y;
}

@property DisplayTryMode displayTryMode() nothrow
{
    if (screenMode !is null
        && screenMode.value != ScreenMode.softwareFullscreen
        && screenWindowedX !is null && screenWindowedY !is null
    ) {
        try return DisplayTryMode(screenMode.value.to!ScreenMode,
            screenWindowedX.value, screenWindowedY.value);
        catch (Exception)
            screenMode.value = ScreenMode.softwareFullscreen;
    }
    return DisplayTryMode(ScreenMode.softwareFullscreen, 0, 0);
}

/*
 * addToUser: Update trophy database (user progress, list of checkmarks)
 * with a new level result. This tries to save the best result per level.
 * Call this only with winning _trophies! The progress database doesn't know
 * whether a result is winning, it merely knows how many lix were saved.
 *
 * Returns true if we updated the previous result or if no previous result
 * existed. Returns false if the previous result was already equal or better.
 */
bool addToUser(Trophy tro, in Filename _fn)
{
    auto fn = rebindable!(const Filename)(_fn);
    auto existing = (fn in _trophies);
    if (! existing || tro.shouldReplaceAfterPlay(*existing)) {
        _trophies[fn] = tro;
        return true;
    }
    else
        return false;
}

Optional!Trophy getTrophy(in Filename fn)
{
    Trophy* ret = (rebindable!(const Filename)(fn) in _trophies);
    return ret ? some(*ret) : Optional!Trophy();
}

UserOptionFilename fileLanguage;
UserOption!int optionGroup;

UserOption!int mouseSpeed;
UserOption!int scrollSpeedEdge;
UserOption!int holdToScrollSpeed;
UserOption!bool holdToScrollInvert;
UserOption!bool fastMovementFreesMouse;
UserOption!bool avoidBuilderQueuing;
UserOption!bool avoidBatterToExploder;
UserOption!bool replayAfterFrameBack;
UserOption!bool unpauseOnAssign;

UserOption!int screenMode;
UserOption!int screenWindowedX;
UserOption!int screenWindowedY;
UserOption!int splatRulerDesign;
UserOption!bool paintTorusSeams;
UserOption!bool showButtonHotkeys;
UserOption!bool ingameTooltips;
UserOption!bool showFPS;
UserOption!int guiColorRed;
UserOption!int guiColorGreen;
UserOption!int guiColorBlue;

UserOption!bool soundEnabled;
UserOption!bool musicEnabled;
UserOption!int soundDecibels;
UserOption!int musicDecibels;

UserOptionFilename singleLastLevel;
UserOptionFilename networkLastLevel;
UserOptionFilename replayLastLevel;
UserOption!bool replayAutoSolutions;
UserOption!bool replayAutoMulti;

UserOption!int networkLastStyle;
UserOption!bool networkPreferCustom;
UserOption!string networkIpLastUsed;

UserOption!int  editorGridSelected;
UserOption!int  editorGridCustom;
UserOptionFilename editorLastDirTerrain;
UserOptionFilename editorLastDirSteel;
UserOptionFilename editorLastDirHatch;
UserOptionFilename editorLastDirGoal;
UserOptionFilename editorLastDirHazard;

UserOption!KeySet
    keyScroll,
    keyPriorityInvert,
    keyZoomIn,
    keyZoomOut,
    keyScreenshot,

    keyForceLeft,
    keyForceRight,
    keyPause,
    keyFrameBackMany,
    keyFrameBackOne,
    keyFrameAheadOne,
    keyFrameAheadMany,
    keySpeedFast,
    keySpeedTurbo,
    keyRestart,
    keyStateLoad,
    keyStateSave,
    keyNuke,
    keyChat,
    keyPingGoals,
    keyGameExit,

    keyMenuOkay,
    keyMenuEdit,
    keyMenuNewLevel,
    keyMenuExport,
    keyMenuDelete,
    keyMenuSearch,
    keyMenuUpDir,
    keyMenuUpBy1,
    keyMenuUpBy5,
    keyMenuDownBy1,
    keyMenuDownBy5,
    keyMenuExit,
    keyMenuMainSingle,
    keyMenuMainNetwork,
    keyMenuMainReplays,
    keyMenuMainOptions,

    keyEditorLeft,
    keyEditorRight,
    keyEditorUp,
    keyEditorDown,
    keyEditorSave,
    keyEditorSaveAs,
    keyEditorCopy,
    keyEditorDelete,
    keyEditorGrid,
    keyEditorSelectAll,
    keyEditorSelectFrame,
    keyEditorSelectAdd,
    keyEditorGroup,
    keyEditorUngroup,
    keyEditorBackground,
    keyEditorForeground,
    keyEditorMirror,
    keyEditorRotate,
    keyEditorDark,
    keyEditorAddTerrain,
    keyEditorAddSteel,
    keyEditorAddHatch,
    keyEditorAddGoal,
    keyEditorAddHazard,
    keyEditorExit,
    keyEditorMenuConstants,
    keyEditorMenuTopology,
    keyEditorMenuLooks,
    keyEditorMenuSkills;

Enumap!(Ac, UserOption!KeySet) keySkill;

@property const(Ac[14]) skillSort() { return _skillSort; }

private Ac[14] _skillSort = [
    Ac.walker,
    Ac.jumper,
    Ac.runner,
    Ac.climber,
    Ac.floater,
    Ac.batter,
    Ac.exploder,
    Ac.blocker,
    Ac.cuber,
    Ac.builder,
    Ac.platformer,
    Ac.basher,
    Ac.miner,
    Ac.digger
];

static this()
{
    assert (! fileLanguage);
    assert (fileLanguageEnglish);
    fileLanguage = newOpt("LANGUAGE", Lang.optionLanguage, fileLanguageEnglish);
    optionGroup = newOpt("OPTION_GROUP", 0);

    mouseSpeed = newOpt("MOUSE_SPEED", Lang.optionMouseSpeed, mouseStandardDivisor);
    scrollSpeedEdge = newOpt("SCROLL_SPEED_EDGE", Lang.optionScrollSpeedEdge, mouseStandardDivisor);
    holdToScrollSpeed = newOpt("SCROLL_SPEED_CLICK", Lang.optionHoldToScrollSpeed, mouseStandardDivisor / 2);
    holdToScrollInvert = newOpt("HOLD_TO_SCROLL_INVERT", Lang.optionHoldToScrollInvert, false);
    version (linux) {
        fastMovementFreesMouse = newOpt("FAST_MOVEMENT_FREES_MOUSE",
            Lang.optionFastMovementFreesMouse, false);
    }
    else {
        fastMovementFreesMouse = newOpt("FAST_MOVEMENT_FREES_MOUSE",
            Lang.optionFastMovementFreesMouse, true);
    }
    avoidBuilderQueuing = newOpt("AVOID_BUILDER_QUEUING", Lang.optionAvoidBuilderQueuing, true);
    avoidBatterToExploder = newOpt("AVOID_BATTER_TO_EXPLODER", Lang.optionAvoidBatterToExploder, false);
    replayAfterFrameBack = newOpt("REPLAY_AFTER_FRAME_BACK", Lang.optionReplayAfterFrameBack, true);
    unpauseOnAssign = newOpt("UNPAUSE_ON_ASSIGN", Lang.optionUnpauseOnAssign, false);

    screenMode = newOpt("SCREEN_MODE", Lang.optionScreenMode, ScreenMode.softwareFullscreen.to!int);
    screenWindowedX = newOpt("SCREEN_WINDOWED_X", Lang.optionScreenWindowedRes, 640);
    screenWindowedY = newOpt("SCREEN_WINDOWED_Y", 480);
    splatRulerDesign = newOpt("SPLAT_RULER_DESIGN", Lang.optionSplatRulerDesign, 2);
    paintTorusSeams = newOpt("PAINT_TORUS_SEAMS", Lang.optionPaintTorusSeams, false);
    showButtonHotkeys = newOpt("SHOW_BUTTON_HOTKEYS", Lang.optionShowButtonHotkeys, true);
    ingameTooltips = newOpt("INGAME_TOOLTIPS", Lang.optionIngameTooltips, true);
    showFPS = newOpt("SHOW_FRAMES_PER_SECOND", Lang.optionShowFPS, false);
    guiColorRed = newOpt("GUI_COLOR_RED", Lang.optionGuiColorRed, 0x60);
    guiColorGreen = newOpt("GUI_COLOR_GREEN", Lang.optionGuiColorGreen, 0x80);
    guiColorBlue = newOpt("GUI_COLOR_BLUE", Lang.optionGuiColorBlue, 0xB0);

    soundEnabled = newOpt("SOUND_ENABLED", Lang.optionSoundEnabled, true);
    musicEnabled = newOpt("MUSIC_ENABLED", Lang.optionMusicEnabled, true);
    soundDecibels = newOpt("SOUND_DECIBELS", Lang.optionSoundDecibels, 0);
    musicDecibels = newOpt("MUSIC_DECIBELS", Lang.optionMusicDecibels, -10);

    singleLastLevel = newOpt("SINGLE_LAST_LEVEL", fileSingleplayerFirstLevel);
    networkLastLevel = newOpt("NETWORK_LAST_LEVEL", dirLevelsNetwork);
    replayLastLevel = newOpt("REPLAY_LAST_LEVEL", dirReplays);
    replayAutoSolutions = newOpt("REPLAY_AUTO_SAVE_SOLUTIONS", Lang.optionReplayAutoSolutions, true);
    replayAutoMulti = newOpt("REPLAY_AUTO_SAVE_MULTI", Lang.optionReplayAutoMulti, true);

    networkLastStyle = newOpt("NETWORK_LAST_STYLE", Style.red.to!int);
    networkPreferCustom = newOpt("NETWORK_PREFER_CUSTOM", Lang.winLobbyStartCustom, false);
    networkIpLastUsed = newOpt("NETWORK_IP_LAST_USED", Lang.winLobbyStartCustom, "127.0.0.1");

    editorLastDirTerrain = newOpt("EDITOR_LAST_DIR_TERRAIN", Lang.addTerrain, dirImages);
    editorLastDirSteel = newOpt("EDITOR_LAST_DIR_STEEL", Lang.addSteel, dirImages);
    editorLastDirHatch = newOpt("EDITOR_LAST_DIR_HATCH", Lang.addHatch, dirImages);
    editorLastDirGoal = newOpt("EDITOR_LAST_DIR_GOAL", Lang.addGoal, dirImages);
    editorLastDirHazard = newOpt("EDITOR_LAST_DIR_HAZARD", Lang.addHazard, dirImages);

    editorGridSelected = newOpt("EDITOR_GRID_SELECTED", 1);
    editorGridCustom = newOpt("EDITOR_GRID_CUSTOM", Lang.optionEdGridCustom, 8);

    void newSkillKey(Ac ac, int singleKey)
    {
        keySkill[ac] = newOpt(ac.acToString, KeySet(singleKey));
    }
    newSkillKey(Ac.walker, ALLEGRO_KEY_D);
    newSkillKey(Ac.jumper, ALLEGRO_KEY_R);
    newSkillKey(Ac.runner, ALLEGRO_KEY_LSHIFT);
    newSkillKey(Ac.climber, ALLEGRO_KEY_Z);
    newSkillKey(Ac.floater, ALLEGRO_KEY_Q);
    newSkillKey(Ac.batter, ALLEGRO_KEY_C);
    newSkillKey(Ac.exploder, ALLEGRO_KEY_V);
    newSkillKey(Ac.blocker, ALLEGRO_KEY_X);
    newSkillKey(Ac.cuber, ALLEGRO_KEY_B);
    newSkillKey(Ac.builder, ALLEGRO_KEY_A);
    newSkillKey(Ac.platformer, ALLEGRO_KEY_T);
    newSkillKey(Ac.basher, ALLEGRO_KEY_E);
    newSkillKey(Ac.miner, ALLEGRO_KEY_G);
    newSkillKey(Ac.digger, ALLEGRO_KEY_W);

    auto newKey(string str, Lang lang, int key)
    {
        return newOpt(str, lang, KeySet(key));
    }
    auto newKey2(string str, Lang lang, int key1, int key2)
    {
        return newOpt(str, lang, KeySet(KeySet(key1), KeySet(key2)));
    }
    // Global keys -- these work in editor and game
    keyScroll = newKey("KEY_HOLD_TO_SCROLL", Lang.optionKeyScroll, keyRMB);
    keyPriorityInvert = newKey("KEY_PRIORITY_INVERT", Lang.optionKeyPriorityInvert, keyRMB);
    keyZoomIn = newKey("KEY_ZOOM_IN", Lang.optionKeyZoomIn, hardware.keynames.keyWheelUp);
    keyZoomOut = newKey("KEY_ZOOM_OUT", Lang.optionKeyZoomOut, hardware.keynames.keyWheelDown);
    keyScreenshot = newOpt("KEY_SCREENSHOT", Lang.optionKeyScreenshot,
        KeySet());

    // Game keys
    keyForceLeft = newKey2("KEY_FORCE_LEFT", Lang.optionKeyForceLeft, ALLEGRO_KEY_S, ALLEGRO_KEY_LEFT);
    keyForceRight = newKey2("KEY_FORCE_RIGHT", Lang.optionKeyForceRight, ALLEGRO_KEY_F, ALLEGRO_KEY_RIGHT);
    keyPause = newKey2("KEY_PAUSE", Lang.optionKeyPause, ALLEGRO_KEY_SPACE, keyMMB);
    keyFrameBackMany = newKey("KEY_SPEED_BACK_MANY", Lang.optionKeyFrameBackMany, ALLEGRO_KEY_1);
    keyFrameBackOne = newKey("KEY_SPEED_BACK_ONE", Lang.optionKeyFrameBackOne, ALLEGRO_KEY_2);
    keyFrameAheadOne = newKey("KEY_SPEED_AHEAD_ONE", Lang.optionKeyFrameAheadOne, ALLEGRO_KEY_3);
    keyFrameAheadMany = newKey("KEY_SPEED_AHEAD_MANY", Lang.optionKeyFrameAheadMany, ALLEGRO_KEY_6);
    keySpeedFast = newKey("KEY_SPEED_FAST", Lang.optionKeySpeedFast, ALLEGRO_KEY_4);
    keySpeedTurbo = newKey("KEY_SPEED_TURBO", Lang.optionKeySpeedTurbo, ALLEGRO_KEY_5);
    keyRestart = newKey("KEY_RESTART", Lang.optionKeyRestart, ALLEGRO_KEY_F1);
    keyStateLoad = newKey("KEY_STATE_LOAD", Lang.optionKeyStateLoad, ALLEGRO_KEY_F2);
    keyStateSave = newKey("KEY_STATE_SAVE", Lang.optionKeyStateSave, ALLEGRO_KEY_F3);
    keyNuke = newKey("KEY_NUKE", Lang.optionKeyNuke, ALLEGRO_KEY_F12);
    keyPingGoals = newKey("KEY_PING_GOALS", Lang.optionKeyClearPhysics, ALLEGRO_KEY_TAB);
    keyChat = newKey("KEY_CHAT", Lang.optionKeyChat, ALLEGRO_KEY_ENTER);
    keyGameExit = newKey("KEY_GAME_EXIT", Lang.winGameTitle, ALLEGRO_KEY_ESCAPE);

    keyMenuOkay = newKey("KEY_MENU_OKAY", Lang.optionKeyMenuOkay, ALLEGRO_KEY_SPACE);
    keyMenuEdit = newKey("KEY_MENU_EDIT", Lang.optionKeyMenuEdit, ALLEGRO_KEY_F);
    keyMenuNewLevel = newKey("KEY_MENU_NEW_LEVEL", Lang.optionKeyMenuNewLevel, ALLEGRO_KEY_F1);
    keyMenuExport = newKey("KEY_MENU_EXPORT", Lang.optionKeyMenuExport, ALLEGRO_KEY_R);
    keyMenuDelete = newKey2("KEY_MENU_DELETE", Lang.optionKeyMenuDelete, ALLEGRO_KEY_G, ALLEGRO_KEY_DELETE);
    keyMenuSearch = newKey("KEY_MENU_SEARCH", Lang.browserSearch, ALLEGRO_KEY_SLASH);
    keyMenuUpDir = newKey("KEY_MENU_UP_DIR", Lang.optionKeyMenuUpDir, ALLEGRO_KEY_A);
    keyMenuUpBy1 = newKey2("KEY_MENU_UP_1", Lang.optionKeyMenuUpBy1, ALLEGRO_KEY_S, ALLEGRO_KEY_UP);
    keyMenuUpBy5 = newKey("KEY_MENU_UP_5", Lang.optionKeyMenuUpBy5, ALLEGRO_KEY_W);
    keyMenuDownBy1 = newKey2("KEY_MENU_DOWN_1", Lang.optionKeyMenuDownBy1, ALLEGRO_KEY_D, ALLEGRO_KEY_DOWN);
    keyMenuDownBy5 = newKey("KEY_MENU_DOWN_5", Lang.optionKeyMenuDownBy5, ALLEGRO_KEY_E);
    keyMenuExit = newKey("KEY_MENU_EXIT", Lang.optionKeyMenuExit, ALLEGRO_KEY_ESCAPE);
    keyMenuMainSingle = newKey("KEY_MENU_MAIN_SINGLE", Lang.browserSingleTitle, ALLEGRO_KEY_F);
    keyMenuMainNetwork = newKey("KEY_MENU_MAIN_NETWORK", Lang.winLobbyTitle, ALLEGRO_KEY_D);
    keyMenuMainReplays = newKey("KEY_MENU_MAIN_REPLAY", Lang.browserReplayTitle, ALLEGRO_KEY_S);
    keyMenuMainOptions = newKey("KEY_MENU_MAIN_OPTIONS", Lang.optionTitle, ALLEGRO_KEY_A);

    keyEditorLeft = newKey2("KEY_EDITOR_LEFT", Lang.optionEdLeft, ALLEGRO_KEY_S, ALLEGRO_KEY_LEFT);
    keyEditorRight = newKey2("KEY_EDITOR_RIGHT", Lang.optionEdRight, ALLEGRO_KEY_F, ALLEGRO_KEY_RIGHT);
    keyEditorUp = newKey2("KEY_EDITOR_UP", Lang.optionEdUp, ALLEGRO_KEY_E, ALLEGRO_KEY_UP);
    keyEditorDown = newKey2("KEY_EDITOR_DOWN", Lang.optionEdDown, ALLEGRO_KEY_D, ALLEGRO_KEY_DOWN);
    keyEditorSave = newOpt("KEY_EDITOR_SAVE", Lang.optionEdSave, KeySet());
    keyEditorSaveAs = newOpt("KEY_EDITOR_SAVE_AS", Lang.optionEdSaveAs, KeySet());
    keyEditorCopy = newKey("KEY_EDITOR_COPY", Lang.optionEdCopy, ALLEGRO_KEY_A);
    keyEditorDelete = newKey2("KEY_EDITOR_DELETE", Lang.optionEdDelete, ALLEGRO_KEY_G, ALLEGRO_KEY_DELETE);
    keyEditorGrid = newKey("KEY_EDITOR_GRID", Lang.optionEdGrid, ALLEGRO_KEY_C);
    keyEditorSelectAll = newKey("KEY_EDITOR_SELECT_ALL", Lang.optionEdSelectAll, ALLEGRO_KEY_ALT);
    keyEditorSelectFrame = newKey("KEY_EDITOR_SELECT_FRAME", Lang.optionEdSelectFrame, ALLEGRO_KEY_LSHIFT);
    keyEditorSelectAdd = newKey("KEY_EDITOR_SELECT_ADD", Lang.optionEdSelectAdd, ALLEGRO_KEY_V);
    keyEditorGroup = newKey("KEY_EDITOR_GROUP", Lang.optionEdGroup, ALLEGRO_KEY_Q);
    keyEditorUngroup = newOpt("KEY_EDITOR_UNGROUP", Lang.optionEdUngroup, KeySet());
    keyEditorForeground = newKey("KEY_EDITOR_FOREGROUND", Lang.optionEdForeground, ALLEGRO_KEY_T);
    keyEditorBackground = newKey("KEY_EDITOR_BACKGROUND", Lang.optionEdBackground, ALLEGRO_KEY_B);
    keyEditorMirror = newKey("KEY_EDITOR_MIRROR", Lang.optionEdMirror, ALLEGRO_KEY_W);
    keyEditorRotate = newKey("KEY_EDITOR_ROTATE", Lang.optionEdRotate, ALLEGRO_KEY_R);
    keyEditorDark = newKey("KEY_EDITOR_DARK", Lang.optionEdDark, ALLEGRO_KEY_X);
    keyEditorAddTerrain = newKey("KEY_EDITOR_ADD_TERRAIN", Lang.optionEdAddTerrain, ALLEGRO_KEY_SPACE);
    keyEditorAddSteel = newKey("KEY_EDITOR_ADD_STEEL", Lang.optionEdAddSteel, ALLEGRO_KEY_TAB);
    keyEditorAddHatch = newKey("KEY_EDITOR_ADD_HATCH", Lang.optionEdAddHatch, ALLEGRO_KEY_1);
    keyEditorAddGoal = newKey("KEY_EDITOR_ADD_GOAL", Lang.optionEdAddGoal, ALLEGRO_KEY_2);
    keyEditorAddHazard = newKey("KEY_EDITOR_ADD_HAZARD", Lang.optionEdAddHazard, ALLEGRO_KEY_4);
    keyEditorMenuConstants = newKey("KEY_EDITOR_MENU_CONSTANTS", Lang.winConstantsTitle, ALLEGRO_KEY_5);
    keyEditorMenuTopology = newKey("KEY_EDITOR_MENU_TOPOLOGY", Lang.winTopologyTitle, ALLEGRO_KEY_6);
    keyEditorMenuLooks = newKey("KEY_EDITOR_MENU_LOOKS", Lang.winLooksTitle, ALLEGRO_KEY_7);
    keyEditorMenuSkills = newKey("KEY_EDITOR_MENU_SKILLS", Lang.winSkillsTitle, ALLEGRO_KEY_8);
    keyEditorExit = newKey("KEY_EDITOR_EXIT", Lang.commonExit, ALLEGRO_KEY_ESCAPE);

    _optvecLoad.rehash();
}

// ############################################################################

private Filename userFileName()
{
    return new VfsFilename(dirDataUser.dirRootless
     ~ basics.help.escapeStringForFilename(userName)
     ~ filenameExtConfig);
}

void load()
{
    if (userName == null)
        // This happens upon first start after installation.
        // Don't try to load anything, and don't log anything.
        return;

    IoLine[] lines;
    try
        lines = fillVectorFromFile(userFileName());
    catch (Exception e) {
        log("Can't load user configuration for `" ~ userName ~ "':");
        log("    -> " ~ e.msg);
        log("    -> Falling back to the unescaped filename `"
            ~ userName ~ filenameExtConfig ~ "'.");
        try {
            lines = fillVectorFromFile(new VfsFilename(
                dirDataUser.dirRootless ~ userName ~ filenameExtConfig));
        }
        catch (Exception e) {
            log("    -> " ~ e.msg);
            log("    -> " ~ "Falling back to the default user configuration.");
            lines = null;
        }
    }
    _trophies = null;

    foreach (i; lines) {
        if (i.type == '<') {
            import std.string;
            auto fn = rebindable!(const Filename)(new VfsFilename(
                // Backwards compat for renaming Simple to Lovely:
                // Load all old user _trophies. We would save with the new name.
                // Remove the call to replace during early 2018.
                i.text1.replace("lemforum/Simple/", "lemforum/Lovely/")
            ));
            Trophy read = Trophy(i.text2, i.nr1, i.nr2, i.nr3);

            // Don't call addTrophy because that always overwrites the date.
            // We want the newest date here to tiebreak, unlike addTrophy.
            Trophy* old = (fn in _trophies);
            if (! old || read.shouldReplaceDuringUserDataLoad(*old))
                _trophies[fn] = read;
        }
        else if (auto opt = i.text1 in _optvecLoad)
            opt.set(i);

        // Backwards compatibility: Before 0.6.2, I had hacked in two hotkeys
        // for pause that saved to different variables. Load this other var.
        else if (i.nr1 != 0 && i.text1 == "KEY_PAUSE2")
            keyPause.value = KeySet(keyPause.value, KeySet(i.nr1));
        // Backwards compatibility: Before 0.9.7, I had a boolean for windowed
        // mode (0 = software fullscreen, 1 = windowed), but now I have a
        // three-valued int option (0 = windowed, 1 = software fullscreen,
        // 2 = hardware fullscreen).
        else if (i.text1 == "SCREEN_WINDOWED")
            screenMode.value = i.nr1 == 1 ? ScreenMode.windowed
                                          : ScreenMode.softwareFullscreen;
    }
}

nothrow void save()
{
    if (userName == null) {
        log("User name is empty. User configuration will not be saved.");
        return;
    }
    try {
        auto f = userFileName.openForWriting();
        foreach (opt; _optvecSave)
            f.writeln(opt.ioLine);
        f.writeln();
        foreach (key, r; _trophies)
            f.writeln(IoLine.Angle(key.rootless,
                r.lixSaved, r.skillsUsed, r.phyusUsed, r.built.toString));
    }
    catch (Exception e) {
        log("Can't save user configuration for `" ~ userName ~ "':");
        log("    -> " ~ e.msg);
    }
}
