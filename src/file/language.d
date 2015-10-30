module file.language;

/*  enum Lang
 *
 *      has one ID for each to-be-translated string
 *
 *  string transl(Lang)
 *
 *      translate the ID
 *
 *  void loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
 *
 *      Should be used by loading the user file, or by the options dialogue.
 *      Both of these write to the user file anyway.
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
    commonDirParent,
    commonDirFlipPage,
    commonVersion,

    // browsers
    browserSingleTitle,
    browserNetworkTitle,
    browserReplayTitle,
    browserPlay,
    browserEdit,
    browserReplay,
    browserDelete,
    browserExtract,
    browserExportImage,
    browserExportImageDone,

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
    browserInfoResultTime,
    browserInfoResultOld1,
    browserInfoResultOld2,

    browserInfoPlayer,
    browserInfoVersion,
    browserInfoBuilt,
    browserInfoNew,
    browserInfoSame,
    browserInfoOld,
    browserInfoHoldsLevel,

    browserBoxDeleteReplayTitle,
    browserBoxDeleteReplayQuestion,
    browserBoxDeleteLevelTitle,
    browserBoxDeleteLevelQuestion,

    // networking lobby
    winLobbyTitle,
    winLobbyTitleLobby,
    winLobbyTitleRoom,
    winLobbyExit,
    winLobbyUnstableCentral,
    winLobbyStartCentral,
    winLobbyStartServer,
    winLobbyStartClient,
    winLobbyChat,
    winLobbySelectLevel,
    winLobbyReady,
    winLobbyRoomNumber,
    winLobbyRoomPlayer,
    winLobbyRoomPlayers,
    winLobbyRoomCreate,
    winLobbyRoomLeave,

    // end-of-game dialog, or pause dialog
    winGameTitle,
    winGameResult,
    winGameLixSaved,
    winGameLixSavedInTime,
    winGameResume,
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
    gameSpawnintSlower,
    gameSpawnintFaster,
    gamePause,
    gameZoom,
    gameSpeedSlow,
    gameSpeedFast,
    gameSpeedTurbo,
    gameStateSave,
    gameStateLoad,
    gameRestart,
    gameNuke,
    gameHintFirst,
    gameHintNext,
    gameHintPrev,
    gameHintOff,
    gameSpecTribe,

    // main editor screen
    editorUnsavedTitle,
    editorUnsavedTitleNew,
    editorUnsavedQuestion,
    editorUnsavedQuestionNew,
    editorFileName,
    editorLevelName,
    editorHotkey,
    editorHotkeyHold,
    editorBarAt,
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
    editorButtonSelectCopy,
    editorButtonSelectDelete,
    editorButtonSelectMinus,
    editorButtonSelectPlus,
    editorButtonSelectBack,
    editorButtonSelectFront,
    editorButtonSelectFlip,
    editorButtonSelectRotate,
    editorButtonSelectDark,
    editorButtonSelectNoow,
    editorButtonViewZoom,
    editorButtonHelp,
    editorButtonMenuSize,
    editorButtonMenuScroll,
    editorButtonMenuVars,
    editorButtonMenuSkill,
    editorButtonAddTerrain,
    editorButtonAddSteel,
    editorButtonAddHatch,
    editorButtonAddGoal,
    editorButtonAddDeco,
    editorButtonAddHazard,

    // save browser
    saveBrowserTitle,
    saveFilename,
    saveBoxOverwriteTitle,
    saveBoxOverwriteQuestion,

    // BitmapBrowser
    addTerrain,
    addSteel,
    addHatch,
    addGoal,
    addDeco,
    addHazard,

    // editor window about the size of map
    winSizeTitle,
    winSizeL,
    winSizeR,
    winSizeU,
    winSizeD,
    winSizeX,
    winSizeY,
    winSizeHex,
    winSizeTorusX,
    winSizeTorusY,

    // scrolling start position
    winScrollTitle,
    winScrollManual,
    winScrollX,
    winScrollY,
    winScrollRed,
    winScrollGreen,
    winScrollBlue,
    winScrollJump,
    winScrollCurrent,

    // editor window to set level variables
    winVarTitle,
    winVarAuthor,
    winVarNameGerman,
    winVarNameEnglish,
    winVarInitial,
    winVarRequired,
    winVarSpawnintSlow,
    winVarSpawnintFast,
    winVarClock,

    // editor window to set skills
    winSkillTitle,
    winSkillClear,
    winSkillClassic8,
    winSkillClassic12,
    winSkillAllTo,

    // exporting a level into a file
    exportSingleLix,
    exportSingleSpawnint,
    exportSingleClock,
    exportMultiLix,
    exportMultiSpawnint,
    exportMultiClock,

    // network chat messages
    netChatWelcome1,
    netChatWelcomeUnstable,
    netChatWelcome2,
    netChatStartServer,
    netChatStartClient,
    netChatStartCancel,
    netChatDisconnection,
    netChatWeTooOld,
    netChatWeTooNew,
    netChatSomeoneOld,
    netChatSomeoneNew,
    netChatNamedGuyOld,
    netChatVersionYours,
    netChatVersionServer,
    netChatServerUpdate,
    netChatPleaseDownload,
    netChatWeConnected,
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
    netGameOvertime1,
    netGameOvertime2,
    netGameOvertime2One,
    netGameOvertime3,
    netGameOvertime4,
    netGameOvertime4One,
    netGameOvertime4Sec,

    // Optionsfenster
    optionTitle,
    optionGroup0,
    optionGroup1,
    optionGroup2,
    optionGroup3,
    optionGroup4,
    optionGroup5,
    optionGroup6,
    optionUserName,
    optionUserNameAsk,
    optionLanguage,
    optionReplayAutoMax,
    optionReplayAutoSingle,
    optionReplayAutoMulti,
    optionReplayCancel,
    optionReplayCancelAt,
    optionScrollEdge,
    optionScrollRight,
    optionScrollMiddle,
    optionMouseSpeed,
    optionScrollSpeedEdge,
    optionScrollSpeedClick,
    optionMultipleBuilders,
    optionBatterPriority,
    optionPriorityInvertMiddle,
    optionPriorityInvertRight,

    optionScreenWindowed,
    optionScreenResolution,
    optionScreenWindowedRes,
    optionScreenVsync,
    optionArrowsReplay,
    optionArrowsNetwork,
    optionGameplayHelp,
    optionDebrisAmount,
    optionDebrisAmountNone,
    optionDebrisAmountOwn,
    optionDebrisAmountAll,
    optionDebrisType,
    optionDebrisTypeStars,
    optionDebrisTypePixels,
    optionGuiColorRed,
    optionGuiColorGreen,
    optionGuiColorBlue,
    optionInfo,
    optionGfxZero,
    optionSoundLoadDriver,
    optionSoundVolume,
    optionInfoSound,

    optionKeyUnassigned,
    optionKeyForceLeft,
    optionKeyForceRight,
    optionKeyScroll,
    optionKeyPriorityInvert,
    optionKeySpawnintSlower,
    optionKeySpawnintFaster,
    optionKeyPause,
    optionKeySpeedSlow,
    optionKeySpeedFast,
    optionKeySpeedTurbo,
    optionKeyRestart,
    optionKeyStateLoad,
    optionKeyStateSave,
    optionKeyZoom,
    optionKeyChat,
    optionKeySpecTribe,
    optionKeyNuke,
    optionKeyInfo1,
    optionKeyInfo2,
    optionKeyInfo3,

    optionKeyMenuOkay,
    optionKeyMenuEdit,
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
    optionEdCopy,
    optionEdDelete,
    optionEdGrid,
    optionEdSelAll,
    optionEdSelFrame,
    optionEdSelAdd,
    optionEdForeground,
    optionEdBackground,
    optionEdMirror,
    optionEdRotate,
    optionEdDark,
    optionEdNoow,
    optionEdZoom,
    optionEdHelp,
    optionEdMenuSize,
    optionEdMenuVars,
    optionEdMenuSkills,
    optionEdAddTerrain,
    optionEdAddSteel,
    optionEdAddHatch,
    optionEdAddGoal,
    optionEdAddDeco,
    optionEdAddHazard,
    optionEdGridCustom,

    // mini-dialogue to greet a new player
    optionNewPlayerTitle,
    optionNewPlayerFirst,
    optionNewPlayerSecond,

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
        lines = fillVectorFromFile(fileLanguage);
    }
    catch (Exception e) {
        log(e.msg);
        if (fileLanguage != fileLanguageEnglish) {
            log("Falling back to English.");
            fileLanguage = new Filename(fileLanguageEnglish);
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
