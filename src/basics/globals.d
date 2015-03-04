module basics.globals;

import file.filename;

const gloB_name_of_the_game = "Lix";
const gloB_al_window_title  = "Lix";

const gloB_file_log = new Filename("./data/log.txt");

// oh, this is such a mess, some are mutable via global config, but most
// are constant. Consider outsourcing the mutable ones into module globconf.d.

/*
const int updates_per_second  = 60;
const int skill_max           = 12;
const int panel_gameplay_yl   = 80;
const int panel_editor_yl     = 80;
const int scroll_torus_max    =  2;

    user_name            (""),
    user_name_ask        (false),

    screen_resolution_x  ( 640),
    screen_resolution_y  ( 480),
    screen_windowed_x    ( 640),
    screen_windowed_y    ( 480),
    screen_vsync         (false),
    screen_fullscreen_now(false),

    sound_load_driver    (true),

    replay_auto_max      (40),
    replay_auto_single   ( 1),
    replay_auto_multi    ( 1),
    replay_auto_next_s   ( 0),
    replay_auto_next_m   ( 0),

    ip_last_used         ("127.0.0.1"),
    ip_central_server    ("asdfasdf.ethz.ch"),
    server_port          (globals_port_default),

    // Constant strings
    // Diverses
    empty_string                 (""),
    net_ip_localhost             ("127.0.0.1"),
    error_wrong_working_dir      ("Wrong working directory!\n"
                                  "Run the game from its root directory\n"
                                  "or from its subdirectory bin/.\n"
                                  "\n"
                                  "Falsches Arbeitsverzeichnis!\n"
                                  "Starte das Spiel aus seinem\n"
                                  "Wurzelverzeichnis oder aus bin/.\n"
                                  ),
    // Dateien laden
    ext_level                    (".txt"),
    ext_level_orig               (".lvl"),
    ext_level_lemmini            (".ini"),
    ext_replay                   (".txt"),
    ext_user                     (".txt"),
    ext_object_definitions       (".txt"),
    mask_anything                ("*.*"),
    mask_ext_replay              ("*.txt"),
    mask_ext_user                ("*.txt"),

    file_level_dir_order         ("_order.X.txt"),
    file_level_dir_english       ("_english.X.txt"),
    file_level_dir_german        ("_german.X.txt"),

    // Unterteilung der Bilddateien nach Prae-Endung
    pre_ext_null                 (":"),
    pre_ext_internal             ("I"),
    pre_ext_steel                ("S"),
    pre_ext_deco                 ("D"),
    pre_ext_hatch                ("H"),
    pre_ext_goal                 ("G"),
    pre_ext_trap                 ("T"),
    pre_ext_fire                 ("F"),
    pre_ext_water                ("W"),
    pre_ext_oneway_left          ("L"),
    pre_ext_oneway_right         ("R"),

    // Config-Schluessel
    config_user_name             ("USER_NAME"),
    config_user_name_ask         ("USER_NAME_ASK"),

    config_screen_resolution_x   ("SCREEN_RESOLUTION_X"),
    config_screen_resolution_y   ("SCREEN_RESOLUTION_Y"),
    config_screen_windowed_x     ("SCREEN_WINDOWED_X"),
    config_screen_windowed_y     ("SCREEN_WINDOWED_Y"),
    config_screen_vsync          ("SCREEN_VSYNC"),

    config_sound_load_driver     ("SOUND_LOAD_DRIVER"),

    config_replay_auto_max       ("REPLAY_AUTO_MAX"),
    config_replay_auto_single    ("REPLAY_AUTO_SINGLE"),
    config_replay_auto_multi     ("REPLAY_AUTO_MULTI"),
    config_replay_auto_next_s    ("REPLAY_AUTO_SINGLE_NEXT"),
    config_replay_auto_next_m    ("REPLAY_AUTO_MULTI_NEXT"),

    config_ip_last_used          ("IP_LAST_USED"),
    config_ip_central_server     ("IP_CENTRAL_SERVER"),
    config_server_port           ("SERVER_PORT"),

    // Leveldatei-Schluessel
    level_built                  ("BUILT"),
    level_author                 ("AUTHOR"),
    level_name_german            ("GERMAN"),
    level_name_english           ("ENGLISH"),
    level_tutorial_german        ("TUTORIAL_GERMAN"),
    level_tutorial_english       ("TUTORIAL_ENGLISH"),
    level_hint_german            ("HINT_GERMAN"),
    level_hint_english           ("HINT_ENGLISH"),
    level_size_x                 ("SIZE_X"),
    level_size_y                 ("SIZE_Y"),
    level_torus_x                ("TORUS_X"),
    level_torus_y                ("TORUS_Y"),
    level_start_x                ("START_X"),
    level_start_y                ("START_Y"),
    level_bg_red                 ("BACKGROUND_RED"),
    level_bg_green               ("BACKGROUND_GREEN"),
    level_bg_blue                ("BACKGROUND_BLUE"),
    level_seconds                ("SECONDS"),
    level_initial                ("INITIAL"),
    level_initial_legacy         ("LEMMINGS"), // backwards compatibility
    level_required               ("REQUIRED"),
    level_spawnint_slow          ("SPAWN_INTERVAL"),
    level_spawnint_fast          ("SPAWN_INTERVAL_FAST"),
    level_rate                   ("RATE"), // backwards compatibility
    level_count_neutrals_only    ("COUNT_NEUTRALS_ONLY"),
    level_transfer_skills        ("TRANSFER_SKILLS"),

    // Special level objects (hatches, exits, ...) definitions file
    objdef_type                  ("TYPE"),
    objdef_ta_absolute_x         ("TRIGGER_AREA_POSITION_ABSOLUTE_X"),
    objdef_ta_absolute_y         ("TRIGGER_AREA_POSITION_ABSOLUTE_Y"),
    objdef_ta_from_center_x      ("TRIGGER_AREA_POSITION_FROM_CENTER_X"),
    objdef_ta_from_center_y      ("TRIGGER_AREA_POSITION_FROM_CENTER_Y"),
    objdef_ta_from_bottom_y      ("TRIGGER_AREA_POSITION_FROM_BOTTOM_Y"),
    objdef_ta_xl                 ("TRIGGER_AREA_SIZE_X"),
    objdef_ta_yl                 ("TRIGGER_AREA_SIZE_Y"),
    objdef_hatch_opening_frame   ("HATCH_OPENING_FRAME"),
    objdef_fling_nonpermanent    ("FLING_NONPERMANENT"),
    objdef_fling_ignore_orient   ("FLING_IGNORE_X_ORIENTATION"),
    objdef_fling_x               ("FLING_SPEED_X"),
    objdef_fling_y               ("FLING_SPEED_Y"),

    objdef_type_terrain          ("TERRAIN"),
    objdef_type_steel            ("STEEL"),
    objdef_type_deco             ("DECORATION"),
    objdef_type_hatch            ("HATCH"),
    objdef_type_goal             ("GOAL"),
    objdef_type_trap             ("TRAP"),
    objdef_type_water            ("WATER"),
    objdef_type_fire             ("FIRE"),
    objdef_type_oneway_left      ("ONEWAY_LEFT"),
    objdef_type_oneway_right     ("ONEWAY_RIGHT"),
    objdef_type_fling            ("FLING"),
    objdef_type_trampoline       ("TRAMPOLINE"),

    // Replaydatei-Schluessel
    replay_version_min           ("VERSION_REQUIRED"),
    replay_built_required        ("BUILT_REQUIRED"),
    replay_level_filename        ("FILENAME"),
    replay_friend                ("FRIEND"),
    replay_player                ("PLAYER"),
    replay_permu                 ("PERMUTATION"),
    replay_update                ("UPDATE"),
    replay_spawnint              ("SPAWNINT"),
    replay_skill                 ("SKILL"),
    replay_aim                   ("AIM"),
    replay_nuke                  ("NUKE"),
    replay_assign_any            ("ASSIGN"),
    replay_assign_left           ("ASSIGN_LEFT"),
    replay_assign_right          ("ASSIGN_RIGHT"),

    // Userdatei-Schluessel
    user_language                ("LANGUAGE"),
    user_option_group            ("OPTION_GROUP"),

    user_mouse_speed             ("MOUSE_SPEED"),
    user_mouse_acceleration      ("MOUSE_ACCELERATION"),
    user_scroll_speed_edge       ("SCROLL_SPEED_EDGE"),
    user_scroll_speed_click      ("SCROLL_SPEED_CLICK"),
    user_scroll_edge             ("SCROLL_EDGE"),
    user_scroll_right            ("SCROLL_RIGHT"),
    user_scroll_middle           ("SCROLL_MIDDLE"),
    user_scroll_torus_x          ("SCROLL_TORUS_X"),
    user_scroll_torus_y          ("SCROLL_TORUS_Y"),
    user_replay_cancel           ("REPLAY_CANCEL"),
    user_replay_cancel_at        ("REPLAY_CANCEL_AT"),
    user_multiple_builders       ("MULTIPLE_BUILDERS"),
    user_batter_priority         ("BATTER_PRIORITY"),
    user_prioinv_middle          ("PRIORITY_INVERT_MIDDLE"),
    user_prioinv_right           ("PRIORITY_INVERT_RIGHT"),

    user_screen_scaling          ("SCREEN_SCALING"),
    user_screen_border_colored   ("SCREEN_BORDER_COLORED"),
    user_screen_windowed         ("SCREEN_WINDOWED"),
    user_arrows_replay           ("ARROWS_REPLAY"),
    user_arrows_network          ("ARROWS_NETWORK"),
    user_gameplay_help           ("GAMEPLAY_HELP"),
    user_debris_amount           ("DEBRIS_AMOUNT"),
    user_debris_type             ("DEBRIS_TYPE"),
    user_gui_color_red           ("GUI_COLOR_RED"),
    user_gui_color_green         ("GUI_COLOR_GREEN"),
    user_gui_color_blue          ("GUI_COLOR_BLUE"),

    user_sound_volume            ("SOUND_VOLUME"),

    user_editor_hex_level_size   ("EDITOR_HEX_LEVEL_SIZE"),
    user_editor_grid_selected    ("EDITOR_GRID_SELECTED"),
    user_editor_grid_custom      ("EDITOR_GRID_CUSTOM"),

    user_single_last_level       ("SINGLE_LAST_LEVEL"),
    user_network_last_level      ("NETWORK_LAST_LEVEL"),
    user_replay_last_level       ("REPLAY_LAST_LEVEL"),
    user_network_last_style      ("NETWORK_LAST_STYLE"),

    user_editor_last_dir_terrain ("EDITOR_LAST_DIR_TERRAIN"),
    user_editor_last_dir_steel   ("EDITOR_LAST_DIR_STEEL"),
    user_editor_last_dir_goal    ("EDITOR_LAST_DIR_GOAL"),
    user_editor_last_dir_hatch   ("EDITOR_LAST_DIR_HATCH"),
    user_editor_last_dir_deco    ("EDITOR_LAST_DIR_DECO"),
    user_editor_last_dir_hazard  ("EDITOR_LAST_DIR_HAZARD"),

    user_key_force_left          ("KEY_FORCE_LEFT"),
    user_key_force_right         ("KEY_FORCE_RIGHT"),
    user_key_scroll              ("KEY_SCROLL"),
    user_key_priority            ("KEY_PRIORITY"),
    user_key_rate_minus          ("KEY_RATE_MINUS"),
    user_key_rate_plus           ("KEY_RATE_PLUS"),
    user_key_pause               ("KEY_PAUSE"),
    user_key_speed_slow          ("KEY_SPEED_SLOW"),
    user_key_speed_fast          ("KEY_SPEED_FAST"),
    user_key_speed_turbo         ("KEY_SPEED_TURBO"),
    user_key_restart             ("KEY_RESTART"),
    user_key_state_load          ("KEY_STATE_LOAD"),
    user_key_state_save          ("KEY_STATE_SAVE"),
    user_key_zoom                ("KEY_ZOOM"),
    user_key_nuke                ("KEY_NUKE"),
    user_key_spec_tribe          ("KEY_SPECTATE_NEXT_PLAYER"),
    user_key_chat                ("KEY_CHAT"),
    user_key_ga_exit             ("KEY_GAME_EXIT"),

    user_key_me_okay             ("KEY_MENU_OKAY"),
    user_key_me_edit             ("KEY_MENU_EDIT"),
    user_key_me_export           ("KEY_MENU_EXPORT"),
    user_key_me_delete           ("KEY_MENU_DELETE"),
    user_key_me_up_dir           ("KEY_MENU_UP_DIR"),
    user_key_me_up_1             ("KEY_MENU_UP_1"),
    user_key_me_up_5             ("KEY_MENU_UP_5"),
    user_key_me_down_1           ("KEY_MENU_DOWN_1"),
    user_key_me_down_5           ("KEY_MENU_DOWN_5"),
    user_key_me_exit             ("KEY_MENU_EXIT"),
    user_key_me_main_single      ("KEY_MENU_MAIN_SINGLE"),
    user_key_me_main_network     ("KEY_MENU_MAIN_NETWORK"),
    user_key_me_main_replay      ("KEY_MENU_MAIN_REPLAY"),
    user_key_me_main_options     ("KEY_MENU_MAIN_OPTIONS"),

    user_key_ed_left             ("KEY_EDITOR_LEFT"),
    user_key_ed_right            ("KEY_EDITOR_RIGHT"),
    user_key_ed_up               ("KEY_EDITOR_UP"),
    user_key_ed_down             ("KEY_EDITOR_DOWN"),
    user_key_ed_copy             ("KEY_EDITOR_COPY"),
    user_key_ed_delete           ("KEY_EDITOR_DELETE"),
    user_key_ed_grid             ("KEY_EDITOR_GRID"),
    user_key_ed_sel_all          ("KEY_EDITOR_SELECT_ALL"),
    user_key_ed_sel_frame        ("KEY_EDITOR_SELECT_FRAME"),
    user_key_ed_sel_add          ("KEY_EDITOR_SELECT_ADD"),
    user_key_ed_foreground       ("KEY_EDITOR_FOREGROUND"),
    user_key_ed_background       ("KEY_EDITOR_BACKGROUND"),
    user_key_ed_mirror           ("KEY_EDITOR_MIRROR"),
    user_key_ed_rotate           ("KEY_EDITOR_ROTATE"),
    user_key_ed_dark             ("KEY_EDITOR_DARK"),
    user_key_ed_noow             ("KEY_EDITOR_NO_OVERWRITE"),
    user_key_ed_zoom             ("KEY_EDITOR_ZOOM"),
    user_key_ed_help             ("KEY_EDITOR_HELP"),
    user_key_ed_menu_size        ("KEY_EDITOR_MENU_SIZE"),
    user_key_ed_menu_vars        ("KEY_EDITOR_MENU_GENERAL"),
    user_key_ed_menu_skills      ("KEY_EDITOR_MENU_SKILLS"),
    user_key_ed_add_terrain      ("KEY_EDITOR_ADD_TERRAIN"),
    user_key_ed_add_steel        ("KEY_EDITOR_ADD_STEEL"),
    user_key_ed_add_hatch        ("KEY_EDITOR_ADD_HATCH"),
    user_key_ed_add_goal         ("KEY_EDITOR_ADD_GOAL"),
    user_key_ed_add_deco         ("KEY_EDITOR_ADD_DECO"),
    user_key_ed_add_hazard       ("KEY_EDITOR_ADD_HAZARD"),
    user_key_ed_exit             ("KEY_EDITOR_EXIT"),



    // Wichtige Verzeichnisse
    empty_filename               (""),
    dir_levels                   ("levels/"),
    dir_levels_single            (dir_levels.get_dir_rootless()),
    dir_levels_network           (dir_levels.get_dir_rootless() + "network/"),
    dir_replay                   ("replays/"),
    dir_replay_auto              (dir_replay.get_dir_rootless() + "auto/"),
    dir_data                     ("data/"),
    dir_data_bitmap              (dir_data.get_dir_rootless() + "images/"),
    dir_data_sound               (dir_data.get_dir_rootless() + "sound/"),
    dir_data_user                (dir_data.get_dir_rootless() + "user/"),
    dir_bitmap                   ("images/"),
    dir_bitmap_orig              (dir_bitmap.get_dir_rootless() + "orig/"),
    dir_bitmap_orig_l1           (dir_bitmap.get_dir_rootless() + "orig/L1/"),
    dir_bitmap_orig_l2           (dir_bitmap.get_dir_rootless() + "orig/L2/"),

    // Wichtige Dateien
    file_config                  (dir_data.get_dir_rootless() + "config.txt"),
    file_log                     (dir_data.get_dir_rootless() + "log.txt"),
    file_level_network           (dir_data.get_dir_rootless() + "netlevel.txt"),

    file_bitmap_api_number       (dir_data_bitmap.get_dir_rootless() + "api_numb.I"),
    file_bitmap_checkbox         (dir_data_bitmap.get_dir_rootless() + "checkbox.I"),
    file_bitmap_debris           (dir_data_bitmap.get_dir_rootless() + "debris.I"),
    file_bitmap_edit_flip        (dir_data_bitmap.get_dir_rootless() + "edit_flp.I"),
    file_bitmap_edit_hatch       (dir_data_bitmap.get_dir_rootless() + "edit_hat.I"),
    file_bitmap_edit_panel       (dir_data_bitmap.get_dir_rootless() + "edit_pan.I"),
    file_bitmap_explosion        (dir_data_bitmap.get_dir_rootless() + "explode.I"),
    file_bitmap_fuse_flame       (dir_data_bitmap.get_dir_rootless() + "fuse_fla.I"),
    file_bitmap_game_arrow       (dir_data_bitmap.get_dir_rootless() + "game_arr.I"),
    file_bitmap_game_icon        (dir_data_bitmap.get_dir_rootless() + "game_ico.I"),
    file_bitmap_game_nuke        (dir_data_bitmap.get_dir_rootless() + "game_nuk.I"),
    file_bitmap_game_panel       (dir_data_bitmap.get_dir_rootless() + "game_pan.I"),
    file_bitmap_game_panel_2     (dir_data_bitmap.get_dir_rootless() + "game_pa2.I"),
    file_bitmap_game_panel_hints (dir_data_bitmap.get_dir_rootless() + "game_pah.I"),
    file_bitmap_game_spi_fix     (dir_data_bitmap.get_dir_rootless() + "game_spi.I"),
    file_bitmap_game_pause       (dir_data_bitmap.get_dir_rootless() + "game_pau.I"),
    file_bitmap_game_replay      (dir_data_bitmap.get_dir_rootless() + "game_rep.I"),
    file_bitmap_lix              (dir_data_bitmap.get_dir_rootless() + "lix.I"),
    file_bitmap_lix_recol        (dir_data_bitmap.get_dir_rootless() + "lixrecol.I"),
    file_bitmap_lobby_spec       (dir_data_bitmap.get_dir_rootless() + "lobby_sp.I"),
    file_bitmap_menu_background  (dir_data_bitmap.get_dir_rootless() + "menu_bg.I"),
    file_bitmap_menu_checkmark   (dir_data_bitmap.get_dir_rootless() + "menu_chk.I"),
    file_bitmap_mouse            (dir_data_bitmap.get_dir_rootless() + "mouse.I"),
    file_bitmap_preview_icon     (dir_data_bitmap.get_dir_rootless() + "prev_ico.I"),

    file_bitmap_font_big         (dir_data_bitmap.get_dir_rootless() + "font_big.I.tga"),
    file_bitmap_font_nar         (dir_data_bitmap.get_dir_rootless() + "font_nar.I.tga"),
    file_bitmap_font_med         (dir_data_bitmap.get_dir_rootless() + "font_med.I.tga"),
    file_bitmap_font_sml         (dir_data_bitmap.get_dir_rootless() + "font_sml.I.tga"),

    file_replay_auto_single      (dir_replay_auto.get_dir_rootless() + "s"),
    file_replay_auto_multi       (dir_replay_auto.get_dir_rootless() + "m")
*/
