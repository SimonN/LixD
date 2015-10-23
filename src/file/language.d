module file.language;

/*  enum Lang
 *
 *      has one ID for each to-be-translated string
 *
 *  string transl(Lang)
 *
 *      translate the ID
 *
 *  void load_userLanguage_and_if_not_exist_set_userOption_to_english()
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
    gameSpeed_slow,
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
    win_var_title,
    win_var_author,
    win_var_nameGerman,
    win_var_nameEnglish,
    win_var_initial,
    win_var_required,
    win_var_spawnintSlow,
    win_var_spawnintFast,
    win_var_clock,

    // editor window to set skills
    win_skill_title,
    win_skill_clear,
    win_skill_classic_8,
    win_skill_classic_12,
    win_skill_all_to,

    // exporting a level into a file
    export_single_lix,
    export_single_spawnint,
    export_single_clock,
    export_multi_lix,
    export_multi_spawnint,
    export_multi_clock,

    // network chat messages
    net_chat_welcome_1,
    net_chat_welcome_unstable,
    net_chat_welcome_2,
    net_chat_startServer,
    net_chat_startClient,
    net_chat_start_cancel,
    net_chat_disconnection,
    net_chat_we_too_old,
    net_chat_we_too_new,
    net_chat_someone_old,
    net_chat_someone_new,
    net_chat_named_guy_old,
    net_chat_version_yours,
    net_chat_version_server,
    net_chat_server_update,
    net_chat_please_download,
    net_chat_we_connected,
    net_chat_we_in_room,
    net_chat_we_in_room_2,
    net_chat_we_in_lobby,
    net_chat_player_in_room,
    net_chat_player_in_room_2,
    net_chat_player_in_lobby,
    net_chat_player_out_room,
    net_chat_player_out_room_2,
    net_chat_player_out_lobby,
    net_chat_level_change,
    net_game_start,
    net_game_how_to_chat_1,
    net_game_how_to_chat_2,
    net_game_end,
    net_game_end_result,
    net_game_overtime_1,
    net_game_overtime_2,
    net_game_overtime_2_one,
    net_game_overtime_3,
    net_game_overtime_4,
    net_game_overtime_4_one,
    net_game_overtime_4_sec,

    // Optionsfenster
    option_title,
    optionGroup_0,
    optionGroup_1,
    optionGroup_2,
    optionGroup_3,
    optionGroup_4,
    optionGroup_5,
    optionGroup_6,
    option_userName,
    option_userNameAsk,
    option_language,
    option_replayAutoMax,
    option_replayAutoSingle,
    option_replayAutoMulti,
    option_replayCancel,
    option_replayCancelAt,
    option_scrollEdge,
    option_scrollRight,
    option_scrollMiddle,
    option_mouseSpeed,
    option_scrollSpeedEdge,
    option_scrollSpeedClick,
    option_multipleBuilders,
    option_batterPriority,
    option_priorityInvertMiddle,
    option_priorityInvertRight,

    option_screenWindowed,
    option_screen_resolution,
    option_screenWindowed_res,
    option_screenVsync,
    option_arrowsReplay,
    option_arrowsNetwork,
    option_gameplayHelp,
    option_debrisAmount,
    option_debrisAmount_none,
    option_debrisAmount_own,
    option_debrisAmount_all,
    option_debrisType,
    option_debrisType_stars,
    option_debrisType_pixels,
    option_guiColorRed,
    option_guiColorGreen,
    option_guiColorBlue,
    option_info,
    option_gfx_zero,
    option_sound_load_driver,
    option_soundVolume,
    option_info_sound,

    option_key_unassigned,
    option_keyForceLeft,
    option_keyForceRight,
    option_keyScroll,
    option_keyPriorityInvert,
    option_keySpawnintSlower,
    option_keySpawnintFaster,
    option_keyPause,
    option_key_speed_slow,
    option_keySpeedFast,
    option_keySpeedTurbo,
    option_keyRestart,
    option_keyStateLoad,
    option_keyStateSave,
    option_keyZoom,
    option_keyChat,
    option_keySpecTribe,
    option_keyNuke,
    option_key_info_1,
    option_key_info_2,
    option_key_info_3,

    option_keyMenuOkay,
    option_keyMenuEdit,
    option_keyMenuExport,
    option_keyMenuDelete,
    option_keyMenuUpDir,
    option_keyMenuUpBy1,
    option_keyMenuUpBy5,
    option_keyMenuDownBy1,
    option_keyMenuDownBy5,
    option_keyMenuExit,

    option_ed_left,
    option_ed_right,
    option_ed_up,
    option_ed_down,
    option_ed_copy,
    option_ed_delete,
    option_ed_grid,
    option_ed_sel_all,
    option_ed_sel_frame,
    option_ed_sel_add,
    option_ed_foreground,
    option_ed_background,
    option_ed_mirror,
    option_ed_rotate,
    option_ed_dark,
    option_ed_noow,
    option_ed_zoom,
    option_ed_help,
    option_ed_menu_size,
    option_ed_menu_vars,
    option_ed_menu_skills,
    option_ed_addTerrain,
    option_ed_addSteel,
    option_ed_addHatch,
    option_ed_addGoal,
    option_ed_addDeco,
    option_ed_addHazard,
    option_ed_grid_custom,

    // mini-dialogue to greet a new player
    optionNew_player_title,
    optionNew_player_first,
    optionNew_player_second,

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
load_userLanguage_and_if_not_exist_set_userOption_to_english()
{
    IoLine[] lines;
    try
        lines = fillVectorFromFile(fileLanguage);
    catch (Exception e) {
        Log.log(e.msg);
        if (fileLanguage != fileLanguageEnglish) {
            Log.log("Falling back to English.");
            fileLanguage = new Filename(fileLanguageEnglish);
            load_userLanguage_and_if_not_exist_set_userOption_to_english();
            return;
        }
        else {
            Log.log("English language file not found. Broken installation?");
            return;
        }
    }
    // from here on, the user's language (fileLanguage) is not used anymore

    bool[Lang.MAX] lang_ids_read_in; // all false right now
    bool fn_written_to_log = false;

    void local_logf(T...)(string formatstr, T formatargs)
    {
        if (! fn_written_to_log) {
            fn_written_to_log = true;
            Log.logf("While reading `%s':", fileLanguage.rootless);
        }
        Log.logf("  " ~ formatstr, formatargs);
    }

    foreach (line; lines) {
        if (line.type != '$') continue;

        // now come lines in the format $lang_id my translated unquoted string
        Lang lang_id;
        try {
            lang_id = to!Lang(line.text1);
        }
        catch (ConvException) {
            local_logf("Unnecessary line: %s", line.text1);
            continue;
        }
        // now lang_id is a good index
        lang[lang_id] = line.text2;
        lang_ids_read_in[lang_id] = true;
    }
    // end foreach line

    // warn about undefined language IDs
    foreach (int id; 0 .. Lang.MAX) {
        if (! lang_ids_read_in[id]) {
            string lang_id_str = id.to!Lang.to!string;
            local_logf("New translation required: %s", lang_id_str);
            lang[id] = "!" ~ lang_id_str ~ "!";
        }
    }
    // end foreach for undefined IDs
}
// end function load_language_file
