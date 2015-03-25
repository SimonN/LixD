module file.language;

import std.array;

import file.log;

enum Language {
    NONE,
    ENGLISH,
    GERMAN,
    USERLANG,
    MAX
}

abstract class Lang {

    // opIndex implements Lang["my_key_string"];
    static string   opIndex(string key);

    static void     switch_to_language(Language);
    static Language get_current() { return current; }

private:

    static Language       current;
    static string[string] dict;

    static string[string] dict_eng;
    static string[string] dict_ger;

    @disable this() {}

    static void fill_eng_and_ger_dicts();



public:

static string opIndex(string key)
{
    if (key !in dict) {
        dict[key] = "!"~ key ~ "!";
        Log.log("Translation needed for:", key);
    }
    assert (key in dict);
    return dict[key];
}



static void switch_to_language(Language newlang)
{
    if (newlang == Language.USERLANG) {
        assert (false, "userlang not implemented");
    }
    else if (newlang == Language.ENGLISH) {
        if (dict_eng == null) fill_eng_and_ger_dicts();
        dict = dict_eng;
    }
    else if (newlang == Language.GERMAN) {
        if (dict_ger == null) fill_eng_and_ger_dicts();
        dict = dict_ger;
    }
    else {
        assert (false, "strange value for Lang.Language supplied");
    }
    current = newlang;
}



private static void fill_eng_and_ger_dicts()
{
    dict_eng = [
// fundamental things
"main_name_of_the_game"         : "Lix",
"main_loading_1"                : "---------- Loading Lix ----------",
"main_loading_2"                : "---------- Please Wait ----------",
"main_version"                  : "Version:",
"main_website"                  : "asdfasdf.ethz.ch/~simon",

// logging
"log_program_start_1"           : "Lix is starting...",
"log_program_start_2"           : "Lix successfully started.",
"log_program_exit"              : "Lix successfully exited.",

"log_found"                     : "found.",
"log_loaded"                    : "read.",
"log_file_not_found"            : "File not found:",
"log_bitmap_bad"                : "Bad picture:",

"log_level_unknown_bitmap"      : "Missing image:",
"log_level_file_saved"          : "File written:",

// used in various dialogues
"ok"                            : "Okay",
"cancel"                        : "Cancel",
"yes"                           : "Yes",
"no"                            : "No",
"back"                          : "Back",
"exit"                          : "Exit",
"dir_parent"                    : "..",
"dir_flip_page"                 : "(more...)",

// browsers
"browser_single_title"          : "Single Player",
"browser_network_title"         : "Select Multiplayer level",
"browser_replay_title"          : "Replays",
"browser_play"                  : "Play",
"browser_edit"                  : "Edit",
"browser_replay"                : "Replay",
"browser_delete"                : "Delete",
"browser_extract"               : "Extract level",
"browser_export_image"          : "Export image",
"browser_export_image_done"     : "Done.",

"browser_info_author"           : "By:",
"browser_info_initgoal"         : "Save:",
"browser_info_initial"          : "Lix:",
"browser_info_hatches"          : "Hatches:",
"browser_info_goals"            : "Goals:",
"browser_info_skills"           : "Skills:",
"browser_info_clock_2"          : "Overtime:",
"browser_info_author_none"      : "?",
"browser_info_clock_none"       : "--",

"browser_info_result_saved"     : "Saved:",
"browser_info_result_skills"    : "Skills used:",
"browser_info_result_time"      : "Time used:",
"browser_info_result_old_1"     : "The level has",
"browser_info_result_old_2"     : "been edited.",

"browser_info_player"           : "Player:",
"browser_info_version"          : "Game:",
"browser_info_built"            : "Level:",
"browser_info_new"              : "is too new",
"browser_info_same"             : "fits!",
"browser_info_old"              : "is too old",
"browser_info_holds_level"      : "contained",

"browser_box_delete_tit_rep"    : "Delete replay?",
"browser_box_delete_que_rep"    : "Do you really want to delete this replay?",
"browser_box_delete_tit_lev"    : "Delete level?",
"browser_box_delete_que_lev"    : "Do you really want to delete this level?",

// networking lobby
"win_lobby_title"               : "Network Game",
"win_lobby_title_lobby"         : "Lobby",
"win_lobby_title_room"          : "Room #",
"win_lobby_exit"                : "Leave network",
"win_lobby_unstable_central"    : "(Experimental version. Please don't "
                                  "use central server.)",
"win_lobby_start_central"       : "Connect to central server",
"win_lobby_start_server"        : "Host a game yourself",
"win_lobby_start_client"        : "Connect to:",
"win_lobby_chat"                : "Chat:",
"win_lobby_select_level"        : "Choose level",
"win_lobby_ready"               : "Ready for start",
"win_lobby_room_number"         : "Room #",
"win_lobby_room_player"         : "player",
"win_lobby_room_players"        : "players",
"win_lobby_room_create"         : "Open a new room",
"win_lobby_room_leave"          : "Leave room",

// end-of-game dialog, or pause dialog
"win_game_title"                : "Game Menu",
"win_game_result"               : "Result",
"win_game_lix_saved"            : "Lix saved:",
"win_game_lix_saved_in_time"    : "Lix saved in time:",
"win_game_resume"               : "Continue",
"win_game_restart"              : "Restart level",
"win_game_save_replay"          : "Save replay",
"win_game_menu"                 : "Exit",
"win_game_comment_perfect"      : "Perfect! All saved!",
"win_game_comment_more"         : "Super, more than necessary!",
"win_game_comment_exactly"      : "Target reached exactly!",
"win_game_comment_less"         : "Sorry, those were not enough.",
"win_game_comment_none"         : "That was nothing... Try again?",
"win_game_result_skills"        : "Skills used:",
"win_game_result_time"          : "Time taken:",
"win_game_net_first"            : "Awesome! You're the champion!",
"win_game_net_second"           : "Well done, nice second place.",
"win_game_net_middle"           : "An okay outcome... Revanche?",
"win_game_net_last"             : "Sorry, you lie behind this time.",
"win_game_net_first_tie"        : "Great, you're among the champs!",
"win_game_net_last_tie"         : "At least you're not alone there.",
"win_game_net_all_tie"          : "What's that? No true winner?",
"win_game_net_zero"             : "Rock bottom! Did you nuke them?",
"win_game_net_all_zero"         : "Do we have a nuclear winter?",
"win_game_replay_win_one"       : "has won!",
"win_game_replay_win_team"      : "have won!",
"win_game_replay_tie"           : "The game is a tie.",
"win_game_overwrite_title"      : "Overwrite Replay?",
"win_game_overwrite_question"   : "Do you really want to overwrite this replay?",

// help texts inside the game
"gameplay_rate_minus"           : "Raise spawn interval: Lix enter the level slower.",
"gameplay_rate_plus"            : "Lower spawn interval: Lix enter the level faster.",
"gameplay_pause"                : "Pause the game.",
"gameplay_zoom"                 : "Zoom into the level.",
"gameplay_speed_slow"           : "Slow motion.",
"gameplay_speed_fast"           : "Fast forward.",
"gameplay_speed_turbo"          : "Turbo fast forward.",
"gameplay_state_save"           : "Quicksave the current game position.",
"gameplay_state_load"           : "Load the previously quicksaved position.",
"gameplay_restart"              : "Restart the level.",
"gameplay_nuke"                 : "Nuke. Activate with a double click.",
"gameplay_hint_first"           : "View a hint for this level.",
"gameplay_hint_next"            : "View the next hint.",
"gameplay_hint_prev"            : "View the previous hint.",
"gameplay_hint_off"             : "Hide the hint.",
"gameplay_spec_tribe"           : "Examine the skills of a different team.",

// main editor screen
"editor_unsaved_title"          : "Save changes?",
"editor_unsaved_title_new"      : "Save level?",
"editor_unsaved_question"       : "Would you like to save the changes on this level?",
"editor_unsaved_question_new"   : "Would you like to save this new level?",
"editor_file_name"              : "File name:",
"editor_level_name"             : "Level title:",
"editor_hotkey"                 : "Hotkey:",
"editor_hotkey_hold"            : "Hotkey: hold",
"editor_bar_at"                 : "at",
"editor_bar_hover"              : "objects about to be selected.",
"editor_bar_selection"          : "objects selected.",
"editor_bar_movekeys_long"      : "Drag objects or move them with [",
"editor_bar_movekeys_short"     : "Move with [",
"editor_bar_movekeys_mid"       : "], [",
"editor_bar_movekeys_end"       : "].",

// save browser
"save_browser_title"            : "Save As",
"save_filename"                 : "File name:",
"save_box_overwrite_title"      : "Overwrite Level?",
"save_box_overwrite_question"   : "Do you really want to overwrite this level?",

// BitmapBrowser
"add_terrain "                  : "Add terrain",
"add_steel   "                  : "Add steel",
"add_hatch   "                  : "Add hatch",
"add_goal    "                  : "Add goal",
"add_deco    "                  : "Add decoration",
"add_hazard  "                  : "Add hazard",

// editor window about the size of map
"win_size_title"                : "Level Measures",
"win_size_l  "                  : "Left:",
"win_size_r  "                  : "Right:",
"win_size_u  "                  : "Top:",
"win_size_d  "                  : "Bottom:",
"win_size_x  "                  : "Width:",
"win_size_y  "                  : "Height:",
"win_size_hex"                  : "Show size in hexadecimal",
"win_size_torus_x"              : "Wrap around horizontally",
"win_size_torus_y"              : "Wrap around vertically",

// scrolling start position
"win_scroll_title"              : "Level Visuals",
"win_scroll_manual"             : "Manually set initially visible region",
"win_scroll_x"                  : "X Coordinate (0 : left)",
"win_scroll_y"                  : "Y Coordinate (0 : top)",
"win_scroll_r"                  : "Background red",
"win_scroll_g"                  : "Background green",
"win_scroll_b"                  : "Background blue",
"win_scroll_jump"               : "Scroll there",
"win_scroll_current"            : "Current Position",

// editor window to set level variables
"win_var_title"                 : "General Level Settings",
"win_var_author"                : "Author",
"win_var_name_german"           : "German title",
"win_var_name_english"          : "English title",
"win_var_initial"               : "No. of lix",
"win_var_required"              : "Lix to save",
"win_var_spawnint_slow"         : "Spawn interval",
"win_var_spawnint_fast"         : "Spawn int. fast",
"win_var_clock"                 : "Time/overtime",

// editor window to set skills
"win_skill_title"               : "Skill Settings",
"win_skill_clear"               : "Clear all",
"win_skill_classic_8"           : "Classic 8",
"win_skill_classic_12"          : "Modern 12",
"win_skill_all_to"              : "Adjust all:",

// exporting a level into a file
"export_single_lix"             : "Save:",
"export_single_spawnint"        : "Spawn int.:",
"export_single_clock"           : "Time:",
"export_multi_lix"              : "Lix:",
"export_multi_spawnint"         : "Spawn int.:",
"export_multi_clock"            : "Overtime:",

// network chat messages
"net_chat_welcome_1"            : "You can join the central server, "
                                  "host a game yourself,",
"net_chat_welcome_2"            : "or enter an IP address/a host name "
                                  "and click \"Connect to:\".",
"net_chat_unstable_1"           : "This is an experimental version. "
                                  "Host a game yourself",
"net_chat_unstable_2"           : "or enter an IP address/a host name "
                                  "and click \"Connect to:\".",
"net_chat_start_server"         : "You are the server. Other "
                                  "players can connect to you now.",
"net_chat_start_client"         : "Searching a server at",
"net_chat_start_cancel"         : "Connection attempt cancelled.",
"net_chat_disconnection"        : " has quit the network.",
"net_chat_we_too_old"           : "You have too old a Lix version "
                                  "to connect to the server.",
"net_chat_we_too_new"           : "You have too new a Lix version. "
                                  "The server should upgrade.",
"net_chat_someone_old"          : "Someone with too old a Lix version "
                                  "tried to connect.",
"net_chat_someone_new"          : "Someone with too new a Lix version "
                                  "tried to connect.",
"net_chat_named_guy_old"        : " must update his Lix version to "
                                  "continue.",
"net_chat_version_yours"        : "Your version is ",
"net_chat_version_server"       : ", the server requires ",
"net_chat_server_update"        : "The server should update to the "
                                  "most recent Lix version.",
// DTODO: add main website in the caller
"net_chat_please_download"      : "Download the newest version from: ",
"net_chat_we_connected"         : "You have joined the network. "
                                  "Enter a room to start playing.",
"net_chat_we_in_room"           : "You have entered room #",
"net_chat_we_in_room_2"         : ".",
"net_chat_we_in_lobby"          : "You went back into the lobby.",
"net_chat_player_in_room"       : " has joined room #",
"net_chat_player_in_room_2"     : ".",
"net_chat_player_in_lobby"      : " has entered the lobby.",
"net_chat_player_out_room"      : " has entered room #",
"net_chat_player_out_room_2"    : ".",
"net_chat_player_out_lobby"     : " has left the room.",
"net_chat_level_change"         : "has selected this level:",
"net_game_start"                : "The game has started.",
"net_game_how_to_chat_1"        : " Press [",
"net_game_how_to_chat_2"        : "] to chat.",
"net_game_end"                  : "The game is over.",
"net_game_end_result"           : "Game outcome:",
"net_game_overtime_1"           : "has finished playing and has saved",
"net_game_overtime_2"           : "lix.",
"net_game_overtime_2_one"       : "one lix.",
"net_game_overtime_3"           : "Now, the overtime of",
"net_game_overtime_4"           : "minutes will begin!",
"net_game_overtime_4_one"       : "minute will begin!",
"net_game_overtime_4_sec"       : "seconds will begin!",

// Optionsfenster
"option_title"                  : "Options",
"option_group_0"                : "General",
"option_group_1"                : "Controls",
"option_group_2"                : "Hotkeys",
"option_group_3"                : "Editor",
"option_group_4"                : "Menu",
"option_group_5"                : "Graphics",
"option_group_6"                : "Sound",
"option_user_name"              : "Player name",
"option_user_name_ask"          : "Ask for name on startup",
"option_language"               : "Language",
"option_replay_auto_max"        : "Max. auto replays",
"option_replay_auto_single"     : "Auto replay in Singleplayer",
"option_replay_auto_multi"      : "Auto replay in Multiplayer",
"option_replay_cancel"          : "Replay ends: normal speed...",
"option_replay_cancel_at"       : "...1/15 sec before end",
"option_scroll_edge"            : "Scroll at screen border",
"option_scroll_right"           : "Scroll with right click",
"option_scroll_middle"          : "Scroll with middle click",
"option_mouse_speed"            : "Mouse speed",
"option_scroll_speed_edge"      : "Edge scroll speed",
"option_scroll_speed_click"     : "Right/mid. scroll spd.",
"option_multiple_builders"      : "Builders: multiple clicks",
"option_batter_priority"        : "Avoid Exploder -> Batter",
"option_prioinv_middle"         : "Middle button inverts priority",
"option_prioinv_right"          : "Right button inverts priority",

"option_screen_windowed"        : "Windowed mode*",
"option_screen_resolution"      : "Fullscreen resol.**",
"option_screen_windowed_res"    : "Windowed resolution",
"option_screen_vsync"           : "Wait for V-sync",
"option_arrows_replay"          : "Arrows during replays",
"option_arrows_network"         : "Arrows in network games",
"option_gameplay_help"          : "Display game hotkeys",
"option_debris_amount"          : "Debris amount",
"option_debris_amount_none"     : "None",
"option_debris_amount_own"      : "Own",
"option_debris_amount_all"      : "All",
"option_debris_type"            : "Debris type",
"option_debris_type_stars"      : "Stars, clouds",
"option_debris_type_pixels"     : "Pixels",
"option_gui_color_red"          : "Menu color red",
"option_gui_color_green"        : "Menu color green",
"option_gui_color_blue"         : "Menu color blue",
"option_info "                  : "*) Hit [Alt] + [Enter] to toggle full"
                                  "screen/windowed mode at any time.",
"option_gfx_zero"               : "**) Enter 0 in both fields to use "
                                  "your normal desktop resolution.",
"option_sound_load_driver"      : "Load sound driver*",
"option_sound_volume"           : "Sound volume",
"option_info_sound"             : "*) This option requires a program "
                                  "restart to take effect.",

"option_key_unassigned"         : "none",
"option_key_force_left"         : "Force left",
"option_key_force_right"        : "Force right",
"option_key_scroll"             : "Hold to scroll",
"option_key_priority"           : "Priority invert",
"option_key_rate_minus"         : "Rate down",
"option_key_rate_plus"          : "Rate up",
"option_key_pause"              : "Pause",
"option_key_speed_slow"         : "Slow motion",
"option_key_speed_fast"         : "Fast forw.",
"option_key_speed_turbo"        : "Turbo speed",
"option_key_restart"            : "Restart",
"option_key_state_load"         : "Load state",
"option_key_state_save"         : "Save state",
"option_key_zoom"               : "Zoom",
"option_key_chat"               : "Chat",
"option_key_spec_tribe"         : "Cycle spectated teams",
"option_key_nuke"               : "Nuke",
"option_key_info_1"             : "A hotkey assigned to",
"option_key_info_2"             : "multiple skills will",
"option_key_info_3"             : "alternate between them.",

"option_key_me_okay"            : "Okay/yes",
"option_key_me_edit"            : "Edit",
"option_key_me_export"          : "Export",
"option_key_me_delete"          : "Delete/no",
"option_key_me_up_dir"          : "Parent dir",
"option_key_me_up_1"            : "Up by 1",
"option_key_me_up_5"            : "Up by 5",
"option_key_me_down_1"          : "Down by 1",
"option_key_me_down_5"          : "Down by 5",
"option_key_me_exit"            : "Back/cancel",

"option_ed_left"                : "Move left",
"option_ed_right"               : "Move right",
"option_ed_up"                  : "Move up",
"option_ed_down"                : "Move down",
"option_ed_copy"                : "Copy",
"option_ed_delete"              : "Delete",
"option_ed_grid"                : "Grid size",
"option_ed_sel_all"             : "Select all",
"option_ed_sel_frame"           : "Select frame",
"option_ed_sel_add"             : "Add to sel.",
"option_ed_foreground"          : "Foreground",
"option_ed_background"          : "Background",
"option_ed_mirror"              : "Mirror",
"option_ed_rotate"              : "Rotate",
"option_ed_dark"                : "Draw black",
"option_ed_noow"                : "No overwrite",
"option_ed_zoom"                : "Zoom",
"option_ed_help"                : "Show help",
"option_ed_menu_size"           : "Size menu",
"option_ed_menu_vars"           : "General menu",
"option_ed_menu_skills"         : "Skills menu",
"option_ed_add_terrain"         : "Add terrain",
"option_ed_add_steel"           : "Add steel",
"option_ed_add_hatch"           : "Add hatch",
"option_ed_add_goal"            : "Add goal",
"option_ed_add_deco"            : "Add deco",
"option_ed_add_hazard"          : "Add hazard",
"option_ed_grid_custom"         : "Custom grid size",

// mini-dialogue to greet a new player
"option_new_player_title"       : "Lix",
"option_new_player_first"       : "Hello and Welcome!",
"option_new_player_second"      : "Please enter your name:"
    ];

    dict_ger = dict_eng; // DTODO: do the German strings
}
// end static function to fill the dictionary

// DTODO: do the editor help strings
/*
eb[Editor::FILE_NEW]
 = "New: Deletes everything on screen and starts a new level.";
eb[Editor::FILE_EXIT]
 = "Quit: Exits the editor and asks about saving changed data.";
eb[Editor::FILE_SAVE]
 = "Save: Saves the current level under its current file name.";
eb[Editor::FILE_SAVE_AS]
 = "Save As: Saves the current level under a new file name.";
eb[Editor::GRID_2]
 = "Grid 2: Rounds object coordinates to multiples of 2.";
eb[Editor::GRID_CUSTOM]
 = "Custom grid: This grid size is settable in the options.";
eb[Editor::GRID_16]
 = "Grid 16: Rounds object coordinates to multiples of 16.";
eb[Editor::SELECT_ALL]
 = "Everything: Selects all objects in the level.";
eb[Editor::SELECT_FRAME]
 = "Frame: Selects multiple objects by dragging a frame.";
eb[Editor::SELECT_ADD]
 = "Add: Selects new objects, keeping old ones in the selection.";
eb[Editor::SELECT_COPY]
 = "Copy: Clones the selected objects for placing them elsewhere.";
eb[Editor::SELECT_DELETE]
 = "Delete: Removes the selected objects.";
eb[Editor::SELECT_MINUS]
 = "Back: Puts the selected objects behind some others.";
eb[Editor::SELECT_PLUS]
 = "Forth: Puts the selected objects in front of some others.";
eb[Editor::SELECT_BACK]
 = "Background: Puts the selected objects into the background.";
eb[Editor::SELECT_FRONT]
 = "Foreground: Puts the selected objects into the foreground.";
eb[Editor::SELECT_FLIP]
 = "Flip: Mirrors the selected terrain horizontally.";
eb[Editor::SELECT_ROTATE]
 = "Rotate: Performs a quarter turn on the selected terrain.";
eb[Editor::SELECT_DARK]
= "Dark: Paints the selected terrain in black inside the game.";
eb[Editor::SELECT_NOOW]
= "No overwrite: Selected terrain overwrites only dark objects.";
eb[Editor::VIEW_ZOOM]
= "Zoom: Activate or deactivate the map zoom.";
eb[Editor::HELP]
 = "(this doesn't do anything right now)";
eb[Editor::MENU_SIZE]
 = "Measures: Set the size and the topology for the level.";
eb[Editor::MENU_SCROLL]
 = "Visuals: Set the scrolling position and background color.";
eb[Editor::MENU_VARS]
 = "Variables: Set the fundamental level variables.";
eb[Editor::MENU_SKILL]
 = "Skills: Set the usable lix skills.";
eb[Editor::ADD_TERRAIN]
 = "Terrain: Add a terrain object that can be dug through.";
eb[Editor::ADD_STEEL]
 = "Steel: Add a steel object that cannot be dug through.";
eb[Editor::ADD_HATCH]
 = "Hatch: Add a lix entrance hatch.";
eb[Editor::ADD_GOAL]
 = "Goal: Add a goal, i.e. an exit for the lix.";
eb[Editor::ADD_DECO]
 = "Decoration: Add a non-interactive decoration object.";
eb[Editor::ADD_HAZARD]
 = "Hazard: Add a trap, water or fire.";
*/

}
// end class
