module basics.globals;

import file.filename;

// globals.d contains all the compile-time _constants_ accessible from
// throughout the game. Global variables that may change are in globconf.d,
// those are the variables saved into the global config file.

// Untranslated strings; for translations of other strings see file.language
immutable nameOfTheGame = "Lix";
immutable homepageURL   = "asdfasdf.ethz.ch/~simon";

enum int ticksPerSecond       = 60;
enum int ticksForDoubleClick  = 20; // 1/3 of a second at 60 ticks/sec

enum int playerNameMaxLength  = 30;
enum int mouseStandardDivisor = 20;

immutable netIPLocalhost        = "127.0.0.1";
immutable errorWrongWorkingDir  = "Wrong working directory!\n"
                                  "Run the game from its root directory\n"
                                  "or from its subdirectory bin/.\n"
                                  "\n"
                                  "Falsches Arbeitsverzeichnis!\n"
                                  "Starte das Spiel aus seinem\n"
                                  "Wurzelverzeichnis oder aus bin/.\n";
// loading files
immutable filenameExtLevel           = ".txt";
immutable filenameExtLevelOrig       = ".lvl";
immutable filenameExtLevelLemmini    = ".ini";
immutable filenameExtReplay          = ".txt";
immutable filenameExtConfig          = ".txt";
immutable filenameExtTransl          = ".txt";
immutable filenameExtTileDefinitions = ".txt";

immutable fileLevelDirOrder   = "_order.X.txt";
immutable fileLevelDirEnglish = "_english.X.txt";
immutable fileLevelDirGerman  = "_german.X.txt";

// pre-extensions of image files
immutable preExtInternal             = 'I';
immutable preExtSteel                = 'S';
immutable preExtDeco                 = 'D';
immutable preExtHatch                = 'H';
immutable preExtGoal                 = 'G';
immutable preExtTrap                 = 'T';
immutable preExtFire                 = 'F';
immutable preExtWater                = 'W';

// keys for saving/loading the global config file
immutable cfgUserName                = "USER_NAME";
immutable cfgUserNameAsk             = "USER_NAME_ASK";

immutable cfgIPLastUsed             = "IP_LAST_USED";
immutable cfgIPCentralServer        = "IP_CENTRAL_SERVER";
immutable cfgServerPort              = "SERVER_PORT";

// keys for saving/loading level files
immutable levelBuilt                  = "BUILT";
immutable levelAuthor                 = "AUTHOR";
immutable levelNameGerman             = "GERMAN";
immutable levelNameEnglish            = "ENGLISH";
immutable levelTutorialGerman         = "TUTORIAL_GERMAN";
immutable levelTutorialEnglish        = "TUTORIAL_ENGLISH";
immutable levelHintGerman             = "HINT_GERMAN";
immutable levelHintEnglish            = "HINT_ENGLISH";
immutable levelSizeX                  = "SIZE_X";
immutable levelSizeY                  = "SIZE_Y";
immutable levelTorusX                 = "TORUS_X";
immutable levelTorusY                 = "TORUS_Y";
immutable levelBackgroundRed          = "BACKGROUND_RED";
immutable levelBackgroundGreen        = "BACKGROUND_GREEN";
immutable levelBackgroundBlue         = "BACKGROUND_BLUE";
immutable levelSeconds                = "SECONDS";
immutable levelInitial                = "INITIAL";
immutable levelInitialLegacy          = "LEMMINGS"; // backwards compatibility
immutable levelRequired               = "REQUIRED";
immutable levelSpawnintSlow           = "SPAWN_INTERVAL";
immutable levelSpawnintFast           = "SPAWN_INTERVAL_FAST";
immutable levelRateLegacy             = "RATE"; // backwards compatibility

// keys for loading objdef files, customization of interactive objects
immutable tileDefType                 = "TYPE";
immutable tileDefTAAbsoluteX          = "TRIGGER_AREA_POSITION_ABSOLUTE_X";
immutable tileDefTAAbsoluteY          = "TRIGGER_AREA_POSITION_ABSOLUTE_Y";
immutable tileDefTAFromCenterX        = "TRIGGER_AREA_POSITION_FROM_CENTER_X";
immutable tileDefTAFromCenterY        = "TRIGGER_AREA_POSITION_FROM_CENTER_Y";
immutable tileDefTAFromBottomY        = "TRIGGER_AREA_POSITION_FROM_BOTTOM_Y";
immutable tileDefTAXl                 = "TRIGGER_AREA_SIZE_X";
immutable tileDefTAYl                 = "TRIGGER_AREA_SIZE_Y";
immutable tileDefHatchOpeningFrame    = "HATCH_OPENING_FRAME";
immutable tileDefFlingNonpermanent    = "FLING_NONPERMANENT";
immutable tileDefFlingIgnoreOrientation="FLING_IGNORE_X_ORIENTATION";
immutable tileDefFlingX               = "FLING_SPEED_X";
immutable tileDefFlingY               = "FLING_SPEED_Y";

immutable tileDefTypeTerrain          = "TERRAIN";
immutable tileDefTypeSteel            = "STEEL";
immutable tileDefTypeDeco             = "DECORATION";
immutable tileDefTypeHatch            = "HATCH";
immutable tileDefTypeGoal             = "GOAL";
immutable tileDefTypeTrap             = "TRAP";
immutable tileDefTypeWater            = "WATER";
immutable tileDefTypeFire             = "FIRE";
immutable tileDefTypeFling            = "FLING";
immutable tileDefTypeTrampoline       = "TRAMPOLINE";

// keys for saving/loading replays
immutable replayGameVersionRequired   = "GAME_VERSION_REQUIRED";
immutable replayLevelBuiltRequired    = "LEVEL_BUILT_REQUIRED";
immutable replayLevelFilename         = "FILENAME";
immutable replayFriend                = "FRIEND";
immutable replayPlayer                = "PLAYER";
immutable replayPermu                 = "PERMUTATION";
immutable replayUpdate                = "UPDATE";
immutable replaySpawnint              = "SPAWNINT";
immutable replaySkill                 = "SKILL";
immutable replayNuke                  = "NUKE";
immutable replayAssignAny             = "ASSIGN";
immutable replayAssignLeft            = "ASSIGN_LEFT";
immutable replayAssignRight           = "ASSIGN_RIGHT";

// keys for saving/loading the user (non-global) configurations file
immutable userLanguage               = "LANGUAGE";
immutable userOptionGroup            = "OPTION_GROUP";

immutable userMouseSpeed             = "MOUSE_SPEED";
immutable userScrollSpeedEdge        = "SCROLL_SPEED_EDGE";
immutable userScrollSpeedClick       = "SCROLL_SPEED_CLICK";
immutable userScrollEdge             = "SCROLL_EDGE";
immutable userScrollRight            = "SCROLL_RIGHT";
immutable userScrollMiddle           = "SCROLL_MIDDLE";
immutable userReplayCancel           = "REPLAY_CANCEL";
immutable userReplayCancelAt         = "REPLAY_CANCEL_AT";
immutable userAvoidBuilderQueuing    = "AVOID_BUILDER_QUEUING";
immutable userAvoidBatterToExploder  = "AVOID_BATTER_TO_EXPLODER";
immutable userPriorityInvertMiddle   = "PRIORITY_INVERT_MIDDLE";
immutable userPriorityInvertRight    = "PRIORITY_INVERT_RIGHT";

immutable userScreenWindowed         = "SCREEN_WINDOWED";
immutable userScreenWindowedX        = "SCREEN_WINDOWED_X";
immutable userScreenWindowedY        = "SCREEN_WINDOWED_Y";
immutable userArrowsReplay           = "ARROWS_REPLAY";
immutable userArrowsNetwork          = "ARROWS_NETWORK";
immutable userIngameTooltips         = "INGAME_TOOLTIPS";
immutable userShowButtonHotkeys      = "SHOW_BUTTON_HOTKEYS";
immutable userGuiColorRed            = "GUI_COLOR_RED";
immutable userGuiColorGreen          = "GUI_COLOR_GREEN";
immutable userGuiColorBlue           = "GUI_COLOR_BLUE";

immutable userSoundVolume            = "SOUND_VOLUME";

immutable userSingleLastLevel  = "SINGLE_LAST_LEVEL";
immutable userNetworkLastLevel = "NETWORK_LAST_LEVEL";
immutable userReplayLastLevel  = "REPLAY_LAST_LEVEL";
immutable userNetworkLastStyle = "NETWORK_LAST_STYLE";

immutable userReplayAutoSolutions = "REPLAY_AUTO_SAVE_SOLUTIONS";
immutable userReplayAutoMulti     = "REPLAY_AUTO_SAVE_MULTI";

immutable userEditorLastDirTerrain = "EDITOR_LAST_DIR_TERRAIN";
immutable userEditorLastDirSteel   = "EDITOR_LAST_DIR_STEEL";
immutable userEditorLastDirGoal    = "EDITOR_LAST_DIR_GOAL";
immutable userEditorLastDirHatch   = "EDITOR_LAST_DIR_HATCH";
immutable userEditorLastDirDeco    = "EDITOR_LAST_DIR_DECO";
immutable userEditorLastDirHazard  = "EDITOR_LAST_DIR_HAZARD";

immutable userEditorHexLevelSize   = "EDITOR_HEX_LEVEL_SIZE";
immutable userEditorGridSelected   = "EDITOR_GRID_SELECTED";
immutable userEditorGridCustom     = "EDITORGridCustom";

immutable userKeyForceLeft      = "KEY_FORCE_LEFT";
immutable userKeyForceRight     = "KEY_FORCE_RIGHT";
immutable userKeyScroll         = "KEY_SCROLL";
immutable userKeyPriorityInvert = "KEY_PRIORITY";
immutable userKeySpawnintSlower = "KEY_RATE_MINUS";
immutable userKeySpawnintFaster = "KEY_RATE_PLUS";
immutable userKeyPause          = "KEY_PAUSE";
immutable userKeyFrameBackMany  = "KEY_SPEED_BACK_MANY";
immutable userKeyFrameBackOne   = "KEY_SPEED_BACK_ONE";
immutable userKeyFrameAheadOne  = "KEY_SPEED_AHEAD_ONE";
immutable userKeyFrameAheadMany = "KEY_SPEED_AHEAD_MANY";
immutable userKeySpeedFast      = "KEY_SPEED_FAST";
immutable userKeySpeedTurbo     = "KEY_SPEED_TURBO";
immutable userKeyRestart        = "KEY_RESTART";
immutable userKeyStateLoad      = "KEY_STATE_LOAD";
immutable userKeyStateSave      = "KEY_STATE_SAVE";
immutable userKeyZoom           = "KEY_ZOOM";
immutable userKeyNuke           = "KEY_NUKE";
immutable userKeySpecTribe      = "KEY_SPECTATE_NEXT_PLAYER";
immutable userKeyChat           = "KEY_CHAT";
immutable userKeyGameExit       = "KEY_GAME_EXIT";

immutable userKeyMenuOkay       = "KEY_MENU_OKAY";
immutable userKeyMenuEdit       = "KEY_MENU_EDIT";
immutable userKeyMenuExport     = "KEY_MENU_EXPORT";
immutable userKeyMenuDelete     = "KEY_MENU_DELETE";
immutable userKeyMenuUpDir      = "KEY_MENU_UP_DIR";
immutable userKeyMenuUpBy1      = "KEY_MENU_UP_1";
immutable userKeyMenuUpBy5      = "KEY_MENU_UP_5";
immutable userKeyMenuDownBy1    = "KEY_MENU_DOWN_1";
immutable userKeyMenuDownBy5    = "KEY_MENU_DOWN_5";
immutable userKeyMenuExit       = "KEY_MENU_EXIT";

immutable userKeyMenuMainSingle  = "KEY_MENU_MAIN_SINGLE";
immutable userKeyMenuMainNetwork = "KEY_MENU_MAIN_NETWORK";
immutable userKeyMenuMainReplays = "KEY_MENU_MAIN_REPLAY";
immutable userKeyMenuMainOptions = "KEY_MENU_MAIN_OPTIONS";

immutable userKeyEditorLeft        = "KEY_EDITOR_LEFT";
immutable userKeyEditorRight       = "KEY_EDITOR_RIGHT";
immutable userKeyEditorUp          = "KEY_EDITOR_UP";
immutable userKeyEditorDown        = "KEY_EDITOR_DOWN";
immutable userKeyEditorCopy        = "KEY_EDITOR_COPY";
immutable userKeyEditorDelete      = "KEY_EDITOR_DELETE";
immutable userKeyEditorGrid        = "KEY_EDITOR_GRID";
immutable userKeyEditorSelectAll   = "KEY_EDITORSelectAll";
immutable userKeyEditorSelectFrame = "KEY_EDITORSelectFrame";
immutable userKeyEditorSelectAdd   = "KEY_EDITORSelectAdd";
immutable userKeyEditorForeground  = "KEY_EDITOR_FOREGROUND";
immutable userKeyEditorBackground  = "KEY_EDITOR_BACKGROUND";
immutable userKeyEditorMirror      = "KEY_EDITOR_MIRROR";
immutable userKeyEditorRotate      = "KEY_EDITOR_ROTATE";
immutable userKeyEditorDark        = "KEY_editorDark";
immutable userKeyEditorNoow        = "KEY_EDITOR_NO_OVERWRITE";
immutable userKeyEditorZoom        = "KEY_EDITOR_ZOOM";
immutable userKeyEditorHelp        = "KEY_EDITOR_HELP";
immutable userKeyEditorMenuSize    = "KEY_EDITORMenuSize";
immutable userKeyEditorMenuVars    = "KEY_EDITOR_MENU_GENERAL";
immutable userKeyEditorMenuSkills  = "KEY_EDITORMenuSkillS";
immutable userKeyEditorAddTerrain  = "KEY_EDITORAddTerrain";
immutable userKeyEditorAddSteel    = "KEY_EDITORAddSteel";
immutable userKeyEditorAddHatch    = "KEY_EDITORAddHatch";
immutable userKeyEditorAddGoal     = "KEY_EDITORAddGoal";
immutable userKeyEditorAddDeco     = "KEY_EDITORAddDeco";
immutable userKeyEditorAddHazard   = "KEY_EDITORAddHazard";
immutable userKeyEditorExit        = "KEY_EDITOR_EXIT";



private alias const(Filename) cF;

cF dirLevels          = new cF("levels/");
cF dirLevelsSingle    = new cF("levels/single/");
cF dirLevelsNetwork   = new cF("levels/network/");
cF dirReplays         = new cF("replays/");
cF dirData            = new cF("data/");
cF dirDataBitmap      = new cF("data/images/");
cF dirDataBitmapScale = new cF("data/images/scale"); // stub, no /
cF dirDataSound       = new cF("data/sound/");
cF dirDataUser        = new cF("data/user/");
cF dirDataTransl      = new cF("data/transl/");
cF dirImages          = new cF("images/");
cF dirImagesOrig      = new cF("images/orig/");
cF dirImagesOrigL1    = new cF("images/orig/L1/");
cF dirImagesOrigL2    = new cF("images/orig/L2/");

cF dirReplayAutoSolutions  = new cF("replays/solved/");
cF dirReplayAutoMulti      = new cF("replays/network/");
cF dirReplayManual         = new cF("replays/manual/");

cF fileGlobalConfig        = new cF("data/config.txt");
cF fileLog                 = new cF("data/log.txt");
cF fileTharsisProf         = new cF("data/profile.txt");
cF fileLanguageEnglish     = new cF("data/transl/english.txt");

cF fileImageGuiNumber      = new cF("data/images/api_numb.I");
cF fileImageDebris         = new cF("data/images/debris.I");
cF fileImageEditFlip       = new cF("data/images/edit_flp.I");
cF fileImageEditHatch      = new cF("data/images/edit_hat.I");
cF fileImageEditPanel      = new cF("data/images/edit_pan.I");
cF fileImageExplosion      = new cF("data/images/explode.I");
cF fileImageFuseFlame      = new cF("data/images/fuse_fla.I");
cF fileImageGameArrow      = new cF("data/images/game_arr.I");
cF fileImageGameIcon       = new cF("data/images/game_ico.I");
cF fileImageGameNuke       = new cF("data/images/game_nuk.I");
cF fileImageGamePanel      = new cF("data/images/game_pan.I");
cF fileImageGamePanel2     = new cF("data/images/game_pa2.I");
cF fileImageGamePanelHints = new cF("data/images/game_pah.I");
cF fileImageGameSpawnint   = new cF("data/images/game_spi.I");
cF fileImageGamePause      = new cF("data/images/game_pau.I");
cF fileImageGameReplay     = new cF("data/images/game_rep.I");
cF fileImageImplosion      = new cF("data/images/implode.I");
cF fileImageSpritesheet    = new cF("data/images/lix.I");
cF fileImageStyleRecol     = new cF("data/images/lixrecol.I");
cF fileImageLobbySpec      = new cF("data/images/lobby_sp.I");
cF fileImageMenuBackground = new cF("data/images/menu_bg.I");
cF fileImageMenuCheckmark  = new cF("data/images/menu_chk.I");
cF fileImageMouse          = new cF("data/images/mouse.I");
cF fileImagePreviewIcon    = new cF("data/images/prev_ico.I");
cF fileImageSkillIcons     = new cF("data/images/skillico.I");
