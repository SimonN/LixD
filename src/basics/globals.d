module basics.globals;

import file.filename;

// globals.d contains all the compile-time _constants_ accessible from
// throughout the game. Global variables that may change are in globconf.d,
// those are the variables saved into the global config file.

// Untranslated strings; for translations of other strings see file.language
immutable nameOfTheGame = "Lix";
immutable homepageURL   = "www.lixgame.com";
immutable musicDownloadURL = "www.lixgame.com/dow/lix-music.zip";

enum int ticksPerSecond       = 60;
enum int ticksForDoubleClick  = 20; // 1/3 of a second at 60 ticks/sec

enum int teamsPerLevelMax     =  8;
enum int mouseStandardDivisor = 20;

/*
 * Large levels may crash Lix because of gigantic VRAM bitmaps swapped into
 * RAM that never get freed properly, or the graphics card hogs this RAM. See:
 * https://www.lemmingsforums.net/index.php?topic=3701.msg69288#msg69288
 *
 * Our workaround is to warn when setting the size of a level to this constant
 * or more, and to warn in the level-browser-preview before playing.
 */
enum int levelPixelsToWarn = 1024 * 1024 * 28 / 10;

immutable netIPLocalhost = "127.0.0.1";

// loading files
immutable filenameExtLevel           = ".txt";
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
immutable levelSizeX                  = "SIZE_X";
immutable levelSizeY                  = "SIZE_Y";
immutable levelTorusX                 = "TORUS_X";
immutable levelTorusY                 = "TORUS_Y";
immutable levelBackgroundRed          = "BACKGROUND_RED";
immutable levelBackgroundGreen        = "BACKGROUND_GREEN";
immutable levelBackgroundBlue         = "BACKGROUND_BLUE";
immutable levelSeconds                = "SECONDS";
immutable levelInitial                = "INITIAL";
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

// Class objects will be instantiated in the module constructor.
Filename dirLevels, dirLevelsSingle, dirLevelsNetwork, dirReplays, dirData,
    dirDataBitmap, dirDataSound, dirDataMusic,
    dirDataUser, dirDataTransl, dirImages,
    dirReplayAutoSolutions, dirReplayAutoMulti, dirReplayManual,
    dirExport;

Filename fileGlobalConfig, fileLog, fileReplayVerifier, fileTharsisProf,
    fileLanguageEnglish, fileMusicMenu, fileMusicGain,
    fileSingleplayerFirstLevel;

Filename fileImageAbility, fileImageGuiNumber, fileImageAppIcon,
    fileImageDebris, fileImageEditFlip, fileImageEditHatch,
    fileImageEditPanel, fileImageExplosion, fileImageFuse,
    fileImageFuseFlame, fileImageGameArrow, fileImageGameIcon,
    fileImageGamePanel, fileImageGamePanel2,
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
    dirDataMusic = new Fn("music/");
    dirDataUser = new Fn("data/user/");
    dirDataTransl = new Fn("data/transl/");
    dirImages = new Fn("images/");
    dirReplayAutoSolutions = new Fn("replays/solved/");
    dirReplayAutoMulti = new Fn("replays/network/");
    dirReplayManual = new Fn("replays/manual/");
    dirExport = new Fn("export/");

    fileGlobalConfig = new Fn("data/config.txt");
    fileLog = new Fn("data/log.txt");
    fileReplayVerifier = new Fn("data/verifier.txt");
    fileTharsisProf = new Fn("data/profile.txt");
    fileLanguageEnglish = new Fn("data/transl/english.txt");
    fileMusicMenu = new Fn(dirDataMusic.rootless ~ "menulix");
    fileMusicGain = new Fn(dirDataMusic.rootless ~ "gain.txt");
    fileSingleplayerFirstLevel = new Fn(dirLevelsSingle.rootless
                                    ~ "lemforum/Lovely/anyway.txt");

    fileImageAppIcon = new Fn("data/images/app_icon.I.png"); // with extension

    // These are without image extensions due to legacy design that tried
    // to stay format-agnostic. But PNG has become the standard since.
    fileImageAbility = new Fn("data/images/ability.I");
    fileImageGuiNumber = new Fn("data/images/api_numb.I");
    fileImageDebris = new Fn("data/images/debris.I");
    fileImageEditFlip = new Fn("data/images/edit_flp.I");
    fileImageEditHatch = new Fn("data/images/edit_hat.I");
    fileImageEditPanel = new Fn("data/images/edit_pan.I");
    fileImageExplosion = new Fn("data/images/explode.I");
    fileImageFuse = new Fn("data/images/fuse.I");
    fileImageFuseFlame = new Fn("data/images/fuse_fla.I");
    fileImageGameArrow = new Fn("data/images/game_arr.I");
    fileImageGameIcon = new Fn("data/images/game_ico.I");
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
