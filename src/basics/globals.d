module basics.globals;

import file.filename;

// globals.d contains all the compile-time _constants_ accessible from
// throughout the game. Global variables that may change are in globconf.d,
// those are the variables saved into the global config file.

const int ticks_per_sec     = 60;
const int skill_max         = 12;
const int panel_gameplay_yl = 80;
const int panel_editor_yl   = 80;
const int scroll_torus_max  =  2;

const net_ip_localhost             = "127.0.0.1";
const error_wrong_working_dir      = "Wrong working directory!\n"
                                    "Run the game from its root directory\n"
                                    "or from its subdirectory bin/.\n"
                                    "\n"
                                    "Falsches Arbeitsverzeichnis!\n"
                                    "Starte das Spiel aus seinem\n"
                                    "Wurzelverzeichnis oder aus bin/.\n";
// loading files
const ext_level                    = ".txt";
const ext_level_orig               = ".lvl";
const ext_level_lemmini            = ".ini";
const ext_replay                   = ".txt";
const ext_user                     = ".txt";
const ext_object_definitions       = ".txt";
const mask_anything                = "*.*";
const mask_ext_replay              = "*.txt";
const mask_ext_user                = "*.txt";

const file_level_dir_order         = "_order.X.txt";
const file_level_dir_english       = "_english.X.txt";
const file_level_dir_german        = "_german.X.txt";
const file_level_dir_userlang      = "_userlang.X.txt";

// pre-extensions of image files
const pre_ext_null                 = ":"; // this should never be used
const pre_ext_internal             = "I";
const pre_ext_steel                = "S";
const pre_ext_deco                 = "D";
const pre_ext_hatch                = "H";
const pre_ext_goal                 = "G";
const pre_ext_trap                 = "T";
const pre_ext_fire                 = "F";
const pre_ext_water                = "W";
const pre_ext_oneway_left          = "L";
const pre_ext_oneway_right         = "R";

// keys for saving/loading the global config file
const cfg_user_name                = "USER_NAME";
const cfg_user_name_ask            = "USER_NAME_ASK";

const cfg_screen_resolution_x      = "SCREEN_RESOLUTION_X";
const cfg_screen_resolution_y      = "SCREEN_RESOLUTION_Y";
const cfg_screen_windowed_x        = "SCREEN_WINDOWED_X";
const cfg_screen_windowed_y        = "SCREEN_WINDOWED_Y";
const cfg_screen_vsync             = "SCREEN_VSYNC";
const cfg_sound_load_driver        = "SOUND_LOAD_DRIVER";

const cfg_replay_auto_max          = "REPLAY_AUTO_MAX";
const cfg_replay_auto_single       = "REPLAY_AUTO_SINGLE";
const cfg_replay_auto_multi        = "REPLAY_AUTO_MULTI";
const cfg_replay_auto_next_s       = "REPLAY_AUTO_SINGLE_NEXT";
const cfg_replay_auto_next_m       = "REPLAY_AUTO_MULTI_NEXT";

const cfg_ip_last_used             = "IP_LAST_USED";
const cfg_ip_central_server        = "IP_CENTRAL_SERVER";
const cfg_server_port              = "SERVER_PORT";

// keys for saving/loading level files
const level_built                  = "BUILT";
const level_author                 = "AUTHOR";
const level_name_german            = "GERMAN";
const level_name_english           = "ENGLISH";
const level_tutorial_german        = "TUTORIAL_GERMAN";
const level_tutorial_english       = "TUTORIAL_ENGLISH";
const level_hint_german            = "HINT_GERMAN";
const level_hint_english           = "HINT_ENGLISH";
const level_size_x                 = "SIZE_X";
const level_size_y                 = "SIZE_Y";
const level_torus_x                = "TORUS_X";
const level_torus_y                = "TORUS_Y";
const level_start_x                = "START_X";
const level_start_y                = "START_Y";
const level_bg_red                 = "BACKGROUND_RED";
const level_bg_green               = "BACKGROUND_GREEN";
const level_bg_blue                = "BACKGROUND_BLUE";
const level_seconds                = "SECONDS";
const level_initial                = "INITIAL";
const level_initial_legacy         = "LEMMINGS"; // backwards compatibility
const level_required               = "REQUIRED";
const level_spawnint_slow          = "SPAWN_INTERVAL";
const level_spawnint_fast          = "SPAWN_INTERVAL_FAST";
const level_rate                   = "RATE"; // backwards compatibility
const level_count_neutrals_only    = "COUNT_NEUTRALS_ONLY";
const level_transfer_skills        = "TRANSFER_SKILLS";

// keys for loading objdef files, customization of interactive objects
const objdef_type                  = "TYPE";
const objdef_ta_absolute_x         = "TRIGGER_AREA_POSITION_ABSOLUTE_X";
const objdef_ta_absolute_y         = "TRIGGER_AREA_POSITION_ABSOLUTE_Y";
const objdef_ta_from_center_x      = "TRIGGER_AREA_POSITION_FROM_CENTER_X";
const objdef_ta_from_center_y      = "TRIGGER_AREA_POSITION_FROM_CENTER_Y";
const objdef_ta_from_bottom_y      = "TRIGGER_AREA_POSITION_FROM_BOTTOM_Y";
const objdef_ta_xl                 = "TRIGGER_AREA_SIZE_X";
const objdef_ta_yl                 = "TRIGGER_AREA_SIZE_Y";
const objdef_hatch_opening_frame   = "HATCH_OPENING_FRAME";
const objdef_fling_nonpermanent    = "FLING_NONPERMANENT";
const objdef_fling_ignore_orient   = "FLING_IGNORE_X_ORIENTATION";
const objdef_fling_x               = "FLING_SPEED_X";
const objdef_fling_y               = "FLING_SPEED_Y";

const objdef_type_terrain          = "TERRAIN";
const objdef_type_steel            = "STEEL";
const objdef_type_deco             = "DECORATION";
const objdef_type_hatch            = "HATCH";
const objdef_type_goal             = "GOAL";
const objdef_type_trap             = "TRAP";
const objdef_type_water            = "WATER";
const objdef_type_fire             = "FIRE";
const objdef_type_oneway_left      = "ONEWAY_LEFT";
const objdef_type_oneway_right     = "ONEWAY_RIGHT";
const objdef_type_fling            = "FLING";
const objdef_type_trampoline       = "TRAMPOLINE";

// keys for saving/loading replays
const replay_version_min           = "VERSION_REQUIRED";
const replay_built_required        = "BUILT_REQUIRED";
const replay_level_filename        = "FILENAME";
const replay_friend                = "FRIEND";
const replay_player                = "PLAYER";
const replay_permu                 = "PERMUTATION";
const replay_update                = "UPDATE";
const replay_spawnint              = "SPAWNINT";
const replay_skill                 = "SKILL";
const replay_aim                   = "AIM";
const replay_nuke                  = "NUKE";
const replay_assign_any            = "ASSIGN";
const replay_assign_left           = "ASSIGN_LEFT";
const replay_assign_right          = "ASSIGN_RIGHT";

// keys for saving/loading the user (non-global) configurations file
const user_language                = "LANGUAGE";
const user_option_group            = "OPTION_GROUP";

const user_mouse_speed             = "MOUSE_SPEED";
const user_mouse_acceleration      = "MOUSE_ACCELERATION";
const user_scroll_speed_edge       = "SCROLL_SPEED_EDGE";
const user_scroll_speed_click      = "SCROLL_SPEED_CLICK";
const user_scroll_edge             = "SCROLL_EDGE";
const user_scroll_right            = "SCROLL_RIGHT";
const user_scroll_middle           = "SCROLL_MIDDLE";
const user_scroll_torus_x          = "SCROLL_TORUS_X";
const user_scroll_torus_y          = "SCROLL_TORUS_Y";
const user_replay_cancel           = "REPLAY_CANCEL";
const user_replay_cancel_at        = "REPLAY_CANCEL_AT";
const user_multiple_builders       = "MULTIPLE_BUILDERS";
const user_batter_priority         = "BATTER_PRIORITY";
const user_prioinv_middle          = "PRIORITY_INVERT_MIDDLE";
const user_prioinv_right           = "PRIORITY_INVERT_RIGHT";

const user_screen_scaling          = "SCREEN_SCALING";
const user_screen_border_colored   = "SCREEN_BORDER_COLORED";
const user_screen_windowed         = "SCREEN_WINDOWED";
const user_arrows_replay           = "ARROWS_REPLAY";
const user_arrows_network          = "ARROWS_NETWORK";
const user_gameplay_help           = "GAMEPLAY_HELP";
const user_debris_amount           = "DEBRIS_AMOUNT";
const user_debris_type             = "DEBRIS_TYPE";
const user_gui_color_red           = "GUI_COLOR_RED";
const user_gui_color_green         = "GUI_COLOR_GREEN";
const user_gui_color_blue          = "GUI_COLOR_BLUE";

const user_sound_volume            = "SOUND_VOLUME";

const user_editor_hex_level_size   = "EDITOR_HEX_LEVEL_SIZE";
const user_editor_grid_selected    = "EDITOR_GRID_SELECTED";
const user_editor_grid_custom      = "EDITOR_GRID_CUSTOM";

const user_single_last_level       = "SINGLE_LAST_LEVEL";
const user_network_last_level      = "NETWORK_LAST_LEVEL";
const user_replay_last_level       = "REPLAY_LAST_LEVEL";
const user_network_last_style      = "NETWORK_LAST_STYLE";

const user_editor_last_dir_terrain = "EDITOR_LAST_DIR_TERRAIN";
const user_editor_last_dir_steel   = "EDITOR_LAST_DIR_STEEL";
const user_editor_last_dir_goal    = "EDITOR_LAST_DIR_GOAL";
const user_editor_last_dir_hatch   = "EDITOR_LAST_DIR_HATCH";
const user_editor_last_dir_deco    = "EDITOR_LAST_DIR_DECO";
const user_editor_last_dir_hazard  = "EDITOR_LAST_DIR_HAZARD";

const user_key_force_left          = "KEY_FORCE_LEFT";
const user_key_force_right         = "KEY_FORCE_RIGHT";
const user_key_scroll              = "KEY_SCROLL";
const user_key_priority            = "KEY_PRIORITY";
const user_key_rate_minus          = "KEY_RATE_MINUS";
const user_key_rate_plus           = "KEY_RATE_PLUS";
const user_key_pause               = "KEY_PAUSE";
const user_key_speed_slow          = "KEY_SPEED_SLOW";
const user_key_speed_fast          = "KEY_SPEED_FAST";
const user_key_speed_turbo         = "KEY_SPEED_TURBO";
const user_key_restart             = "KEY_RESTART";
const user_key_state_load          = "KEY_STATE_LOAD";
const user_key_state_save          = "KEY_STATE_SAVE";
const user_key_zoom                = "KEY_ZOOM";
const user_key_nuke                = "KEY_NUKE";
const user_key_spec_tribe          = "KEY_SPECTATE_NEXT_PLAYER";
const user_key_chat                = "KEY_CHAT";
const user_key_ga_exit             = "KEY_GAME_EXIT";

const user_key_me_okay             = "KEY_MENU_OKAY";
const user_key_me_edit             = "KEY_MENU_EDIT";
const user_key_me_export           = "KEY_MENU_EXPORT";
const user_key_me_delete           = "KEY_MENU_DELETE";
const user_key_me_up_dir           = "KEY_MENU_UP_DIR";
const user_key_me_up_1             = "KEY_MENU_UP_1";
const user_key_me_up_5             = "KEY_MENU_UP_5";
const user_key_me_down_1           = "KEY_MENU_DOWN_1";
const user_key_me_down_5           = "KEY_MENU_DOWN_5";
const user_key_me_exit             = "KEY_MENU_EXIT";
const user_key_me_main_single      = "KEY_MENU_MAIN_SINGLE";
const user_key_me_main_network     = "KEY_MENU_MAIN_NETWORK";
const user_key_me_main_replay      = "KEY_MENU_MAIN_REPLAY";
const user_key_me_main_options     = "KEY_MENU_MAIN_OPTIONS";

const user_key_ed_left             = "KEY_EDITOR_LEFT";
const user_key_ed_right            = "KEY_EDITOR_RIGHT";
const user_key_ed_up               = "KEY_EDITOR_UP";
const user_key_ed_down             = "KEY_EDITOR_DOWN";
const user_key_ed_copy             = "KEY_EDITOR_COPY";
const user_key_ed_delete           = "KEY_EDITOR_DELETE";
const user_key_ed_grid             = "KEY_EDITOR_GRID";
const user_key_ed_sel_all          = "KEY_EDITOR_SELECT_ALL";
const user_key_ed_sel_frame        = "KEY_EDITOR_SELECT_FRAME";
const user_key_ed_sel_add          = "KEY_EDITOR_SELECT_ADD";
const user_key_ed_foreground       = "KEY_EDITOR_FOREGROUND";
const user_key_ed_background       = "KEY_EDITOR_BACKGROUND";
const user_key_ed_mirror           = "KEY_EDITOR_MIRROR";
const user_key_ed_rotate           = "KEY_EDITOR_ROTATE";
const user_key_ed_dark             = "KEY_EDITOR_DARK";
const user_key_ed_noow             = "KEY_EDITOR_NO_OVERWRITE";
const user_key_ed_zoom             = "KEY_EDITOR_ZOOM";
const user_key_ed_help             = "KEY_EDITOR_HELP";
const user_key_ed_menu_size        = "KEY_EDITOR_MENU_SIZE";
const user_key_ed_menu_vars        = "KEY_EDITOR_MENU_GENERAL";
const user_key_ed_menu_skills      = "KEY_EDITOR_MENU_SKILLS";
const user_key_ed_add_terrain      = "KEY_EDITOR_ADD_TERRAIN";
const user_key_ed_add_steel        = "KEY_EDITOR_ADD_STEEL";
const user_key_ed_add_hatch        = "KEY_EDITOR_ADD_HATCH";
const user_key_ed_add_goal         = "KEY_EDITOR_ADD_GOAL";
const user_key_ed_add_deco         = "KEY_EDITOR_ADD_DECO";
const user_key_ed_add_hazard       = "KEY_EDITOR_ADD_HAZARD";
const user_key_ed_exit             = "KEY_EDITOR_EXIT";



// important directories
const empty_filename               = new Filename("");
const dir_levels                   = new Filename("levels/");
const dir_levels_single            = new Filename("levels/single/");
const dir_levels_network           = new Filename("levels/network/");
const dir_replay                   = new Filename("replays/");
const dir_replay_auto              = new Filename("replays/auto/");
const dir_data                     = new Filename("data/");
const dir_data_bitmap              = new Filename("data/images/");
const dir_data_sound               = new Filename("data/sound/");
const dir_data_user                = new Filename("data/user/");
const dir_bitmap                   = new Filename("images/");
const dir_bitmap_orig              = new Filename("images/orig/");
const dir_bitmap_orig_l1           = new Filename("images/orig/L1/");
const dir_bitmap_orig_l2           = new Filename("images/orig/L2/");

// stubs for various filenames
const file_replay_auto_single      = new Filename("replays/auto/s");
const file_replay_auto_multi       = new Filename("replays/auto/m");

// important single files
const file_config                  = new Filename("data/config.txt");
const file_log                     = new Filename("data/log.txt");
const file_level_network           = new Filename("data/netlevel.txt");

const file_bitmap_api_number       = new Filename("data/bitmap/api_numb.I");
const file_bitmap_checkbox         = new Filename("data/bitmap/checkbox.I");
const file_bitmap_debris           = new Filename("data/bitmap/debris.I");
const file_bitmap_edit_flip        = new Filename("data/bitmap/edit_flp.I");
const file_bitmap_edit_hatch       = new Filename("data/bitmap/edit_hat.I");
const file_bitmap_edit_panel       = new Filename("data/bitmap/edit_pan.I");
const file_bitmap_explosion        = new Filename("data/bitmap/explode.I");
const file_bitmap_fuse_flame       = new Filename("data/bitmap/fuse_fla.I");
const file_bitmap_game_arrow       = new Filename("data/bitmap/game_arr.I");
const file_bitmap_game_icon        = new Filename("data/bitmap/game_ico.I");
const file_bitmap_game_nuke        = new Filename("data/bitmap/game_nuk.I");
const file_bitmap_game_panel       = new Filename("data/bitmap/game_pan.I");
const file_bitmap_game_panel_2     = new Filename("data/bitmap/game_pa2.I");
const file_bitmap_game_panel_hints = new Filename("data/bitmap/game_pah.I");
const file_bitmap_game_spi_fix     = new Filename("data/bitmap/game_spi.I");
const file_bitmap_game_pause       = new Filename("data/bitmap/game_pau.I");
const file_bitmap_game_replay      = new Filename("data/bitmap/game_rep.I");
const file_bitmap_lix              = new Filename("data/bitmap/lix.I");
const file_bitmap_lix_recol        = new Filename("data/bitmap/lixrecol.I");
const file_bitmap_lobby_spec       = new Filename("data/bitmap/lobby_sp.I");
const file_bitmap_menu_background  = new Filename("data/bitmap/menu_bg.I");
const file_bitmap_menu_checkmark   = new Filename("data/bitmap/menu_chk.I");
const file_bitmap_mouse            = new Filename("data/bitmap/mouse.I");
const file_bitmap_preview_icon     = new Filename("data/bitmap/prev_ico.I");

const file_bitmap_font_big         = new Filename("data/bitmap/font_big.I.tga");
const file_bitmap_font_nar         = new Filename("data/bitmap/font_nar.I.tga");
const file_bitmap_font_med         = new Filename("data/bitmap/font_med.I.tga");
const file_bitmap_font_sml         = new Filename("data/bitmap/font_sml.I.tga");
