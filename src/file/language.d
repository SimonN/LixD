module file.language;

/*  enum Lang
 *      has one ID for each to-be-translated string
 *
 *  string transl(Lang)
 *      translate the ID
 *
 *  string dsecr(Lang)
 *      give a translated longer `|'-linebroken description for the options
 *
 *  void loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
 *      Should be used by loading the user file, or by the options dialogue.
 *      Both of these write to the user file anyway.
 */

import std.array;
import std.algorithm : splitter;
import std.conv; // (enum constant) <-> (string of its variable name)
                 // This is done by to!Lang or to!string. This capability
                 // for D enums is awesome, the entire module is built on it

import basics.globals; // fileLanguageEnglish
import basics.user;    // fileLanguage, which file does the user want
import file.io;
import file.log;
import file.filename;

enum Lang {
    // fundamental things
    mainNameOfLanguage,

    // used in various dialogues
    commonOk,
    commonCancel,
    commonNo,
    commonBack,
    commonExit,
    commonVersion,
    mainMenuGetMusic,

    // browsers
    browserSingleTitle,
    browserNetworkTitle,
    browserReplayTitle,
    browserPlay,
    browserEdit,
    browserNewLevel,
    browserReplay,
    browserDelete,
    browserSearch,
    browserExportImage,
    browserExportImageDone,

    browserMkdirTitle,
    browserMkdirPleaseEnter,

    browserInfoAuthor,
    browserInfoInitgoal,

    browserInfoResultSaved,
    browserInfoResultSkills,

    winSearchTitle,
    winSearchPrompt,
    winVerifyTitle,

    // networking lobby
    winLobbyTitle,
    winLobbyDisconnect,
    winLobbyStartCentral,
    winLobbyStartCustom,
    winLobbyStartConnect,
    winLobbyChat,
    winLobbySelectLevel,
    winLobbyReady,
    winLobbyRoomNumber,
    winLobbyRoomCreate,
    winLobbyRoomLeave,

    // end-of-game dialog, or pause dialog
    winGameTitle,
    winGameResult,
    winGameLixSaved,
    winGameResume,
    winGameFramestepBack,
    winGameRestart,
    winGameSaveReplay,
    winGameMenu,
    winGameCommentPerfect,
    winGameCommentMore,
    winGameCommentExactly,
    winGameCommentFewer,
    winGameCommentNone,

    // help texts inside the game
    gameForceLeft,
    gameForceRight,
    gamePriorityInvert,
    gameQueueBuilder,
    gameQueuePlatformer,
    gameHoldToScroll,
    gameClickToCancelReplay,
    gamePause,
    gameZoom,
    gameStateSave,
    gameStateLoad,
    gameFramestepBack,
    gameFramestepAhead,
    gameFastForward,
    gameRestart,
    gameNuke,
    gameClearPhysics,

    // main editor screen
    editorHotkey,
    editorBarAt,
    editorBarGroup,
    editorBarHover,
    editorBarSelection,

    // These must come in the same order as the editor button enum.
    editorButtonFileNew,
    editorButtonFileExit,
    editorButtonFileSave,
    editorButtonFileSaveAs,
    editorButtonGrid2,
    editorButtonGridCustom,
    editorButtonGrid16,
    editorButtonSelectAll,
    editorButtonSelectFrame,
    editorButtonSelectAdd,
    editorButtonUndo,
    editorButtonRedo,
    editorButtonGroup,
    editorButtonUngroup,
    editorButtonSelectCopy,
    editorButtonSelectDelete,
    editorButtonBackground,
    editorButtonForeground,
    editorButtonSelectFlip,
    editorButtonSelectRotate,
    editorButtonSelectDark,
    editorButtonViewZoom,
    editorButtonAddTerrain,
    editorButtonAddSteel,
    editorButtonAddHatch,
    editorButtonAddGoal,
    editorButtonAddDeco,
    editorButtonAddHazard,
    editorButtonMenuConstants,
    editorButtonMenuTopology,
    editorButtonMenuLooks,
    editorButtonMenuSkills,

    saveBrowserTitle,
    saveBrowserWhatToType,
    saveBoxOverwriteTitle,
    saveBoxOverwriteQuestion,
    saveBoxOverwrite,

    saveBoxTitleDelete,
    saveBoxTitleSave,
    saveBoxQuestionUnsavedChangedLevel,
    saveBoxQuestionUnsavedNewLevel,
    saveBoxQuestionDeleteReplay,
    saveBoxQuestionDeleteLevel,
    saveBoxDirectory,
    saveBoxFileName,
    saveBoxLevelName,
    saveBoxYesSave,
    saveBoxNoDiscard,
    saveBoxNoCancel,

    // BitmapBrowser
    addTerrain,
    addSteel,
    addHatch,
    addGoal,
    addHazard,

    // editor window about the size of map
    winTopologyTitle,
    winTopologyL,
    winTopologyR,
    winTopologyU,
    winTopologyD,
    winTopologyTorusX,
    winTopologyTorusY,

    // scrolling start position
    winLooksTitle,
    winLooksRed,
    winLooksGreen,
    winLooksBlue,

    // editor window to set level variables
    winConstantsTitle,
    winConstantsAuthor,
    winConstantsLevelName,
    winConstantsPlayers,
    winConstantsInitial,
    winConstantsRequired,
    winConstantsSpawnint,
    winConstantsOvertime,

    // editor window to set skills
    winSkillsTitle,
    winSkillsUseExploder,
    winSkillsClear,
    winSkillsAllTo,
    winSkillsEightTo,

    // exporting a level into a file
    exportSingleInitial,
    exportSingleRequired,
    exportSingleSpawnint,

    // network chat messages
    netChatStartClient,
    netChatStartCancel,
    netChatYouLoggedOut,
    netChatYouCannotConnect,
    netChatYouLostConnection,
    netChatPeerDisconnected,
    netChatWeTooOld,
    netChatWeTooNew,
    netChatVersionYours,
    netChatVersionServer,
    netChatPleaseDownload,
    netChatWeInRoom,
    netChatWeInRoom2,
    netChatWeInLobby,
    netChatPlayerInRoom,
    netChatPlayerInRoom2,
    netChatPlayerInLobby,
    netChatPlayerOutRoom,
    netChatPlayerOutRoom2,
    netChatPlayerOutLobby,
    netChatLevelChange,
    netGameHowToChat1,
    netGameHowToChat2,
    netGameEnd,
    netGameEndResult,
    netGameOvertimeNukeIn,

    // Optionsfenster
    optionTitle,
    optionGroupGeneral,
    optionGroupGraphics,
    optionGroupControls,
    optionGroupGameKeys,
    optionGroupEditorKeys,
    optionGroupMenuKeys,
    optionUserName,
    optionLanguage,
    optionReplayAutoSolutions,
    optionReplayAutoMulti,
    optionMouseSpeed,
    optionScrollSpeedEdge,
    optionHoldToScrollSpeed,
    optionHoldToScrollInvert,
    optionFastMovementFreesMouse,
    optionAvoidBuilderQueuing,
    optionAvoidBatterToExploder,
    optionReplayAfterFrameBack,
    optionUnpauseOnAssign,

    optionScreenMode,
    optionScreenWindowed,
    optionScreenSoftwareFullscreen,
    optionScreenHardwareFullscreen,
    optionScreenWindowedRes,
    optionPaintTorusSeams,
    optionIngameTooltips,
    optionShowButtonHotkeys,
    optionShowFPS,
    optionGuiColorRed,
    optionGuiColorGreen,
    optionGuiColorBlue,
    optionSoundEnabled,
    optionMusicEnabled,
    optionSoundDecibels,
    optionMusicDecibels,

    optionKeyScroll,
    optionKeyPriorityInvert,
    optionKeyZoomIn,
    optionKeyZoomOut,
    optionKeyScreenshot,

    optionKeyForceLeft,
    optionKeyForceRight,
    optionKeyPause,
    optionKeyFrameBackMany,
    optionKeyFrameBackOne,
    optionKeyFrameAheadOne,
    optionKeyFrameAheadMany,
    optionKeySpeedFast,
    optionKeySpeedTurbo,
    optionKeyRestart,
    optionKeyStateLoad,
    optionKeyStateSave,
    optionKeyChat,
    optionKeyClearPhysics,
    optionKeyNuke,

    optionKeyMenuOkay,
    optionKeyMenuEdit,
    optionKeyMenuNewLevel,
    optionKeyMenuExport,
    optionKeyMenuDelete,
    optionKeyMenuUpDir,
    optionKeyMenuUpBy1,
    optionKeyMenuUpBy5,
    optionKeyMenuDownBy1,
    optionKeyMenuDownBy5,
    optionKeyMenuExit,

    optionEdLeft,
    optionEdRight,
    optionEdUp,
    optionEdDown,
    optionEdSave,
    optionEdSaveAs,
    optionEdGrid,
    optionEdGridCustom,
    optionEdSelectAll,
    optionEdSelectFrame,
    optionEdSelectAdd,
    optionEdUndo,
    optionEdRedo,
    optionEdGroup,
    optionEdUngroup,
    optionEdCopy,
    optionEdDelete,
    optionEdBackground,
    optionEdForeground,
    optionEdMirror,
    optionEdRotate,
    optionEdDark,
    optionEdAddTerrain,
    optionEdAddSteel,
    optionEdAddHatch,
    optionEdAddGoal,
    optionEdAddHazard,

    // mini-dialogue to greet a new player
    windowAskNameTitle,
    windowAskNameFirst,
    windowAskNameSecond,

    // This should never be output or read in. Arrays should be created
    // with this as the size, and shouldn't have this as an index.
    MAX
}



// translated strings of currently loaded language
private:

struct Transl {
    string transl;
    string[] descr;
}
Transl[Lang.MAX] _lang;

public:

string transl(in Lang key) { return _lang[key].transl; }
string[] descr(in Lang key) { return _lang[key].descr; }



public void
loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
{
    IoLine[] lines;
    try {
        assert (fileLanguage !is null);
        assert (fileLanguage.value !is null);
        lines = fillVectorFromFile(fileLanguage);
    }
    catch (Exception e) {
        log(e.msg);
        if (! languageIsEnglish) {
            log("Falling back to English.");
            fileLanguage = fileLanguageEnglish;
            loadUserLanguageAndIfNotExistSetUserOptionToEnglish();
            return;
        }
        else {
            log("English language file not found. Broken installation?");
            return;
        }
    }
    // from here on, the user's language (fileLanguage) is not used anymore

    bool[Lang.MAX] langIdsReadIn; // all false right now
    bool fnWrittenToLog = false;

    void localLogf(T...)(string formatstr, T formatargs)
    {
        if (! fnWrittenToLog) {
            fnWrittenToLog = true;
            logf("While reading `%s':", fileLanguage.rootless);
        }
        logf("    -> " ~ formatstr, formatargs);
    }

    foreach (line; lines) {
        if (line.type != '$') continue;

        // now come lines in the format $langId my translated unquoted string
        Lang langId;
        try {
            langId = to!Lang(line.text1);
        }
        catch (ConvException) {
            localLogf("Unnecessary line: %s", line.text1);
            continue;
        }
        // now langId is a good index
        auto range = line.text2.splitter('|');
        if (range.empty) {
            localLogf("Key without translation: %s", line.text1);
            continue;
        }
        _lang[langId].transl = range.front;
        langIdsReadIn[langId] = true;
        range.popFront;
        if (range.empty)
            continue;
        _lang[langId].descr = range.array; // all remaining fields
    }
    // end foreach line

    // warn about undefined language IDs
    foreach (int id; 0 .. Lang.MAX) {
        if (! langIdsReadIn[id]) {
            string langIdStr = id.to!Lang.to!string;
            localLogf("New translation required: %s", langIdStr);
            _lang[id].transl = "!" ~ langIdStr ~ "!";
        }
    }
    // end foreach for undefined IDs
}
// end function loadLanguageFile
