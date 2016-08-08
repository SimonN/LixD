module basics.user;

/* User settings read from the user config file. This file differs from the
 * global config file, see globconf.d. Whenever the user file doesn't exist,
 * the default values from static this() are used.
 */

import std.typecons; // rebindable
import std.algorithm; // sort filenames before outputting them
import std.conv;
import std.file; // mkdirRecurse
import std.stdio;

import enumap;

import basics.alleg5;
import basics.globals;
import basics.globconf;
import basics.help;
import basics.nettypes;
import file.filename;
import file.date;
import file.io;
import file.language;
import file.log; // when writing to disk fails
import file.useropt;
import lix.enums;
import hardware.keynames;
import hardware.keyset;

/*  static this();
 *  void load();
 *  void save();
 *  const(Result) getLevelResult         (Filename);
 *  void          setLevelResultCarefully(Filename, Result, in int);
 */

private Result[Filename] results;

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

UserOptionFilename fileLanguage;
UserOption!int optionGroup;

UserOption!int mouseSpeed;
UserOption!int scrollSpeedEdge;
UserOption!int scrollSpeedClick;
UserOption!bool fastMovementFreesMouse;
UserOption!bool avoidBuilderQueuing;
UserOption!bool avoidBatterToExploder;
UserOption!int pausedAssign; // 0 = nothing (allows multiple assignments),
                             // 1 = advance 1 frame, 2 = unpause
UserOption!bool screenWindowed;
UserOption!int screenWindowedX;
UserOption!int screenWindowedY;
UserOption!bool paintTorusSeams;
UserOption!bool ingameTooltips;
UserOption!bool showButtonHotkeys;
UserOption!bool showFPS;
UserOption!int guiColorRed;
UserOption!int guiColorGreen;
UserOption!int guiColorBlue;
UserOption!int soundVolume;

UserOptionFilename singleLastLevel;
UserOptionFilename networkLastLevel;
UserOptionFilename replayLastLevel;
UserOption!int networkLastStyle;
UserOption!bool replayAutoSolutions;
UserOption!bool replayAutoMulti;

UserOption!int  editorGridSelected;
UserOption!int  editorGridCustom;
UserOptionFilename editorLastDirTerrain;
UserOptionFilename editorLastDirSteel;
UserOptionFilename editorLastDirHatch;
UserOptionFilename editorLastDirGoal;
UserOptionFilename editorLastDirDeco;
UserOptionFilename editorLastDirHazard;

UserOption!KeySet
    keyScroll,
    keyPriorityInvert,
    keyZoomIn,
    keyZoomOut,

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
    keySpecTribe,
    keyChat,
    keyGameExit,

    keyMenuOkay,
    keyMenuEdit,
    keyMenuExport,
    keyMenuDelete,
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
    keyEditorAddDeco,
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
    scrollSpeedClick = newOpt("SCROLL_SPEED_CLICK", Lang.optionScrollSpeedClick, mouseStandardDivisor / 2);
    fastMovementFreesMouse = newOpt("FAST_MOVEMENT_FREES_MOUSE", Lang.optionFastMovementFreesMouse, true);
    avoidBuilderQueuing = newOpt("AVOID_BUILDER_QUEUING", Lang.optionAvoidBuilderQueuing, true);
    avoidBatterToExploder = newOpt("AVOID_BATTER_TO_EXPLODER", Lang.optionAvoidBatterToExploder, false);
    pausedAssign = newOpt("PAUSED_ASSIGN", Lang.optionPausedAssign, 1);

    screenWindowed = newOpt("SCREEN_WINDOWED", Lang.optionScreenWindowed, false);
    screenWindowedX = newOpt("SCREEN_WINDOWED_X", Lang.optionScreenWindowedRes, 640);
    screenWindowedY = newOpt("SCREEN_WINDOWED_Y", 480);
    paintTorusSeams = newOpt("PAINT_TORUS_SEAMS", Lang.optionPaintTorusSeams, true);
    ingameTooltips = newOpt("INGAME_TOOLTIPS", Lang.optionIngameTooltips, true);
    showButtonHotkeys = newOpt("SHOW_BUTTON_HOTKEYS", Lang.optionShowButtonHotkeys, true);
    showFPS = newOpt("SHOW_FPS", Lang.optionShowFPS, true);
    guiColorRed = newOpt("GUI_COLOR_RED", Lang.optionGuiColorRed, 0x60);
    guiColorGreen = newOpt("GUI_COLOR_GREEN", Lang.optionGuiColorGreen, 0x80);
    guiColorBlue = newOpt("GUI_COLOR_BLUE", Lang.optionGuiColorBlue, 0xB0);
    soundVolume = newOpt("SOUND_VOLUME", Lang.optionSoundVolume, 10);

    singleLastLevel = newOpt("SINGLE_LAST_LEVEL", dirLevelsSingle);
    networkLastLevel = newOpt("NETWORK_LAST_LEVEL", dirLevelsNetwork);
    replayLastLevel = newOpt("REPLAY_LAST_LEVEL", dirReplays);
    networkLastStyle = newOpt("NETWORK_LAST_STYLE", Style.red.to!int);

    replayAutoSolutions = newOpt("REPLAY_AUTO_SAVE_SOLUTIONS", Lang.optionReplayAutoSolutions, true);
    replayAutoMulti = newOpt("REPLAY_AUTO_SAVE_MULTI", Lang.optionReplayAutoMulti, true);

    editorLastDirTerrain = newOpt("EDITOR_LAST_DIR_TERRAIN", Lang.addTerrain, dirImages);
    editorLastDirSteel = newOpt("EDITOR_LAST_DIR_STEEL", Lang.addSteel, dirImages);
    editorLastDirHatch = newOpt("EDITOR_LAST_DIR_HATCH", Lang.addHatch, dirImages);
    editorLastDirGoal = newOpt("EDITOR_LAST_DIR_GOAL", Lang.addGoal, dirImages);
    editorLastDirDeco = newOpt("EDITOR_LAST_DIR_DECO", Lang.addDeco, dirImages);
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
    keySpecTribe = newKey("KEY_SPECTATE_NEXT_PLAYER", Lang.optionKeySpecTribe, ALLEGRO_KEY_TAB);
    keyChat = newKey("KEY_CHAT", Lang.optionKeyChat, ALLEGRO_KEY_ENTER);
    keyGameExit = newKey("KEY_GAME_EXIT", Lang.winGameTitle, ALLEGRO_KEY_ESCAPE);

    keyMenuOkay = newKey("KEY_MENU_OKAY", Lang.optionKeyMenuOkay, ALLEGRO_KEY_SPACE);
    keyMenuEdit = newKey("KEY_MENU_EDIT", Lang.optionKeyMenuEdit, ALLEGRO_KEY_F);
    keyMenuExport = newKey("KEY_MENU_EXPORT", Lang.optionKeyMenuExport, ALLEGRO_KEY_R);
    keyMenuDelete = newKey2("KEY_MENU_DELETE", Lang.optionKeyMenuDelete, ALLEGRO_KEY_G, ALLEGRO_KEY_DELETE);
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
    keyEditorAddDeco = newKey("KEY_EDITOR_ADD_DECO", Lang.optionEdAddDeco, ALLEGRO_KEY_3);
    keyEditorAddHazard = newKey("KEY_EDITOR_ADD_HAZARD", Lang.optionEdAddHazard, ALLEGRO_KEY_4);
    keyEditorMenuConstants = newKey("KEY_EDITOR_MENU_CONSTANTS", Lang.winConstantsTitle, ALLEGRO_KEY_5);
    keyEditorMenuTopology = newKey("KEY_EDITOR_MENU_TOPOLOGY", Lang.winTopologyTitle, ALLEGRO_KEY_6);
    keyEditorMenuLooks = newKey("KEY_EDITOR_MENU_LOOKS", Lang.winLooksTitle, ALLEGRO_KEY_7);
    keyEditorMenuSkills = newKey("KEY_EDITOR_MENU_SKILLS", Lang.winSkillsTitle, ALLEGRO_KEY_8);
    keyEditorExit = newKey("KEY_EDITOR_EXIT", Lang.commonExit, ALLEGRO_KEY_ESCAPE);

    _optvecLoad.rehash();
}

// ############################################################################

class Result {
    const(Date) built;
    int    lixSaved;
    int    skillsUsed;
    Update updatesUsed;

    this (const(Date) bu)
    {
        built = bu;
    }

    int opEquals(in Result rhs) const
    {
        return built       == rhs.built
            && lixSaved    == rhs.lixSaved
            && skillsUsed  == rhs.skillsUsed
            && updatesUsed == rhs.updatesUsed;
    }

    // Returns < 0 on a worse rhs result, > 0 for a better rhs result.
    // The user wouldn't want to replace an old solving result with
    // a new-built-using non-solving result.
    // To check in results into the database of solved levels, use
    // setLevelResult() from this module.
    int opCmp(in Result rhs) const
    {
        if (lixSaved != rhs.lixSaved)
            return lixSaved - rhs.lixSaved; // more lix saved is better
        if (skillsUsed != rhs.skillsUsed)
            return rhs.skillsUsed - skillsUsed; // fewer skills used is better
        if (updatesUsed != rhs.updatesUsed)
            return rhs.updatesUsed - updatesUsed; // less time taken is better
        return built.opCmp(rhs.built); // newer result better
    }

    unittest {
        Result a = new Result(Date.now());
        Result b = new Result(Date.now());
        a.lixSaved = 4;
        b.lixSaved = 5;
        assert (b > a);
        b.lixSaved = 4;
        assert (a >= b);
        b.updatesUsed = 1;
        assert (a > b);
    }
}

const(Result) getLevelResult(in Filename fn)
{
    Result* ret = (rebindable!(const Filename)(fn) in results);
    return ret ? (*ret) : null;
}

void setLevelResult(
    in Filename _fn,
    Result r,
) {
    auto fn = rebindable!(const Filename)(_fn);
    auto savedResult = (fn in results);
    if (savedResult is null
        || savedResult.built != r.built
        || *savedResult < r)
        results[fn] = r;
}

// ############################################################################

private Filename userFileName()
{
    return new Filename(dirDataUser.dirRootful
     ~ basics.help.escapeStringForFilename(userName)
     ~ filenameExtConfig);
}

void load()
{
    if (userName == null) {
        // This happens upon first start after installation.
        // Don't try to load anything, and don't log anything.
        return;
    }

    while (basics.globconf.userName.length > playerNameMaxLength) {
        userName = basics.help.backspace(userName);
    }

    IoLine[] lines;

    try {
        lines = fillVectorFromFile(userFileName());
    }
    catch (Exception e) {
        log("Can't load user configuration for `" ~ userName ~ "':");
        log("    -> " ~ e.msg);
        log("    -> Falling back to the unescaped filename `"
            ~ userName ~ filenameExtConfig ~ "'.");
        try {
            lines = fillVectorFromFile(new Filename(
                dirDataUser.dirRootful ~ userName ~ filenameExtConfig));
        }
        catch (Exception e) {
            log("    -> " ~ e.msg);
            log("    -> " ~ "Falling back to the default user configuration.");
            lines = null;
        }
    }
    results = null;

    foreach (i; lines) {
        if (i.type == '<') {
            auto fn = rebindable!(const Filename)(new Filename(i.text1));
            Result read = new Result(new Date(i.text2));
            read.lixSaved    = i.nr1;
            read.skillsUsed  = i.nr2;
            read.updatesUsed = Update(i.nr3);
            Result* old = (fn in results);
            if (! old || *old < read)
                results[fn] = read;
        }
        else if (auto opt = i.text1 in _optvecLoad)
            opt.set(i);
        // Backwards compatibility: Before 0.6.2, I had hacked in two hotkeys
        // for pause that saved to different variables. Load this other var.
        else if (i.nr1 != 0 && i.text1 == "KEY_PAUSE2")
            keyPause.value = KeySet(keyPause.value, KeySet(i.nr1));
    }
}

nothrow void save()
{
    if (userName == null) {
        log("User name is empty. User configuration will not be saved.");
        return;
    }
    else if (userName.escapeStringForFilename == null) {
        log("Can't save user configuration for user `" ~ "':");
        log("    -> None of these characters are allowed in filenames.");
    }
    try {
        auto ufn = userFileName();
        mkdirRecurse(ufn.dirRootful);
        std.stdio.File f = File(ufn.rootful, "w");

        foreach (opt; _optvecSave)
            f.writeln(opt.ioLine);
        f.writeln();
        foreach (key, r; results)
            f.writeln(IoLine.Angle(key.rootless,
                r.lixSaved, r.skillsUsed, r.updatesUsed, r.built.toString));
    }
    catch (Exception e) {
        log("Can't save user configuration for `" ~ userName ~ "':");
        log("    -> " ~ e.msg);
    }
}
