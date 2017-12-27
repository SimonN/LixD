module file.language;

/*  enum Lang
 *      has one ID for each to-be-translated string
 *
 *  string transl(Lang)
 *      translate the ID
 *
 *  void loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
 *      Should be used by loading the user file, or by the options dialogue.
 *      Both of these write to the user file anyway.
 *
 * DTODOOPTION
 *      These appear out of place from regular option names.
 *      The options menu hijacks some names from elsewhere and reuses them
 *      as captions in the options menu. The contract in basics.useropt
 *      demand that the explanation comes right after. Thus, the explanation
 *      appears out of place from the options, even though only the options
 *      menu uses it.
 */

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
    commonYes,
    commonNo,
    commonBack,
    commonExit,
    commonVersion,

    // browsers
    browserSingleTitle, browserSingleTitleDesc, // DTODOOPTION
    browserNetworkTitle,
    browserReplayTitle, browserReplayTitleDesc, // DTODOOPTION
    browserPlay,
    browserEdit,
    browserNewLevel,
    browserReplay,
    browserDelete,
    browserSearch,
    browserExtract,
    browserExportImage,
    browserExportImageDone,

    browserMkdirTitle,
    browserMkdirPleaseEnter,

    browserInfoAuthor,
    browserInfoInitgoal,
    browserInfoInitial,
    browserInfoHatches,
    browserInfoGoals,
    browserInfoSkills,
    browserInfoClock2,
    browserInfoAuthorNone,
    browserInfoClockNone,

    browserInfoResultSaved,
    browserInfoResultSkills,
    browserInfoResultOld1,
    browserInfoResultOld2,

    browserInfoPlayer,
    browserInfoVersion,
    browserInfoBuilt,
    browserInfoNew,
    browserInfoSame,
    browserInfoOld,
    browserInfoHoldsLevel,

    winSearchTitle,

    winVerifyTitle,

    // networking lobby
    winLobbyTitle, winLobbyTitleDesc, // DTODOOPTION
    winLobbyTitleLobby,
    winLobbyTitleRoom,
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
    winGameTitle, winGameTitleDesc, // DTODOOPTION: option menu explains this
    winGameResult,
    winGameLixSaved,
    winGameLixSavedInTime,
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
    winGameResultSkillsUsed,
    winGameResultTimeUsed,
    winGameNetFirst,
    winGameNetSecond,
    winGameNetMiddle,
    winGameNetLast,
    winGameNetTieForFirst,
    winGameNetTieForLast,
    winGameNetEverybodyTies,
    winGameNetZero,
    winGameNetEverybodyZero,
    winGameReplayWinOne,
    winGameReplayWinTeam,
    winGameReplayTie,
    winGameOverwriteTitle,
    winGameOverwriteQuestion,

    // help texts inside the game
    gameForceLeft,
    gameForceRight,
    gamePriorityInvert,
    gameQueueBuilder,
    gameQueuePlatformer,
    gameHoldToScroll,
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
    gameSpecTribe,

    // main editor screen
    editorHotkey,
    editorHotkeyHold,
    editorBarAt,
    editorBarGroup,
    editorBarHover,
    editorBarSelection,
    editorBarMoveWithKeysLong,
    editorBarMoveWithKeysShort,
    editorBarMoveWithKeysMid,
    editorBarMoveWithKeysEnd,

    // make sure these come in the same order as the editor button enum.
    // I don't know how to generate source code for these these enum values.
    // If you have cute D code for that, tell me. :-)
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

    // save browser
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
    addDeco,
    addHazard,

    // editor window about the size of map
    winTopologyTitle,
    winTopologyL,
    winTopologyR,
    winTopologyU,
    winTopologyD,
    winTopologyX,
    winTopologyY,
    winTopologyHex,
    winTopologyTorusX,
    winTopologyTorusY,

    // scrolling start position
    winLooksTitle,
    winLooksManual,
    winLooksX,
    winLooksY,
    winLooksRed,
    winLooksGreen,
    winLooksBlue,
    winLooksJump,
    winLooksCurrent,

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
    exportMultiLix,
    exportMultiSpawnint,
    exportMultiClock,

    // network chat messages
    netChatStartServer,
    netChatStartClient,
    netChatStartCancel,
    netChatYouLoggedOut,
    netChatYouCannotConnect,
    netChatYouLostConnection,
    netChatPeerDisconnected,
    netChatWeTooOld,
    netChatWeTooNew,
    netChatSomeoneOld,
    netChatSomeoneNew,
    netChatNamedGuyOld,
    netChatVersionYours,
    netChatVersionServer,
    netChatServerUpdate,
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
    netGameStart,
    netGameHowToChat1,
    netGameHowToChat2,
    netGameEnd,
    netGameEndResult,
    netGameOvertimeNukeIn,
    netGameTriggersOvertime,
    netGameWantsAbortiveTie,

    // Optionsfenster
    optionTitle, optionTitleDesc, // DTODOOPTION
    optionGroupGeneral,
    optionGroupGraphics,
    optionGroupControls,
    optionGroupGameKeys,
    optionGroupEditorKeys,
    optionGroupMenuKeys,
    optionUserName, optionUserNameDesc,
    optionLanguage, optionLanguageDesc,
    optionReplayAutoSolutions, optionReplayAutoSolutionsDesc,
    optionReplayAutoMulti, optionReplayAutoMultiDesc,
    optionMouseSpeed, optionMouseSpeedDesc,
    optionScrollSpeedEdge, optionScrollSpeedEdgeDesc,
    optionScrollSpeedClick, optionScrollSpeedClickDesc,
    optionFastMovementFreesMouse, optionFastMovementFreesMouseDesc,
    optionAvoidBuilderQueuing, optionAvoidBuilderQueuingDesc,
    optionAvoidBatterToExploder, optionAvoidBatterToExploderDesc,
    optionReplayAfterFrameBack, optionReplayAfterFrameBackDesc,
    optionUnpauseOnAssign, optionUnpauseOnAssignDesc,

    optionScreenWindowed, optionScreenWindowedDesc,
    optionScreenWindowedRes, optionScreenWindowedResDesc,
    optionPaintTorusSeams, optionPaintTorusSeamsDesc,
    optionIngameTooltips, optionIngameTooltipsDesc,
    optionShowButtonHotkeys, optionShowButtonHotkeysDesc,
    optionShowFPS, optionShowFPSDesc,
    optionGuiColorRed, optionGuiColorRedDesc,
    optionGuiColorGreen, optionGuiColorGreenDesc,
    optionGuiColorBlue, optionGuiColorBlueDesc,
    optionSoundEnabled, optionSoundEnabledDesc,
    optionMusicEnabled, optionMusicEnabledDesc,
    optionSoundDecibels, optionSoundDecibelsDesc,
    optionMusicDecibels, optionMusicDecibelsDesc,

    optionKeyForceLeft, optionKeyForceLeftDesc,
    optionKeyForceRight, optionKeyForceRightDesc,
    optionKeyScroll, optionKeyScrollDesc,
    optionKeyPriorityInvert, optionKeyPriorityInvertDesc,
    optionKeyPause, optionKeyPauseDesc,
    optionKeyFrameBackMany, optionKeyFrameBackManyDesc,
    optionKeyFrameBackOne, optionKeyFrameBackOneDesc,
    optionKeyFrameAheadOne, optionKeyFrameAheadOneDesc,
    optionKeyFrameAheadMany, optionKeyFrameAheadManyDesc,
    optionKeySpeedFast, optionKeySpeedFastDesc,
    optionKeySpeedTurbo, optionKeySpeedTurboDesc,
    optionKeyRestart, optionKeyRestartDesc,
    optionKeyStateLoad, optionKeyStateLoadDesc,
    optionKeyStateSave, optionKeyStateSaveDesc,
    optionKeyZoomIn, optionKeyZoomInDesc,
    optionKeyZoomOut, optionKeyZoomOutDesc,
    optionKeyChat, optionKeyChatDesc,
    optionKeySpecTribe, optionKeySpecTribeDesc,
    optionKeyClearPhysics, optionKeyClearPhysicsDesc,
    optionKeyNuke, optionKeyNukeDesc,

    optionKeyMenuOkay, optionKeyMenuOkayDesc,
    optionKeyMenuEdit, optionKeyMenuEditDesc,
    optionKeyMenuNewLevel, optionKeyMenuNewLevelDesc,
    optionKeyMenuExport, optionKeyMenuExportDesc,
    optionKeyMenuDelete, optionKeyMenuDeleteDesc,
    optionKeyMenuUpDir, optionKeyMenuUpDirDesc,
    optionKeyMenuUpBy1, optionKeyMenuUpBy1Desc,
    optionKeyMenuUpBy5, optionKeyMenuUpBy5Desc,
    optionKeyMenuDownBy1, optionKeyMenuDownBy1Desc,
    optionKeyMenuDownBy5, optionKeyMenuDownBy5Desc,
    optionKeyMenuExit, optionKeyMenuExitDesc,

    optionEdLeft, optionEdLeftDesc,
    optionEdRight, optionEdRightDesc,
    optionEdUp, optionEdUpDesc,
    optionEdDown, optionEdDownDesc,
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
    optionEdAddDeco,
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
private string[Lang.MAX] lang;

public string
transl(in Lang key)
{
    return lang[key];
}



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
        lang[langId] = line.text2;
        langIdsReadIn[langId] = true;
    }
    // end foreach line

    // warn about undefined language IDs
    foreach (int id; 0 .. Lang.MAX) {
        if (! langIdsReadIn[id]) {
            string langIdStr = id.to!Lang.to!string;
            localLogf("New translation required: %s", langIdStr);
            lang[id] = "!" ~ langIdStr ~ "!";
        }
    }
    // end foreach for undefined IDs
}
// end function loadLanguageFile
