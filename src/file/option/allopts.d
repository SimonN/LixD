module file.option.allopts;

/*
 * User settings. Class objects will be initialized by initializeIfNecessary(),
 * called from file.option.saveload.
 *
 * Later, their values will be read in from the user config file.
 * Whenever the user file doesn't exist, the default values from
 * initializeIfNecessary() are used.
 */

import std.typecons; // rebindable
import std.algorithm; // sort filenames before outputting them
import std.conv;

import enumap;
import optional;

import basics.alleg5;
import basics.globals;
import file.option;
import basics.help;
import file.filename;
import file.io;
import file.language;
import file.option;
import hardware.keyenum;
import hardware.keyset;
import hardware.tharsis;
import net.ac;
import net.style;

// These is only for iteration during option saving/loading.
// Outside of this package, refer to options by their static variable name.
package AbstractUserOption[string] _optvecLoad;
package AbstractUserOption[] _optvecSave;

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

Filename fileLanguage()
{
    return new VfsFilename(dirDataTransl.dirRootless
        ~ (languageBasenameNoExt is null ? "" : languageBasenameNoExt.value)
        ~ ".txt");
}

bool languageIsEnglish()
{
    assert (fileLanguage !is null);
    return fileLanguage.fileNoExtNoPre == basics.globals.englishBasenameNoExt;
}

string userName() { return userNameOption is null ? "" : userNameOption.value;}
UserOption!string userNameOption; // userName is string for back-compat

UserOption!string languageBasenameNoExt;
UserOption!int optionGroup;

UserOption!bool soundEnabled;
UserOption!bool musicEnabled;
UserOption!int soundDecibels;
UserOption!int musicDecibels;
UserOption!bool replayAutoSolutions;
UserOption!bool replayAutoMulti;

UserOption!int screenType; // Read through file.option.screen.screenChoice
UserOption!int screenWindowedX;
UserOption!int screenWindowedY;
UserOption!int screenHardwareFullscreenX;
UserOption!int screenHardwareFullscreenY;
UserOption!bool allowBlurryZoom;
UserOption!int splatRulerDesign;
UserOption!int splatRulerSnapPixels;
UserOption!bool paintTorusSeams;
UserOption!bool ingameTooltips;
UserOption!bool showFPS;

UserOption!int mouseSpeed;
UserOption!int scrollSpeedEdge;
UserOption!int holdToScrollSpeed;
UserOption!bool holdToScrollInvert;
UserOption!bool fastMovementFreesMouse;

UserOption!bool replayAfterFrameBack;
UserOption!bool airClicksCutWhenTweakerHidden;
UserOption!bool airClicksCutWhenTweakerShown;
UserOption!bool insertAssignmentsWhenTweakerHidden;
UserOption!bool insertAssignmentsWhenTweakerShown;

UserOption!bool avoidBuilderQueuing;
UserOption!bool avoidBatterToExploder;
UserOption!bool unpauseOnAssign;

UserOption!int networkLastStyle;
UserOption!int networkConnectionMethod;
UserOption!string networkCentralServerAddress;
UserOption!int networkCentralServerPort;
UserOption!string networkOwnServerAddress;
UserOption!int networkOwnServerPort;
UserOption!string networkConnectToAddress;
UserOption!int networkConnectToPort;

UserOption!int editorGridSelected;
UserOption!int editorGridCustom;
UserOption!int editorCopiedTilesOffest;

UserOption!int guiColorRed;
UserOption!int guiColorGreen;
UserOption!int guiColorBlue;

UserOptionFilename singleLastLevel;
UserOptionFilename networkLastLevel;
UserOptionFilename replayLastLevel;
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
    keyShowTweaker,
    keyNuke,
    keyChat,
    keyShowSplatRuler,
    keyHighlightGoals,
    keyGameExit,

    keyMenuOkay,
    keyMenuEdit,
    keyMenuNewLevel,
    keyMenuRepForLev,
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

    keyOutcomeSaveReplay,
    keyOutcomeOldLevel,
    keyOutcomeNextLevel,
    keyOutcomeNextUnsolved,

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
    keyEditorUndo,
    keyEditorRedo,
    keyEditorGroup,
    keyEditorUngroup,
    keyEditorBackground,
    keyEditorForeground,
    keyEditorMirrorHorizontally,
    keyEditorFlipVertically,
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
    keyEditorMenuSkills;

Enumap!(Ac, UserOption!KeySet) keySkill;

const(Ac[14]) skillSort() nothrow @safe @nogc { return _skillSort; }

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

/*
 * This cannot be "static this()" because on macOS 10.14, that would run in
 * a different thread than what runs in al_run_main. That would lead to
 * segfaults when we later access the non-null non-shared mutable options.
 */
void initializeIfNecessary()
out { assert (languageBasenameNoExt !is null); }
do {
    if (languageBasenameNoExt !is null) {
        // We've already created all class objects.
        // Nothing to initialize, caller can take and change their values.
        return;
    }
    userNameOption = newOpt("userName", Lang.optionUserName, "");
    languageBasenameNoExt = newOpt("language", Lang.optionLanguage, englishBasenameNoExt);
    optionGroup = newOpt("optionGroup", 0);

    soundEnabled = newOpt("soundEnabled", Lang.optionSoundEnabled, true);
    musicEnabled = newOpt("musicEnabled", Lang.optionMusicEnabled, true);
    soundDecibels = newOpt("soundDecibels", Lang.optionSoundDecibels, 0);
    musicDecibels = newOpt("musicDecibels", Lang.optionMusicDecibels, -10);
    replayAutoSolutions = newOpt("replayAutoSaveSolutions", Lang.optionReplayAutoSolutions, true);
    replayAutoMulti = newOpt("replayAutoSaveMulti", Lang.optionReplayAutoMulti, true);

    screenType = newOpt("screenMode", Lang.optionScreenWindowed,
        defaultScreenType.to!int);
    screenWindowedX = newOpt("screenWindowedX", Lang.optionScreenWindowedRes, 1280);
    screenWindowedY = newOpt("screenWindowedY", 720);
    screenHardwareFullscreenX = newOpt("screenHardwareFullscreenX",
        Lang.optionScreenHardwareFullscreenRes, 640);
    screenHardwareFullscreenY = newOpt("screenHardwareFullscreenY", 480);
    allowBlurryZoom = newOpt("allowBlurryZoom", Lang.optionAllowBlurryZoom, true);
    splatRulerDesign = newOpt("splatRulerDesign", Lang.optionSplatRulerDesign3Bars, 2);
    splatRulerSnapPixels = newOpt("splatRulerSnapPixels", Lang.optionSplatRulerSnapPixels, 126);
    paintTorusSeams = newOpt("paintTorusSeams", Lang.optionPaintTorusSeams, false);
    ingameTooltips = newOpt("ingameTooltips", Lang.optionIngameTooltips, true);
    version (assert) {
        showFPS = newOpt("showFramesPerSecond", Lang.optionShowFPS, true);
    }
    else {
        showFPS = newOpt("showFramesPerSecond", Lang.optionShowFPS, false);
    }

    version (linux) {
        mouseSpeed = newOpt("mouseSpeed", Lang.optionMouseSpeed,
            mouseStandardDivisor / 2);
        fastMovementFreesMouse = newOpt("fastMovementFreesMouse",
            Lang.optionFastMovementFreesMouse, false);
    }
    else {
        mouseSpeed = newOpt("mouseSpeed", Lang.optionMouseSpeed,
            mouseStandardDivisor);
        fastMovementFreesMouse = newOpt("fastMovementFreesMouse",
            Lang.optionFastMovementFreesMouse, true);
    }
    scrollSpeedEdge = newOpt("edgeScrollSpeed", Lang.optionScrollSpeedEdge, mouseStandardDivisor);
    holdToScrollSpeed = newOpt("holdToScrollSpeed", Lang.optionHoldToScrollSpeed, mouseStandardDivisor / 2);
    holdToScrollInvert = newOpt("holdToScrollInvert", Lang.optionHoldToScrollInvert, false);

    replayAfterFrameBack = newOpt("replayAfterFrameBack",
        Lang.optionRewindIsBrowse, true);
    airClicksCutWhenTweakerHidden = newOpt("airClicksCutWhenTweakerHidden",
        Lang.optionAirClicksCut, true);
    airClicksCutWhenTweakerShown = newOpt("airClicksCutWhenTweakerShown",
        Lang.optionAirClicksCut, false);
    insertAssignmentsWhenTweakerHidden = newOpt("insertAssignmentsWhenTweakerHidden",
        Lang.optionInsertAssignments, false);
    insertAssignmentsWhenTweakerShown = newOpt("insertAssignmentsWhenTweakerShown",
        Lang.optionInsertAssignments, true);

    avoidBuilderQueuing = newOpt("avoidBuilderQueuing", Lang.optionAvoidBuilderQueuing, true);
    avoidBatterToExploder = newOpt("avoidBatterToExploder", Lang.optionAvoidBatterToExploder, false);
    unpauseOnAssign = newOpt("unpauseOnAssign", Lang.optionUnpauseOnAssign, false);

    networkLastStyle = newOpt("networkLastStyle", Style.red.to!int);
    networkConnectionMethod = newOpt("networkConnectionMethod", Lang.winLobbyStartCustom, 0);
    networkCentralServerAddress = newOpt("networkCentralServerAddress", "lixgame.com");
    networkCentralServerPort = newOpt("networkCentralServerPort", 22934);
    networkOwnServerAddress = newOpt("networkOwnServerAddress", "127.0.0.1");
    networkOwnServerPort = newOpt("networkOwnServerPort", 22934);
    networkConnectToAddress = newOpt("networkConnectToAddress", "127.0.0.1");
    networkConnectToPort = newOpt("networkConnectToPort", 22934);

    editorGridSelected = newOpt("editorGridSelected", 2);
    editorGridCustom = newOpt("editorGridCustom", Lang.optionEdGridCustom, 8);
    editorCopiedTilesOffest = newOpt("editorCopiedTilesOffest", 16);

    guiColorRed = newOpt("guiColorRed", Lang.optionGuiColorRed, 0x60);
    guiColorGreen = newOpt("guiColorGreen", Lang.optionGuiColorGreen, 0x80);
    guiColorBlue = newOpt("guiColorBlue", Lang.optionGuiColorBlue, 0xB0);

    singleLastLevel = newOpt("singleLastLevel", fileSingleplayerFirstLevel);
    networkLastLevel = newOpt("networkLastLevel", dirLevelsNetwork);
    replayLastLevel = newOpt("replayLastLevel", dirReplays);
    editorLastDirTerrain = newOpt("editorLastDirTerrain", Lang.addTerrain, dirImages);
    editorLastDirSteel = newOpt("editorLastDirSteel", Lang.addSteel,
        cast (Filename) new VfsFilename(dirImages.rootless ~ "geoo/steel/"));
    editorLastDirHatch = newOpt("editorLastDirHatch", Lang.addHatch, dirImages);
    editorLastDirGoal = newOpt("editorLastDirGoal", Lang.addGoal, dirImages);
    editorLastDirHazard = newOpt("editorLastDirHazard", Lang.addHazard, dirImages);

    void newSkillKey(Ac ac, int singleKey)
    {
        keySkill[ac] = newOpt(
            "keySkill" ~ ac.acToNiceCase.to!string, KeySet(singleKey));
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
    keyScroll = newKey("keyHoldToScroll", Lang.optionKeyScroll, hardware.keyenum.keyRMB);
    keyPriorityInvert = newKey("keyPriorityInvert", Lang.optionKeyPriorityInvert, hardware.keyenum.keyRMB);
    keyZoomIn = newKey("keyZoomIn", Lang.optionKeyZoomIn, hardware.keyenum.keyWheelUp);
    keyZoomOut = newKey("keyZoomOut", Lang.optionKeyZoomOut, hardware.keyenum.keyWheelDown);
    keyScreenshot = newOpt("keyScreenshot", Lang.optionKeyScreenshot,
        KeySet());

    // Game keys
    keyForceLeft = newKey2("keyForceLeft", Lang.optionKeyForceLeft, ALLEGRO_KEY_S, ALLEGRO_KEY_LEFT);
    keyForceRight = newKey2("keyForceRight", Lang.optionKeyForceRight, ALLEGRO_KEY_F, ALLEGRO_KEY_RIGHT);
    keyPause = newKey2("keyPause", Lang.optionKeyPause, ALLEGRO_KEY_SPACE, hardware.keyenum.keyMMB);
    keyFrameBackMany = newKey("keySpeedBackMany", Lang.optionKeyFrameBackMany, ALLEGRO_KEY_1);
    keyFrameBackOne = newKey("keySpeedBackOne", Lang.optionKeyFrameBackOne, ALLEGRO_KEY_2);
    keyFrameAheadOne = newKey("keySpeedAheadOne", Lang.optionKeyFrameAheadOne, ALLEGRO_KEY_3);
    keyFrameAheadMany = newKey("keySpeedAheadMany", Lang.optionKeyFrameAheadMany, ALLEGRO_KEY_6);
    keySpeedFast = newKey("keySpeedFast", Lang.optionKeySpeedFast, ALLEGRO_KEY_4);
    keySpeedTurbo = newKey("keySpeedTurbo", Lang.optionKeySpeedTurbo, ALLEGRO_KEY_5);
    keyRestart = newKey("keyRestart", Lang.optionKeyRestart, ALLEGRO_KEY_F1);
    keyStateLoad = newKey("keyStateLoad", Lang.optionKeyStateLoad, ALLEGRO_KEY_F2);
    keyStateSave = newKey("keyStateSave", Lang.optionKeyStateSave, ALLEGRO_KEY_F3);
    keyShowTweaker = newKey("keyShowTweaker", Lang.optionKeyShowTweaker, ALLEGRO_KEY_F4);
    keyNuke = newKey("keyNuke", Lang.optionKeyNuke, ALLEGRO_KEY_F12);
    keyShowSplatRuler = newKey("keyShowSplatRuler", Lang.optionKeyShowSplatRuler, ALLEGRO_KEY_TAB);
    keyHighlightGoals = newOpt("keyHighlightGoals", Lang.optionKeyHighlightGoals, KeySet());
    keyChat = newKey("keyChat", Lang.optionKeyChat, ALLEGRO_KEY_ENTER);
    keyGameExit = newKey("keyGameExit", Lang.winAbortNetgameTitle, ALLEGRO_KEY_ESCAPE);

    keyMenuOkay = newKey("keyMenuOkay", Lang.optionKeyMenuOkay, ALLEGRO_KEY_SPACE);
    keyMenuEdit = newKey("keyMenuEdit", Lang.optionKeyMenuEdit, ALLEGRO_KEY_F);
    keyMenuRepForLev = newOpt("keyMenuRepForLev", Lang.optionKeyMenuRepForLev, KeySet());
    keyMenuNewLevel = newKey("keyMenuNewLevel", Lang.optionKeyMenuNewLevel, ALLEGRO_KEY_F1);
    keyMenuExport = newKey("keyMenuExport", Lang.optionKeyMenuExport, ALLEGRO_KEY_R);
    keyMenuDelete = newKey2("keyMenuDelete", Lang.optionKeyMenuDelete, ALLEGRO_KEY_G, ALLEGRO_KEY_DELETE);
    keyMenuSearch = newKey("keyMenuSearch", Lang.browserSearch, ALLEGRO_KEY_SLASH);
    keyMenuUpDir = newKey("keyMenuUpDir", Lang.optionKeyMenuUpDir, ALLEGRO_KEY_A);
    keyMenuUpBy1 = newKey2("keyMenuUp1", Lang.optionKeyMenuUpBy1, ALLEGRO_KEY_S, ALLEGRO_KEY_UP);
    keyMenuUpBy5 = newKey("keyMenuUp5", Lang.optionKeyMenuUpBy5, ALLEGRO_KEY_W);
    keyMenuDownBy1 = newKey2("keyMenuDown1", Lang.optionKeyMenuDownBy1, ALLEGRO_KEY_D, ALLEGRO_KEY_DOWN);
    keyMenuDownBy5 = newKey("keyMenuDown5", Lang.optionKeyMenuDownBy5, ALLEGRO_KEY_E);
    keyMenuExit = newKey("keyMenuExit", Lang.optionKeyMenuExit, ALLEGRO_KEY_ESCAPE);
    keyMenuMainSingle = newKey("keyMenuMainSingle", Lang.browserSingleTitle, ALLEGRO_KEY_F);
    keyMenuMainNetwork = newKey("keyMenuMainNetwork", Lang.winLobbyTitle, ALLEGRO_KEY_D);
    keyMenuMainReplays = newKey("keyMenuMainReplay", Lang.browserReplayTitle, ALLEGRO_KEY_S);
    keyMenuMainOptions = newKey("keyMenuMainOptions", Lang.optionTitle, ALLEGRO_KEY_A);

    keyOutcomeSaveReplay = newOpt("keyOutcomeSaveReplay", Lang.optionKeyOutcomeSaveReplay, KeySet());
    keyOutcomeOldLevel = newKey("keyOutcomeOldLevel", Lang.optionKeyOutcomeOldLevel, ALLEGRO_KEY_F1);
    keyOutcomeNextLevel = newKey("keyOutcomeNextLevel", Lang.optionKeyOutcomeNextLevel, ALLEGRO_KEY_SPACE);
    keyOutcomeNextUnsolved = newKey("keyOutcomeNextUnsolved", Lang.optionKeyOutcomeNextUnsolved, ALLEGRO_KEY_F);

    keyEditorLeft = newKey2("keyEditorLeft", Lang.optionEdLeft, ALLEGRO_KEY_S, ALLEGRO_KEY_LEFT);
    keyEditorRight = newKey2("keyEditorRight", Lang.optionEdRight, ALLEGRO_KEY_F, ALLEGRO_KEY_RIGHT);
    keyEditorUp = newKey2("keyEditorUp", Lang.optionEdUp, ALLEGRO_KEY_E, ALLEGRO_KEY_UP);
    keyEditorDown = newKey2("keyEditorDown", Lang.optionEdDown, ALLEGRO_KEY_D, ALLEGRO_KEY_DOWN);
    keyEditorSave = newOpt("keyEditorSave", Lang.optionEdSave, KeySet());
    keyEditorSaveAs = newOpt("keyEditorSaveAs", Lang.optionEdSaveAs, KeySet());
    keyEditorCopy = newKey("keyEditorCopy", Lang.optionEdCopy, ALLEGRO_KEY_A);
    keyEditorDelete = newKey2("keyEditorDelete", Lang.optionEdDelete, ALLEGRO_KEY_G, ALLEGRO_KEY_DELETE);
    keyEditorGrid = newKey("keyEditorGrid", Lang.optionEdGrid, ALLEGRO_KEY_C);
    keyEditorSelectAll = newKey("keyEditorSelectAll", Lang.optionEdSelectAll, ALLEGRO_KEY_ALT);
    keyEditorSelectFrame = newKey("keyEditorSelectFrame", Lang.optionEdSelectFrame, ALLEGRO_KEY_LSHIFT);
    keyEditorSelectAdd = newKey("keyEditorSelectAdd", Lang.optionEdSelectAdd, ALLEGRO_KEY_V);
    keyEditorUndo = newKey("keyEditorUndo", Lang.optionEdUndo, ALLEGRO_KEY_Z);
    keyEditorRedo = newKey("keyEditorRedo", Lang.optionEdRedo, ALLEGRO_KEY_Y);
    keyEditorGroup = newKey("keyEditorGroup", Lang.optionEdGroup, ALLEGRO_KEY_Q);
    keyEditorUngroup = newOpt("keyEditorUngroup", Lang.optionEdUngroup, KeySet());
    keyEditorForeground = newKey("keyEditorForeground", Lang.optionEdForeground, ALLEGRO_KEY_T);
    keyEditorBackground = newKey("keyEditorBackground", Lang.optionEdBackground, ALLEGRO_KEY_B);
    keyEditorMirrorHorizontally = newKey("keyEditorMirrorHorizontally", Lang.optionEdMirrorHorizontally, ALLEGRO_KEY_W);
    keyEditorFlipVertically = newOpt("keyEditorFlipVertically", Lang.optionEdFlipVertically, KeySet());
    keyEditorRotate = newKey("keyEditorRotate", Lang.optionEdRotate, ALLEGRO_KEY_R);
    keyEditorDark = newKey("keyEditorDark", Lang.optionEdDark, ALLEGRO_KEY_X);
    keyEditorAddTerrain = newKey("keyEditorAddTerrain", Lang.optionEdAddTerrain, ALLEGRO_KEY_SPACE);
    keyEditorAddSteel = newKey("keyEditorAddSteel", Lang.optionEdAddSteel, ALLEGRO_KEY_TAB);
    keyEditorAddHatch = newKey("keyEditorAddHatch", Lang.optionEdAddHatch, ALLEGRO_KEY_1);
    keyEditorAddGoal = newKey("keyEditorAddGoal", Lang.optionEdAddGoal, ALLEGRO_KEY_2);
    keyEditorAddHazard = newKey("keyEditorAddHazard", Lang.optionEdAddHazard, ALLEGRO_KEY_3);
    keyEditorMenuConstants = newKey("keyEditorMenuConstants", Lang.winConstantsTitle, ALLEGRO_KEY_4);
    keyEditorMenuTopology = newKey("keyEditorMenuTopology", Lang.winTopologyTitle, ALLEGRO_KEY_5);
    keyEditorMenuSkills = newKey("keyEditorMenuSkills", Lang.winSkillsTitle, ALLEGRO_KEY_6);
    keyEditorExit = newKey("keyEditorExit", Lang.commonExit, ALLEGRO_KEY_ESCAPE);

    _optvecLoad.rehash();
}
