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

enum int teamsPerLevelMax     =  8;
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
immutable levelIntendedNumberOfPlayers= "INTENDED_NUMBER_OF_PLAYERS";
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
immutable levelBeginGroup             = "BEGIN_TILE_GROUP";
immutable levelEndGroup               = "END_TILE_GROUP";
immutable levelUseGroup               = "Group-";

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
