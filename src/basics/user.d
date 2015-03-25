module basics.user;

import file.language;

Language language     = Language.NONE;
int      option_group = 0;

bool scroll_edge        = true;
bool scroll_right       = true;
bool scroll_middle      = true;
bool replay_cancel      = true;
int  replay_cancel_at   = 30;
int  mouse_speed        = 20;
int  mouse_acceleration = 0;
int  scroll_speed_edge  = 5;
int  scroll_speed_click = 6;
bool multiple_builders  = true;
bool batter_priority    = true;
bool prioinv_middle     = true;
bool prioinv_right      = true;

int  sound_volume       = 10;

bool screen_windowed    = false;
bool arrows_replay      = true;
bool arrows_network     = true;
bool gameplay_help      = true;
int  debris_amount      = 2;
int  debris_type        = 1;

int  gui_color_red      = 0x70;
int  gui_color_green    = 0x80;
int  gui_color_blue     = 0xA0;

bool editor_hex_level_size = false;
int  editor_grid_selected  = 1;
int  editor_grid_custom    = 8;
