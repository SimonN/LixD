module basics.globals;

import file.filename;

// globals.d contains all the compile-time _constants_ accessible from
// throughout the game. Global variables that may change are in globconf.d,
// those are the variables saved into the global config file.

// Untranslated strings; for translations of other strings see file.language
const main_name_of_game = "Lix";
const main_website      = "asdfasdf.ethz.ch/~simon";

const int ticks_per_sec     = 60;
const int skill_max         = 12;
const int panel_gameplay_yl = 80;
const int panel_editor_yl   = 80;

const int player_name_max_length   = 30;

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
const ext_config                   = ".txt";
const ext_object_definitions       = ".txt";
deprecated const mask_anything     = "";
deprecated const mask_ext_replay   = ext_replay;
deprecated const mask_ext_user     = ".txt";

const file_level_dir_order         = "_order.X.txt";
const file_level_dir_english       = "_english.X.txt";
const file_level_dir_german        = "_german.X.txt";
const file_level_dir_userlang      = "_userlang.X.txt";

// pre-extensions of image files
const pre_ext_internal             = 'I';
const pre_ext_steel                = 'S';
const pre_ext_deco                 = 'D';
const pre_ext_hatch                = 'H';
const pre_ext_goal                 = 'G';
const pre_ext_trap                 = 'T';
const pre_ext_fire                 = 'F';
const pre_ext_water                = 'W';
const pre_ext_oneway_left          = 'L';
const pre_ext_oneway_right         = 'R';

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
const level_tuto_german            = "TUTORIAL_GERMAN";
const level_tuto_english           = "TUTORIAL_ENGLISH";
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
const user_replay_cancel           = "REPLAY_CANCEL";
const user_replay_cancel_at        = "REPLAY_CANCEL_AT";
const user_multiple_builders       = "MULTIPLE_BUILDERS";
const user_batter_priority         = "BATTER_PRIORITY";
const user_prioinv_middle          = "PRIORITY_INVERT_MIDDLE";
const user_prioinv_right           = "PRIORITY_INVERT_RIGHT";

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
private alias const(Filename) cF;

cF empty_filename               = new cF("");
cF dir_levels                   = new cF("levels/");
cF dir_levels_single            = new cF("levels/single/");
cF dir_levels_network           = new cF("levels/network/");
cF dir_replays                  = new cF("replays/");
cF dir_replays_auto             = new cF("replays/auto/");
cF dir_data                     = new cF("data/");
cF dir_data_bitmap              = new cF("data/images/");
cF dir_data_bitmap_scale        = new cF("data/images/scale"); // stub, no /
cF dir_data_sound               = new cF("data/sound/");
cF dir_data_user                = new cF("data/user/");
cF dir_data_transl              = new cF("data/transl/");
cF dir_bitmap                   = new cF("images/");
cF dir_bitmap_orig              = new cF("images/orig/");
cF dir_bitmap_orig_l1           = new cF("images/orig/L1/");
cF dir_bitmap_orig_l2           = new cF("images/orig/L2/");

// stubs for various filenames
cF file_replay_auto_single      = new cF("replays/auto/s");
cF file_replay_auto_multi       = new cF("replays/auto/m");

// important single files
cF file_config                  = new cF("data/config.txt");
cF file_log                     = new cF("data/log.txt");
cF file_tharsis_prof            = new cF("data/profile.txt");
cF file_language_english        = new cF("data/transl/english.txt");

cF file_bitmap_api_number       = new cF("data/images/api_numb.I");
cF file_bitmap_debris           = new cF("data/images/debris.I");
cF file_bitmap_edit_flip        = new cF("data/images/edit_flp.I");
cF file_bitmap_edit_hatch       = new cF("data/images/edit_hat.I");
cF file_bitmap_edit_panel       = new cF("data/images/edit_pan.I");
cF file_bitmap_explosion        = new cF("data/images/explode.I");
cF file_bitmap_fuse_flame       = new cF("data/images/fuse_fla.I");
cF file_bitmap_game_arrow       = new cF("data/images/game_arr.I");
cF file_bitmap_game_icon        = new cF("data/images/game_ico.I");
cF file_bitmap_game_nuke        = new cF("data/images/game_nuk.I");
cF file_bitmap_game_panel       = new cF("data/images/game_pan.I");
cF file_bitmap_game_panel_2     = new cF("data/images/game_pa2.I");
cF file_bitmap_game_panel_hints = new cF("data/images/game_pah.I");
cF file_bitmap_game_spi_fix     = new cF("data/images/game_spi.I");
cF file_bitmap_game_pause       = new cF("data/images/game_pau.I");
cF file_bitmap_game_replay      = new cF("data/images/game_rep.I");
cF file_bitmap_lix              = new cF("data/images/lix.I");
cF file_bitmap_lix_recol        = new cF("data/images/lixrecol.I");
cF file_bitmap_lobby_spec       = new cF("data/images/lobby_sp.I");
cF file_bitmap_menu_background  = new cF("data/images/menu_bg.I");
cF file_bitmap_menu_checkmark   = new cF("data/images/menu_chk.I");
cF file_bitmap_mouse            = new cF("data/images/mouse.I");
cF file_bitmap_preview_icon     = new cF("data/images/prev_ico.I");
