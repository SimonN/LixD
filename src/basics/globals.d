module basics.globals;

/*
 * globals.d contains all the compile-time _constants_ accessible from
 * throughout the game. Mutable user options are in file.option.allopts.
 */

import file.filename;

// Untranslated strings; for translations of other strings see file.language
immutable nameOfTheGame = "Lix";
immutable homepageURL   = "www.lixgame.com";
immutable musicDownloadURL = "www.lixgame.com/dow/lix-music.zip";

enum int ticksPerSecond       = 60;
enum int ticksForDoubleClick  = 20; // 1/3 of a second at 60 ticks/sec

enum int phyusPerSecondAtNormalSpeed = 15;
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

// pre-extensions of image files
immutable preExtInternal             = 'I';
immutable preExtSteel                = 'S';
immutable preExtHatch                = 'H';
immutable preExtGoal                 = 'G';
immutable preExtTrap                 = 'T';
immutable preExtFire                 = 'F';
immutable preExtWater                = 'W';
immutable preExtHiddenFile           = 'X';

// keys for saving/loading level files
immutable levelBuilt                  = "BUILT";
immutable levelAuthor                 = "AUTHOR";
immutable levelNameGerman             = "GERMAN";
immutable levelNameEnglish            = "ENGLISH";
immutable levelIntendedNumberOfPlayers= "INTENDED_NUMBER_OF_PLAYERS";
immutable levelTag                    = "TAG";
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
immutable replaySingleHandi           = "HANDICAP";
immutable replayPermu                 = "PERMUTATION";
immutable replayNuke                  = "NUKE";
immutable replayAssignAny             = "ASSIGN";
immutable replayAssignLeft            = "ASSIGN_LEFT";
immutable replayAssignRight           = "ASSIGN_RIGHT";

immutable dirDataBitmapScale = "data/images/scale";
immutable englishBasenameNoExt = "english";

// Class objects will be instantiated in the module constructor.
Filename dirLevels, dirLevelsSingle, dirLevelsNetwork, dirReplays, dirData,
    dirDataBitmap, dirDataSound, dirDataMusic,
    dirDataUser, dirDataTransl, dirImages,
    dirReplayAutoSolutions, dirReplayAutoMulti, dirReplayManual,
    dirExport;

Filename fileLog, fileReplayVerifier,
    fileLivestreamNote,
    fileTharsisProf,
    fileHotkeys, fileOptions, fileTrophies,
    fileMusicMenu,
    fileSingleplayerFirstLevel;

Filename fileImageAppIcon;

shared static this()
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

    fileOptions = new Fn("user/options.sdl");
    fileTrophies = new Fn("user/trophies.sdl");
    fileLog = new Fn("user/log.txt");
    fileReplayVerifier = new Fn("user/verifier.txt");
    fileLivestreamNote = new Fn("user/streamnote.txt");
    fileTharsisProf = new Fn("user/profiler.txt");

    fileMusicMenu = new Fn(dirDataMusic.rootless ~ "menulix");
    fileSingleplayerFirstLevel = new Fn(dirLevelsSingle.rootless
                                    ~ "lemforum/Lovely/anyway.txt");

    fileImageAppIcon = new Fn("data/images/appwindowicon.png");
}
