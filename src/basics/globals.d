module basics.globals;

import file.filename;

// globals.d contains all the compile-time _constants_ accessible from
// throughout the game. Global variables that may change are in globconf.d,
// those are the variables saved into the global config file.

// Untranslated strings; for translations of other strings see file.language
immutable main_name_of_game = "Lix";
immutable main_website      = "asdfasdf.ethz.ch/~simon";

immutable int ticks_per_sec     = 60;
immutable int skill_max         = 12;
immutable int panel_gameplay_yl = 80;
immutable int panel_editor_yl   = 80;

immutable int player_name_max_length = 30;

immutable net_ip_localhost         = "127.0.0.1";
immutable error_wrong_working_dir  = "Wrong working directory!\n"
                                     "Run the game from its root directory\n"
                                     "or from its subdirectory bin/.\n"
                                     "\n"
                                     "Falsches Arbeitsverzeichnis!\n"
                                     "Starte das Spiel aus seinem\n"
                                     "Wurzelverzeichnis oder aus bin/.\n";
// loading files
immutable ext_level                    = ".txt";
immutable ext_level_orig               = ".lvl";
immutable ext_level_lemmini            = ".ini";
immutable ext_replay                   = ".txt";
immutable ext_config                   = ".txt";
immutable ext_object_definitions       = ".txt";
deprecated immutable mask_anything     = "";
deprecated immutable mask_ext_replay   = ext_replay;
deprecated immutable mask_ext_user     = ".txt";

immutable file_level_dir_order         = "_order.X.txt";
immutable file_level_dir_english       = "_english.X.txt";
immutable file_level_dir_german        = "_german.X.txt";
immutable file_level_dir_userlang      = "_userlang.X.txt";

// pre-extensions of image files
immutable pre_ext_internal             = 'I';
immutable pre_ext_steel                = 'S';
immutable pre_ext_deco                 = 'D';
immutable pre_ext_hatch                = 'H';
immutable pre_ext_goal                 = 'G';
immutable pre_ext_trap                 = 'T';
immutable pre_ext_fire                 = 'F';
immutable pre_ext_water                = 'W';
immutable pre_ext_oneway_left          = 'L';
immutable pre_ext_oneway_right         = 'R';

// keys for saving/loading the global config file
immutable cfg_user_name                = "USER_NAME";
immutable cfg_user_name_ask            = "USER_NAME_ASK";

immutable cfg_screen_resolution_x      = "SCREEN_RESOLUTION_X";
immutable cfg_screen_resolution_y      = "SCREEN_RESOLUTION_Y";
immutable cfg_screen_windowed_x        = "SCREEN_WINDOWED_X";
immutable cfg_screen_windowed_y        = "SCREEN_WINDOWED_Y";
immutable cfg_screen_vsync             = "SCREEN_VSYNC";
immutable cfg_sound_load_driver        = "SOUND_LOAD_DRIVER";

immutable cfg_replay_auto_max          = "REPLAY_AUTO_MAX";
immutable cfg_replay_auto_single       = "REPLAY_AUTO_SINGLE";
immutable cfg_replay_auto_multi        = "REPLAY_AUTO_MULTI";
immutable cfg_replay_auto_next_s       = "REPLAY_AUTO_SINGLE_NEXT";
immutable cfg_replay_auto_next_m       = "REPLAY_AUTO_MULTI_NEXT";

immutable cfg_ip_last_used             = "IP_LAST_USED";
immutable cfg_ip_central_server        = "IP_CENTRAL_SERVER";
immutable cfg_server_port              = "SERVER_PORT";

// keys for saving/loading level files
immutable level_built                  = "BUILT";
immutable level_author                 = "AUTHOR";
immutable level_name_german            = "GERMAN";
immutable level_name_english           = "ENGLISH";
immutable level_tuto_german            = "TUTORIAL_GERMAN";
immutable level_tuto_english           = "TUTORIAL_ENGLISH";
immutable level_hint_german            = "HINT_GERMAN";
immutable level_hint_english           = "HINT_ENGLISH";
immutable level_size_x                 = "SIZE_X";
immutable level_size_y                 = "SIZE_Y";
immutable level_torus_x                = "TORUS_X";
immutable level_torus_y                = "TORUS_Y";
immutable level_start_x                = "START_X";
immutable level_start_y                = "START_Y";
immutable level_bg_red                 = "BACKGROUND_RED";
immutable level_bg_green               = "BACKGROUND_GREEN";
immutable level_bg_blue                = "BACKGROUND_BLUE";
immutable level_seconds                = "SECONDS";
immutable level_initial                = "INITIAL";
immutable level_initial_legacy         = "LEMMINGS"; // backwards compatibility
immutable level_required               = "REQUIRED";
immutable level_spawnint_slow          = "SPAWN_INTERVAL";
immutable level_spawnint_fast          = "SPAWN_INTERVAL_FAST";
immutable level_rate                   = "RATE"; // backwards compatibility
immutable level_count_neutrals_only    = "COUNT_NEUTRALS_ONLY";
immutable level_transfer_skills        = "TRANSFER_SKILLS";

// keys for loading objdef files, customization of interactive objects
immutable objdef_type                  = "TYPE";
immutable objdef_ta_absolute_x         = "TRIGGER_AREA_POSITION_ABSOLUTE_X";
immutable objdef_ta_absolute_y         = "TRIGGER_AREA_POSITION_ABSOLUTE_Y";
immutable objdef_ta_from_center_x      = "TRIGGER_AREA_POSITION_FROM_CENTER_X";
immutable objdef_ta_from_center_y      = "TRIGGER_AREA_POSITION_FROM_CENTER_Y";
immutable objdef_ta_from_bottom_y      = "TRIGGER_AREA_POSITION_FROM_BOTTOM_Y";
immutable objdef_ta_xl                 = "TRIGGER_AREA_SIZE_X";
immutable objdef_ta_yl                 = "TRIGGER_AREA_SIZE_Y";
immutable objdef_hatch_opening_frame   = "HATCH_OPENING_FRAME";
immutable objdef_fling_nonpermanent    = "FLING_NONPERMANENT";
immutable objdef_fling_ignore_orient   = "FLING_IGNORE_X_ORIENTATION";
immutable objdef_fling_x               = "FLING_SPEED_X";
immutable objdef_fling_y               = "FLING_SPEED_Y";

immutable objdef_type_terrain          = "TERRAIN";
immutable objdef_type_steel            = "STEEL";
immutable objdef_type_deco             = "DECORATION";
immutable objdef_type_hatch            = "HATCH";
immutable objdef_type_goal             = "GOAL";
immutable objdef_type_trap             = "TRAP";
immutable objdef_type_water            = "WATER";
immutable objdef_type_fire             = "FIRE";
immutable objdef_type_oneway_left      = "ONEWAY_LEFT";
immutable objdef_type_oneway_right     = "ONEWAY_RIGHT";
immutable objdef_type_fling            = "FLING";
immutable objdef_type_trampoline       = "TRAMPOLINE";

// keys for saving/loading replays
immutable replay_version_min           = "GAME_VERSION_REQUIRED";
immutable replay_built_required        = "BUILT_REQUIRED";
immutable replay_level_filename        = "FILENAME";
immutable replay_friend                = "FRIEND";
immutable replay_player                = "PLAYER";
immutable replay_permu                 = "PERMUTATION";
immutable replay_update                = "UPDATE";
immutable replay_spawnint              = "SPAWNINT";
immutable replay_skill                 = "SKILL";
immutable replay_aim                   = "AIM";
immutable replay_nuke                  = "NUKE";
immutable replay_assign_any            = "ASSIGN";
immutable replay_assign_left           = "ASSIGN_LEFT";
immutable replay_assign_right          = "ASSIGN_RIGHT";

// keys for saving/loading the user (non-global) configurations file
immutable user_language                = "LANGUAGE";
immutable user_option_group            = "OPTION_GROUP";

immutable user_mouse_speed             = "MOUSE_SPEED";
immutable user_mouse_acceleration      = "MOUSE_ACCELERATION";
immutable user_scroll_speed_edge       = "SCROLL_SPEED_EDGE";
immutable user_scroll_speed_click      = "SCROLL_SPEED_CLICK";
immutable user_scroll_edge             = "SCROLL_EDGE";
immutable user_scroll_right            = "SCROLL_RIGHT";
immutable user_scroll_middle           = "SCROLL_MIDDLE";
immutable user_replay_cancel           = "REPLAY_CANCEL";
immutable user_replay_cancel_at        = "REPLAY_CANCEL_AT";
immutable user_multiple_builders       = "MULTIPLE_BUILDERS";
immutable user_batter_priority         = "BATTER_PRIORITY";
immutable user_prioinv_middle          = "PRIORITY_INVERT_MIDDLE";
immutable user_prioinv_right           = "PRIORITY_INVERT_RIGHT";

immutable user_screen_windowed         = "SCREEN_WINDOWED";
immutable user_arrows_replay           = "ARROWS_REPLAY";
immutable user_arrows_network          = "ARROWS_NETWORK";
immutable user_gameplay_help           = "GAMEPLAY_HELP";
immutable user_debris_amount           = "DEBRIS_AMOUNT";
immutable user_debris_type             = "DEBRIS_TYPE";
immutable user_gui_color_red           = "GUI_COLOR_RED";
immutable user_gui_color_green         = "GUI_COLOR_GREEN";
immutable user_gui_color_blue          = "GUI_COLOR_BLUE";

immutable user_sound_volume            = "SOUND_VOLUME";

immutable user_editor_hex_level_size   = "EDITOR_HEX_LEVEL_SIZE";
immutable user_editor_grid_selected    = "EDITOR_GRID_SELECTED";
immutable user_editor_grid_custom      = "EDITOR_GRID_CUSTOM";

immutable user_single_last_level       = "SINGLE_LAST_LEVEL";
immutable user_network_last_level      = "NETWORK_LAST_LEVEL";
immutable user_replay_last_level       = "REPLAY_LAST_LEVEL";
immutable user_network_last_style      = "NETWORK_LAST_STYLE";

immutable user_editor_last_dir_terrain = "EDITOR_LAST_DIR_TERRAIN";
immutable user_editor_last_dir_steel   = "EDITOR_LAST_DIR_STEEL";
immutable user_editor_last_dir_goal    = "EDITOR_LAST_DIR_GOAL";
immutable user_editor_last_dir_hatch   = "EDITOR_LAST_DIR_HATCH";
immutable user_editor_last_dir_deco    = "EDITOR_LAST_DIR_DECO";
immutable user_editor_last_dir_hazard  = "EDITOR_LAST_DIR_HAZARD";

immutable user_key_force_left          = "KEY_FORCE_LEFT";
immutable user_key_force_right         = "KEY_FORCE_RIGHT";
immutable user_key_scroll              = "KEY_SCROLL";
immutable user_key_priority            = "KEY_PRIORITY";
immutable user_key_rate_minus          = "KEY_RATE_MINUS";
immutable user_key_rate_plus           = "KEY_RATE_PLUS";
immutable user_key_pause               = "KEY_PAUSE";
immutable user_key_speed_slow          = "KEY_SPEED_SLOW";
immutable user_key_speed_fast          = "KEY_SPEED_FAST";
immutable user_key_speed_turbo         = "KEY_SPEED_TURBO";
immutable user_key_restart             = "KEY_RESTART";
immutable user_key_state_load          = "KEY_STATE_LOAD";
immutable user_key_state_save          = "KEY_STATE_SAVE";
immutable user_key_zoom                = "KEY_ZOOM";
immutable user_key_nuke                = "KEY_NUKE";
immutable user_key_spec_tribe          = "KEY_SPECTATE_NEXT_PLAYER";
immutable user_key_chat                = "KEY_CHAT";
immutable user_key_ga_exit             = "KEY_GAME_EXIT";

immutable user_key_me_okay             = "KEY_MENU_OKAY";
immutable user_key_me_edit             = "KEY_MENU_EDIT";
immutable user_key_me_export           = "KEY_MENU_EXPORT";
immutable user_key_me_delete           = "KEY_MENU_DELETE";
immutable user_key_me_up_dir           = "KEY_MENU_UP_DIR";
immutable user_key_me_up_1             = "KEY_MENU_UP_1";
immutable user_key_me_up_5             = "KEY_MENU_UP_5";
immutable user_key_me_down_1           = "KEY_MENU_DOWN_1";
immutable user_key_me_down_5           = "KEY_MENU_DOWN_5";
immutable user_key_me_exit             = "KEY_MENU_EXIT";
immutable user_key_me_main_single      = "KEY_MENU_MAIN_SINGLE";
immutable user_key_me_main_network     = "KEY_MENU_MAIN_NETWORK";
immutable user_key_me_main_replays     = "KEY_MENU_MAIN_REPLAY";
immutable user_key_me_main_options     = "KEY_MENU_MAIN_OPTIONS";

immutable user_key_ed_left             = "KEY_EDITOR_LEFT";
immutable user_key_ed_right            = "KEY_EDITOR_RIGHT";
immutable user_key_ed_up               = "KEY_EDITOR_UP";
immutable user_key_ed_down             = "KEY_EDITOR_DOWN";
immutable user_key_ed_copy             = "KEY_EDITOR_COPY";
immutable user_key_ed_delete           = "KEY_EDITOR_DELETE";
immutable user_key_ed_grid             = "KEY_EDITOR_GRID";
immutable user_key_ed_sel_all          = "KEY_EDITOR_SELECT_ALL";
immutable user_key_ed_sel_frame        = "KEY_EDITOR_SELECT_FRAME";
immutable user_key_ed_sel_add          = "KEY_EDITOR_SELECT_ADD";
immutable user_key_ed_foreground       = "KEY_EDITOR_FOREGROUND";
immutable user_key_ed_background       = "KEY_EDITOR_BACKGROUND";
immutable user_key_ed_mirror           = "KEY_EDITOR_MIRROR";
immutable user_key_ed_rotate           = "KEY_EDITOR_ROTATE";
immutable user_key_ed_dark             = "KEY_EDITOR_DARK";
immutable user_key_ed_noow             = "KEY_EDITOR_NO_OVERWRITE";
immutable user_key_ed_zoom             = "KEY_EDITOR_ZOOM";
immutable user_key_ed_help             = "KEY_EDITOR_HELP";
immutable user_key_ed_menu_size        = "KEY_EDITOR_MENU_SIZE";
immutable user_key_ed_menu_vars        = "KEY_EDITOR_MENU_GENERAL";
immutable user_key_ed_menu_skills      = "KEY_EDITOR_MENU_SKILLS";
immutable user_key_ed_add_terrain      = "KEY_EDITOR_ADD_TERRAIN";
immutable user_key_ed_add_steel        = "KEY_EDITOR_ADD_STEEL";
immutable user_key_ed_add_hatch        = "KEY_EDITOR_ADD_HATCH";
immutable user_key_ed_add_goal         = "KEY_EDITOR_ADD_GOAL";
immutable user_key_ed_add_deco         = "KEY_EDITOR_ADD_DECO";
immutable user_key_ed_add_hazard       = "KEY_EDITOR_ADD_HAZARD";
immutable user_key_ed_exit             = "KEY_EDITOR_EXIT";



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
