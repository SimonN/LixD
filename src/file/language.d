module file.language;

/*  enum Lang
 *      has one ID for each to-be-translated string
 *
 *  string transl(Lang)
 *      translate the ID
 *
 *  string descr(Lang)
 *      give a translated longer `|'-linebroken description for the options
 *
 *  string skillTooltip(Ac)
 *      give the skill tooltip if defined or empty string
 *
 *  void loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
 *      Should be used by loading the user file, or by the options dialogue.
 *      Both of these write to the user file anyway.
 */

import enumap;

import std.array;
import std.algorithm;
import std.conv; // (enum constant) --to!Lang--> (string of its variable name)
import std.format;

import basics.globals; // fileLanguageEnglish
import file.option; // fileLanguage, which file does the user want
import file.io;
import file.log;
import file.filename;
import net.ac;

nothrow @nogc @safe {
    string transl(in Lang key) { return _lang[key].transl; }
    string[] descr(in Lang key) { return _lang[key].descr; }
    string skillTooltip(in Ac ac) { return _skillTooltips[ac]; }
}

// Get a translated string after %d/%s substitution.
// If the translation doesn't allow substitution, log and return fallback.
nothrow string translf(FormatArgs...)(in Lang key, FormatArgs args)
{
    static assert (args.length >= 1,
        "Call transl instead of translf for 0 args.");
    try {
        return format(key.transl, args);
    }
    catch (Exception e) {
        logf("Cannot format translation of `%s':", key);
        logf("    -> Translation is `%s'", key.transl);
        logf("    -> %s", e.msg);
    }
    try {
        return text(key.transl, args);
    }
    catch (Exception) {
        return key.transl;
    }
}

void loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
{
    _fnWrittenToLog = false;
    IoLine[] lines = readFileUserLanguageOrNullArray();
    foreach (line; lines.filter!(l => l.type == '$')) {
        if (line.text1 == skillTooltipKeyword)
            parseSkillTooltip(line.text2);
        else
            parseTranslation(line.text1, line.text2);
    }
    warnAboutUndefinedLanguageIds();
}

string formattedWinTopologyWarnSize2() // strange here, but it's needed 2x
{
    return format!"\u2265 %3.1f \u00D7 2\u00b2\u2070 %s"(
        // greaterThan %d times 2^20 pixels
        levelPixelsToWarn * 1.0f / 2^^20,
        Lang.winTopologyWarnSize2.transl);
}

enum Lang {
    // fundamental things
    mainNameOfLanguage,

    // game and versioning
    versioningVersion,
    versioningForOperatingSystem,

    // used in various dialogues
    commonOk,
    commonCancel,
    commonNo,
    commonBack,
    commonExit,
    mainMenuGetMusic,

    // browsers
    browserSingleTitle,
    browserNetworkTitle,
    browserPlay,
    browserEdit,
    browserNewLevel,
    browserDelete,
    browserSearch,
    browserOpenRepForLev,
    browserExportImage,
    browserExportImageDone,
    browserMkdirTitle,
    browserMkdirPleaseEnter,

    browserReplayTitle,
    browserReplayPointedTo,
    browserReplayVerifyDir,

    winVerifyTitle,
    winVerifyOutputWrittenTo,
    verifyHeader,
    verifyStatisticsFrom,
    verifyTrophiesUpdated,
    verifyLevelsNoProof,
    verifyDirectoryCoverage,
    verifyAllLevelsCovered,
    verifySomeLevelsCovered,
    verifyStatusMultiplayer,
    verifyStatusNoPointer,
    verifyStatusMissingLevel,
    verifyStatusBadLevel,
    verifyStatusFailed,
    verifyStatusMercyKilled,
    verifyStatusSolved,

    previewLevelAuthor,
    previewLevelSingleGoal,
    previewLevelSingleTrophySaved,
    previewLevelSingleTrophySkills,
    previewLevelMultiIntendedNumPlayers,
    previewReplayPlayer,
    previewReplayPointsTo,
    previewMissingTiles,
    previewMissingTilesMoreSee,

    harvestYouSavedThisTime,
    harvestReplayAutoSaved,
    harvestReplaySaveManuallyAtAll,
    harvestReplaySaveManuallyToo,

    winSearchTitle,
    winSearchPrompt,

    repForLevTitle,

    // Singleplayer outcome
    outcomeRetryOldLevel,
    outcomeYouSolvedOldLevel,
    outcomeAttemptNextLevel,
    outcomeResolveNextLevel,
    outcomeAttemptNextUnsolvedLevel,
    outcomeExitToSingleBrowser,

    outcomeTrophyLixSaved,
    outcomeTrophySkillsUsed,
    outcomeTrophyYourAttempt,
    outcomeTrophyPreviousRecord,

    // networking lobby
    winLobbyTitle,
    winLobbyDisconnect,
    winLobbyStartCentral,
    winLobbyStartServer,
    winLobbyStartCustom,
    winLobbyTitleAddress,
    winLobbyTitlePort,
    winLobbyChat,
    winLobbySelectLevel,
    winLobbyReady,
    winLobbyRoomNumber,
    winLobbyRoomInhabitants,
    winLobbyRoomCreate,
    winLobbyRoomLeave,

    handicapTitle,
    handicapPhilosophy1,
    handicapPhilosophy2,
    handicapPhilosophy3,
    handicapInitialLix,
    handicapInitialLixNormal,
    handicapInitialSkills,
    handicapInitialSkillsNormal,
    handicapSpawnDelay,
    handicapSpawnDelayNormal,
    handicapScore,
    handicapScoreNormal,

    // Multiplayer interruption dialog
    winAbortNetgameTitle,
    winAbortNetgameContinuePlaying,
    winAbortNetgameExitToLobby,

    // help texts inside the game
    gameForceLeft,
    gameForceRight,
    gamePriorityInvert,
    gameQueueBuilder,
    gameQueuePlatformer,
    gameHoldToScroll,
    gameClickToCancelReplay,
    gameFramestepOrQuit,
    gamePause,
    gameZoom,
    gameShowSplatRuler,
    gameHighlightGoals,
    gameStateSave,
    gameStateLoad,
    gameShowTweaker,
    gameFramestepBack,
    gameFramestepAhead,
    gameFastForward,
    gameRestart,
    gameNuke,

    tweakerHeaderLixID,
    tweakerHeaderPhyu,
    tweakerLineNow,
    tweakerEmptyListTitle,
    tweakerEmptyListDesc1,
    tweakerEmptyListDesc2,
    tweakerEmptyListDesc3,

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
    editorButtonMirrorHorizontally,
    editorButtonFlipVertically,
    editorButtonSelectRotate,
    editorButtonSelectDark,
    editorButtonViewZoom,
    editorButtonAddTerrain,
    editorButtonAddSteel,
    editorButtonAddHatch,
    editorButtonAddGoal,
    editorButtonAddHazard,
    editorButtonMenuConstants,
    editorButtonMenuTopology,
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
    winTopologyWarnSize1,
    winTopologyWarnSize2,
    winTopologyWarnSize3,

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
    netChatEnetDLLMissing,
    netChatStartClient,
    netChatStartCancel,
    netChatYouLoggedOut,
    netChatYouCannotConnect,
    netChatYouLostConnection,
    netChatPeerDisconnected,
    netChatVersionServerSuggests,
    netChatVersionRoomRequires,
    netChatVersionYours,
    netChatPleaseDownload,
    netChatWeInRoom,
    netChatWeInLobby,
    netChatPlayerInRoom,
    netChatPlayerInLobby,
    netChatPlayerOutRoom,
    netChatPlayerOutLobby,
    netChatHandicapSet,
    netChatHandicapUnset,
    netChatLevelChange,
    netGameHowToChat,
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
    optionSplatRulerDesign,
    optionSplatRulerDesignTwoBars,
    optionSplatRulerDesign094,
    optionSplatRulerDesignSuperSnap,

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
    optionKeyShowTweaker,
    optionKeyChat,
    optionKeyShowSplatRuler,
    optionKeyHighlightGoals,
    optionKeyNuke,

    optionKeyMenuOkay,
    optionKeyMenuEdit,
    optionKeyMenuNewLevel,
    optionKeyMenuRepForLev,
    optionKeyMenuExport,
    optionKeyMenuDelete,
    optionKeyMenuUpDir,
    optionKeyMenuUpBy1,
    optionKeyMenuUpBy5,
    optionKeyMenuDownBy1,
    optionKeyMenuDownBy5,
    optionKeyMenuExit,

    optionKeyOutcomeSaveReplay,
    optionKeyOutcomeOldLevel,
    optionKeyOutcomeNextLevel,
    optionKeyOutcomeNextUnsolved,

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
    optionEdMirrorHorizontally,
    optionEdFlipVertically,
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

/////////////////////////////////////////////////////////////////////// private

private:
    enum string skillTooltipKeyword = "skillTooltip";

    // translated strings of currently loaded language
    struct Transl {
        string transl;
        string[] descr;
    }
    Transl[Lang.MAX] _lang;
    Enumap!(Ac, string) _skillTooltips;

    bool _fnWrittenToLog = false;

    void localLogf(T...)(string formatstr, T formatargs)
    {
        if (! _fnWrittenToLog) {
            _fnWrittenToLog = true;
            logf("While reading `%s':", fileLanguage.rootless);
        }
        logf("    -> " ~ formatstr, formatargs);
    }

    IoLine[] readFileUserLanguageOrNullArray()
    in {
        assert (languageBasenameNoExt !is null,
            "Initialize user options before reading language files");
    }
    do {
        try {
            assert (fileLanguage !is null);
            return fillVectorFromFile(fileLanguage);
        }
        catch (Exception e) {
            log(e.msg);
            if (! languageIsEnglish) {
                log("Falling back to English.");
                languageBasenameNoExt = englishBasenameNoExt;
                return readFileUserLanguageOrNullArray();
            }
            else {
                log("English language file not found. Broken installation?");
                return null;
            }
        }
    }

    void parseTranslation(in string key, in string translFromFile)
    {
        Lang langId;
        try {
            langId = key.to!Lang;
        }
        catch (ConvException) {
            localLogf("Unnecessary line: %s", key);
            return;
        }
        auto range = translFromFile.splitter('|');
        if (range.empty)
            return;
        _lang[langId].transl = range.front;
        range.popFront;
        if (range.empty)
            return;
        _lang[langId].descr = range.array; // all remaining fields
    }

    void parseSkillTooltip(in string acBarTooltip)
    {
        auto range = acBarTooltip.splitter('|');
        if (range.empty)
            return;
        Ac ac = stringToAc(range.front);
        if (ac == Ac.max) {
            localLogf("Unknown skill: %s", range.front);
            return;
        }
        range.popFront;
        _skillTooltips[ac] = range.empty ? "" : range.front;
    }

    void warnAboutUndefinedLanguageIds()
    {
        foreach (int id; 0 .. Lang.MAX) {
            if (_lang[id].transl.length > 0)
                continue;
            string langIdStr = id.to!Lang.to!string;
            localLogf("New translation required: %s", langIdStr);
            _lang[id].transl = "!" ~ langIdStr ~ "!";
        }
    }
