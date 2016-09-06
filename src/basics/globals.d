module basics.globals;

import file.filename;

// globals.d contains all the compile-time _constants_ accessible from
// throughout the game. Global variables that may change are in globconf.d,
// those are the variables saved into the global config file.

// Untranslated strings; for translations of other strings see file.language
immutable nameOfTheGame = "Lix";
immutable homepageURL   = "www.lixgame.com";

enum int ticksPerSecond       = 60;
enum int updatesPerSecond     = 15; // logic/physics updates of the game
enum int ticksForDoubleClick  = 20; // 1/3 of a second at 60 ticks/sec

enum int teamsPerLevelMax     =  8;
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

immutable dirDataBitmapScale = "data/images/scale";

// Shotgun debugging to fix this: https://github.com/SimonN/LixD/issues/121
// I should initialize the Filenames in a module constructor. This requires
// that I declare them separately from their assignment. I don't declare
// them const, because I could assign to them twice even with const in the
// module constructor. I'm confused.

Filename dirLevels, dirLevelsSingle, dirLevelsNetwork, dirReplays, dirData,
    dirDataBitmap, dirDataSound, dirDataUser, dirDataTransl, dirImages,
    dirImagesOrig, dirImagesOrigL1, dirImagesOrigL2, dirReplayAutoSolutions,
    dirReplayAutoMulti, dirReplayManual, dirExportImages;

Filename fileGlobalConfig, fileLog, fileTharsisProf, fileLanguageEnglish;

Filename fileImageGuiNumber, fileImageDebris, fileImageEditFlip,
    fileImageEditHatch, fileImageEditPanel, fileImageExplosion,
    fileImageFuseFlame, fileImageGameArrow, fileImageGameIcon,
    fileImageGameNuke, fileImageGamePanel, fileImageGamePanel2,
    fileImageGamePanelHints, fileImageGameSpawnint, fileImageGamePause,
    fileImageGameReplay, fileImageImplosion, fileImageSpritesheet,
    fileImageStyleRecol, fileImageLobbySpec, fileImageMenuBackground,
    fileImageMenuCheckmark, fileImageMouse, fileImagePreviewIcon,
    fileImageSkillIcons;

static this()
{
    alias Fn = immutable(VfsFilename);

    dirLevels = new Fn("levels/");
    dirLevelsSingle = new Fn("levels/single/");
    dirLevelsNetwork = new Fn("levels/network/");
    dirReplays = new Fn("replays/");
    dirData = new Fn("data/");
    dirDataBitmap = new Fn("data/images/");
    dirDataSound = new Fn("data/sound/");
    dirDataUser = new Fn("data/user/");
    dirDataTransl = new Fn("data/transl/");
    dirImages = new Fn("images/");
    dirImagesOrig = new Fn("images/orig/");
    dirImagesOrigL1 = new Fn("images/orig/L1/");
    dirImagesOrigL2 = new Fn("images/orig/L2/");
    dirReplayAutoSolutions = new Fn("replays/solved/");
    dirReplayAutoMulti = new Fn("replays/network/");
    dirReplayManual = new Fn("replays/manual/");
    dirExportImages = new Fn("export/");

    fileGlobalConfig = new Fn("data/config.txt");
    fileLog = new Fn("data/log.txt");
    fileTharsisProf = new Fn("data/profile.txt");
    fileLanguageEnglish = new Fn("data/transl/english.txt");

    fileImageGuiNumber = new Fn("data/images/api_numb.I");
    fileImageDebris = new Fn("data/images/debris.I");
    fileImageEditFlip = new Fn("data/images/edit_flp.I");
    fileImageEditHatch = new Fn("data/images/edit_hat.I");
    fileImageEditPanel = new Fn("data/images/edit_pan.I");
    fileImageExplosion = new Fn("data/images/explode.I");
    fileImageFuseFlame = new Fn("data/images/fuse_fla.I");
    fileImageGameArrow = new Fn("data/images/game_arr.I");
    fileImageGameIcon = new Fn("data/images/game_ico.I");
    fileImageGameNuke = new Fn("data/images/game_nuk.I");
    fileImageGamePanel = new Fn("data/images/game_pan.I");
    fileImageGamePanel2 = new Fn("data/images/game_pa2.I");
    fileImageGamePanelHints = new Fn("data/images/game_pah.I");
    fileImageGameSpawnint = new Fn("data/images/game_spi.I");
    fileImageGamePause = new Fn("data/images/game_pau.I");
    fileImageGameReplay = new Fn("data/images/game_rep.I");
    fileImageImplosion = new Fn("data/images/implode.I");
    fileImageSpritesheet = new Fn("data/images/lix.I");
    fileImageStyleRecol = new Fn("data/images/lixrecol.I");
    fileImageLobbySpec = new Fn("data/images/lobby_sp.I");
    fileImageMenuBackground = new Fn("data/images/menu_bg.I");
    fileImageMenuCheckmark = new Fn("data/images/menu_chk.I");
    fileImageMouse = new Fn("data/images/mouse.I");
    fileImagePreviewIcon = new Fn("data/images/prev_ico.I");
    fileImageSkillIcons = new Fn("data/images/skillico.I");
}

