module basics.globals;

import file.filename;

// globals.d contains all the compile-time _constants_ accessible from
// throughout the game. Global variables that may change are in globconf.d,
// those are the variables saved into the global config file.

// Untranslated strings; for translations of other strings see file.language
immutable nameOfTheGame = "Lix";
immutable homepageURL   = "asdfasdf.ethz.ch/~simon";

enum int ticksPerSecond       = 60;
enum int updatesPerSecond     = 15; // logic/physics updates of the game
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
immutable preExtHiddenFile           = 'X';

// keys for saving/loading the global config file
immutable cfgUserName                = "USER_NAME";
immutable cfgUserNameAsk             = "USER_NAME_ASK";

immutable cfgIPLastUsed              = "IP_LAST_USED";
immutable cfgIPCentralServer         = "IP_CENTRAL_SERVER";
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
immutable levelStartCornerX           = "START_X";
immutable levelStartCornerY           = "START_Y";
immutable levelBackgroundRed          = "BACKGROUND_RED";
immutable levelBackgroundGreen        = "BACKGROUND_GREEN";
immutable levelBackgroundBlue         = "BACKGROUND_BLUE";
immutable levelSeconds                = "SECONDS";
immutable levelInitial                = "INITIAL";
immutable levelInitialLegacy          = "LEMMINGS"; // backwards compatibility
immutable levelRequired               = "REQUIRED";
immutable levelSpawnint               = "SPAWN_INTERVAL";
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

// keys for saving/loading replays
immutable replayGameVersionRequired   = "GAME_VERSION_REQUIRED";
immutable replayLevelBuiltRequired    = "LEVEL_BUILT_REQUIRED";
immutable replayLevelFilename         = "FILENAME";
immutable replayFriend                = "FRIEND";
immutable replayPlayer                = "PLAYER";
immutable replayPermu                 = "PERMUTATION";
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
immutable userReplayCancel           = "REPLAY_CANCEL";
immutable userReplayCancelAt         = "REPLAY_CANCEL_AT";
immutable userAvoidBuilderQueuing    = "AVOID_BUILDER_QUEUING";
immutable userAvoidBatterToExploder  = "AVOID_BATTER_TO_EXPLODER";

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
immutable userKeyScroll         = "KEY_HOLD_TO_SCROLL";
immutable userKeyPriorityInvert = "KEY_PRIORITY_INVERT";
immutable userKeySpawnintSlower = "KEY_RATE_MINUS";
immutable userKeySpawnintFaster = "KEY_RATE_PLUS";
immutable userKeyPause1         = "KEY_PAUSE";
immutable userKeyPause2         = "KEY_PAUSE2";
immutable userKeyFrameBackMany  = "KEY_SPEED_BACK_MANY";
immutable userKeyFrameBackOne   = "KEY_SPEED_BACK_ONE";
immutable userKeyFrameAheadOne  = "KEY_SPEED_AHEAD_ONE";
immutable userKeyFrameAheadMany = "KEY_SPEED_AHEAD_MANY";
immutable userKeySpeedFast      = "KEY_SPEED_FAST";
immutable userKeySpeedTurbo     = "KEY_SPEED_TURBO";
immutable userKeyRestart        = "KEY_RESTART";
immutable userKeyStateLoad      = "KEY_STATE_LOAD";
immutable userKeyStateSave      = "KEY_STATE_SAVE";
immutable userKeyZoomIn         = "KEY_ZOOM_IN";
immutable userKeyZoomOut        = "KEY_ZOOM_OUT";
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

static const dirLevels          = new Filename("levels/");
static const dirLevelsSingle    = new Filename("levels/single/");
static const dirLevelsNetwork   = new Filename("levels/network/");
static const dirReplays         = new Filename("replays/");
static const dirData            = new Filename("data/");
static const dirDataBitmap      = new Filename("data/images/");
static const dirDataSound       = new Filename("data/sound/");
static const dirDataUser        = new Filename("data/user/");
static const dirDataTransl      = new Filename("data/transl/");
static const dirImages          = new Filename("images/");
static const dirImagesOrig      = new Filename("images/orig/");
static const dirImagesOrigL1    = new Filename("images/orig/L1/");
static const dirImagesOrigL2    = new Filename("images/orig/L2/");

immutable dirDataBitmapScale = "data/images/scale";

static const dirReplayAutoSolutions  = new Filename("replays/solved/");
static const dirReplayAutoMulti      = new Filename("replays/network/");
static const dirReplayManual         = new Filename("replays/manual/");

static const fileGlobalConfig        = new Filename("data/config.txt");
static const fileLog                 = new Filename("data/log.txt");
static const fileTharsisProf         = new Filename("data/profile.txt");
static const fileLanguageEnglish     = new Filename("data/transl/english.txt");

static const fileImageGuiNumber      = new Filename("data/images/api_numb.I");
static const fileImageDebris         = new Filename("data/images/debris.I");
static const fileImageEditFlip       = new Filename("data/images/edit_flp.I");
static const fileImageEditHatch      = new Filename("data/images/edit_hat.I");
static const fileImageEditPanel      = new Filename("data/images/edit_pan.I");
static const fileImageExplosion      = new Filename("data/images/explode.I");
static const fileImageFuseFlame      = new Filename("data/images/fuse_fla.I");
static const fileImageGameArrow      = new Filename("data/images/game_arr.I");
static const fileImageGameIcon       = new Filename("data/images/game_ico.I");
static const fileImageGameNuke       = new Filename("data/images/game_nuk.I");
static const fileImageGamePanel      = new Filename("data/images/game_pan.I");
static const fileImageGamePanel2     = new Filename("data/images/game_pa2.I");
static const fileImageGamePanelHints = new Filename("data/images/game_pah.I");
static const fileImageGameSpawnint   = new Filename("data/images/game_spi.I");
static const fileImageGamePause      = new Filename("data/images/game_pau.I");
static const fileImageGameReplay     = new Filename("data/images/game_rep.I");
static const fileImageImplosion      = new Filename("data/images/implode.I");
static const fileImageSpritesheet    = new Filename("data/images/lix.I");
static const fileImageStyleRecol     = new Filename("data/images/lixrecol.I");
static const fileImageLobbySpec      = new Filename("data/images/lobby_sp.I");
static const fileImageMenuBackground = new Filename("data/images/menu_bg.I");
static const fileImageMenuCheckmark  = new Filename("data/images/menu_chk.I");
static const fileImageMouse          = new Filename("data/images/mouse.I");
static const fileImagePreviewIcon    = new Filename("data/images/prev_ico.I");
static const fileImageSkillIcons     = new Filename("data/images/skillico.I");
