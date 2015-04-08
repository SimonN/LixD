module file.language;

/*  enum Lang
 *
 *      has one ID for each to-be-translated string
 *
 *  string transl(Lang)
 *
 *      translate the ID
 *
 *  void load_user_language_and_if_not_exist_set_user_option_to_english()
 *
 *      Should be used by loading the user file, or by the options dialogue.
 *      Both of these write to the user file anyway.
 */

import std.conv; // (enum constant) <-> (string of its variable name)
                 // This is done by to!Lang or to!string. This capability
                 // for D enums is awesome, the entire module is built on it

import basics.globals; // file_language_english
import basics.user;    // file_language, which file does the user want
import file.io;
import file.log;
import file.filename;

enum Lang {
    // fundamental things
    main_name_of_language,
    main_loading_1,
    main_loading_2,
    main_version,

    // used in various dialogues
    common_ok,
    common_cancel,
    common_yes,
    common_no,
    common_back,
    common_exit,
    common_dir_parent,
    common_dir_flip_page,

    // browsers
    browser_single_title,
    browser_network_title,
    browser_replay_title,
    browser_play,
    browser_edit,
    browser_replay,
    browser_delete,
    browser_extract,
    browser_export_image,
    browser_export_image_done,

    browser_info_author,
    browser_info_initgoal,
    browser_info_initial,
    browser_info_hatches,
    browser_info_goals,
    browser_info_skills,
    browser_info_clock_2,
    browser_info_author_none,
    browser_info_clock_none,

    browser_info_result_saved,
    browser_info_result_skills,
    browser_info_result_time,
    browser_info_result_old_1,
    browser_info_result_old_2,

    browser_info_player,
    browser_info_version,
    browser_info_built,
    browser_info_new,
    browser_info_same,
    browser_info_old,
    browser_info_holds_level,

    browser_box_delete_tit_rep,
    browser_box_delete_que_rep,
    browser_box_delete_tit_lev,
    browser_box_delete_que_lev,

    // networking lobby
    win_lobby_title,
    win_lobby_title_lobby,
    win_lobby_title_room,
    win_lobby_exit,
    win_lobby_unstable_central,
    win_lobby_start_central,
    win_lobby_start_server,
    win_lobby_start_client,
    win_lobby_chat,
    win_lobby_select_level,
    win_lobby_ready,
    win_lobby_room_number,
    win_lobby_room_player,
    win_lobby_room_players,
    win_lobby_room_create,
    win_lobby_room_leave,

    // end-of-game dialog, or pause dialog
    win_game_title,
    win_game_result,
    win_game_lix_saved,
    win_game_lix_saved_in_time,
    win_game_resume,
    win_game_restart,
    win_game_save_replay,
    win_game_menu,
    win_game_comment_perfect,
    win_game_comment_more,
    win_game_comment_exactly,
    win_game_comment_less,
    win_game_comment_none,
    win_game_result_skills,
    win_game_result_time,
    win_game_net_first,
    win_game_net_second,
    win_game_net_middle,
    win_game_net_last,
    win_game_net_first_tie,
    win_game_net_last_tie,
    win_game_net_all_tie,
    win_game_net_zero,
    win_game_net_all_zero,
    win_game_replay_win_one,
    win_game_replay_win_team,
    win_game_replay_tie,
    win_game_overwrite_title,
    win_game_overwrite_question,

    // help texts inside the game
    gameplay_rate_minus,
    gameplay_rate_plus,
    gameplay_pause,
    gameplay_zoom,
    gameplay_speed_slow,
    gameplay_speed_fast,
    gameplay_speed_turbo,
    gameplay_state_save,
    gameplay_state_load,
    gameplay_restart,
    gameplay_nuke,
    gameplay_hint_first,
    gameplay_hint_next,
    gameplay_hint_prev,
    gameplay_hint_off,
    gameplay_spec_tribe,

    // main editor screen
    editor_unsaved_title,
    editor_unsaved_title_new,
    editor_unsaved_question,
    editor_unsaved_question_new,
    editor_file_name,
    editor_level_name,
    editor_hotkey,
    editor_hotkey_hold,
    editor_bar_at,
    editor_bar_hover,
    editor_bar_selection,
    editor_bar_movekeys_long,
    editor_bar_movekeys_short,
    editor_bar_movekeys_mid,
    editor_bar_movekeys_end,

    // make sure these come in the same order as the editor button enum.
    // I don't know how to generate source code for these these enum values.
    // If you have cute D code for that, tell me. :-)
    editor_button_FILE_NEW,
    editor_button_FILE_EXIT,
    editor_button_FILE_SAVE,
    editor_button_FILE_SAVE_AS,
    editor_button_GRID_2,
    editor_button_GRID_CUSTOM,
    editor_button_GRID_16,
    editor_button_SELECT_ALL,
    editor_button_SELECT_FRAME,
    editor_button_SELECT_ADD,
    editor_button_SELECT_COPY,
    editor_button_SELECT_DELETE,
    editor_button_SELECT_MINUS,
    editor_button_SELECT_PLUS,
    editor_button_SELECT_BACK,
    editor_button_SELECT_FRONT,
    editor_button_SELECT_FLIP,
    editor_button_SELECT_ROTATE,
    editor_button_SELECT_DARK,
    editor_button_SELECT_NOOW,
    editor_button_VIEW_ZOOM,
    editor_button_HELP,
    editor_button_MENU_SIZE,
    editor_button_MENU_SCROLL,
    editor_button_MENU_VARS,
    editor_button_MENU_SKILL,
    editor_button_ADD_TERRAIN,
    editor_button_ADD_STEEL,
    editor_button_ADD_HATCH,
    editor_button_ADD_GOAL,
    editor_button_ADD_DECO,
    editor_button_ADD_HAZARD,

    // save browser
    save_browser_title,
    save_filename,
    save_box_overwrite_title,
    save_box_overwrite_question,

    // BitmapBrowser
    add_terrain,
    add_steel,
    add_hatch,
    add_goal,
    add_deco,
    add_hazard,

    // editor window about the size of map
    win_size_title,
    win_size_l,
    win_size_r,
    win_size_u,
    win_size_d,
    win_size_x,
    win_size_y,
    win_size_hex,
    win_size_torus_x,
    win_size_torus_y,

    // scrolling start position
    win_scroll_title,
    win_scroll_manual,
    win_scroll_x,
    win_scroll_y,
    win_scroll_r,
    win_scroll_g,
    win_scroll_b,
    win_scroll_jump,
    win_scroll_current,

    // editor window to set level variables
    win_var_title,
    win_var_author,
    win_var_name_german,
    win_var_name_english,
    win_var_initial,
    win_var_required,
    win_var_spawnint_slow,
    win_var_spawnint_fast,
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
    net_chat_start_server,
    net_chat_start_client,
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
    option_group_0,
    option_group_1,
    option_group_2,
    option_group_3,
    option_group_4,
    option_group_5,
    option_group_6,
    option_user_name,
    option_user_name_ask,
    option_language,
    option_replay_auto_max,
    option_replay_auto_single,
    option_replay_auto_multi,
    option_replay_cancel,
    option_replay_cancel_at,
    option_scroll_edge,
    option_scroll_right,
    option_scroll_middle,
    option_mouse_speed,
    option_scroll_speed_edge,
    option_scroll_speed_click,
    option_multiple_builders,
    option_batter_priority,
    option_prioinv_middle,
    option_prioinv_right,

    option_screen_windowed,
    option_screen_resolution,
    option_screen_windowed_res,
    option_screen_vsync,
    option_arrows_replay,
    option_arrows_network,
    option_gameplay_help,
    option_debris_amount,
    option_debris_amount_none,
    option_debris_amount_own,
    option_debris_amount_all,
    option_debris_type,
    option_debris_type_stars,
    option_debris_type_pixels,
    option_gui_color_red,
    option_gui_color_green,
    option_gui_color_blue,
    option_info,
    option_gfx_zero,
    option_sound_load_driver,
    option_sound_volume,
    option_info_sound,

    option_key_unassigned,
    option_key_force_left,
    option_key_force_right,
    option_key_scroll,
    option_key_priority,
    option_key_rate_minus,
    option_key_rate_plus,
    option_key_pause,
    option_key_speed_slow,
    option_key_speed_fast,
    option_key_speed_turbo,
    option_key_restart,
    option_key_state_load,
    option_key_state_save,
    option_key_zoom,
    option_key_chat,
    option_key_spec_tribe,
    option_key_nuke,
    option_key_info_1,
    option_key_info_2,
    option_key_info_3,

    option_key_me_okay,
    option_key_me_edit,
    option_key_me_export,
    option_key_me_delete,
    option_key_me_up_dir,
    option_key_me_up_1,
    option_key_me_up_5,
    option_key_me_down_1,
    option_key_me_down_5,
    option_key_me_exit,

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
    option_ed_add_terrain,
    option_ed_add_steel,
    option_ed_add_hatch,
    option_ed_add_goal,
    option_ed_add_deco,
    option_ed_add_hazard,
    option_ed_grid_custom,

    // mini-dialogue to greet a new player
    option_new_player_title,
    option_new_player_first,
    option_new_player_second,

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
load_user_language_and_if_not_exist_set_user_option_to_english()
{
    IoLine[] lines;
    bool lang_file_loaded = fill_vector_from_file(lines, file_language);

    if (! lang_file_loaded && file_language != file_language_english) {
        Log.log("Falling back to English.");
        file_language = new Filename(file_language_english);
        lang_file_loaded = fill_vector_from_file(lines, file_language);
        if (! lang_file_loaded) {
            Log.log("English language file not found. Broken installation?");
        }
    }
    // from here on, the user's language (file_language) is not used anymore

    bool[Lang.MAX] lang_ids_read_in; // all false right now
    bool fn_written_to_log = false;

    void local_logf(T...)(string formatstr, T formatargs)
    {
        if (! lang_file_loaded) return; // IO routine has logged 404 already
        if (! fn_written_to_log) {
            fn_written_to_log = true;
            Log.logf("While reading `%s':", file_language.get_rootless());
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
