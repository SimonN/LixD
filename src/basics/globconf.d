module basics.globconf;

/* global variables that may change during program run, and are saved
 * to the global config file. The global config file is different from the
 * user config file, it pertains to all users.
 *
 *  void load();
 *  void save();
 *
 *      Load/save the config from/to the global config file.
 */


import std.file;

import basics.globals;
import file.io;
import file.log;

string user_name             = "";
bool   user_name_ask         = false;

int    screen_resolution_x   =   0;
int    screen_resolution_y   =   0;
int    screen_windowed_x     = 640;
int    screen_windowed_y     = 480;
bool   screen_vsync          = false;

bool   sound_load_driver     = true;

int    replay_auto_max       = 60;
int    replay_auto_single    =  1;
int    replay_auto_multi     =  1;
int    replay_auto_next_s    =  0;
int    replay_auto_next_m    =  0;

string ip_last_used          = "127.0.0.1";
string ip_central_server     = "asdfasdf.ethz.ch";
int    server_port           = 22934;

// verify_mode: noninteractive replay verifier is running. This is an extra
// variable that is not saved into config file. If this is set, we can save
// time during program startup.
bool   verify_mode           = false;



void load()
{
    IoLine[] lines;
    bool err = fill_vector_from_file(lines, basics.globals.file_config);
    if (! err) {
        Log.log("Config file not found. Standard configuration will be used.");
        Log.log("This is normal when you run Lix for the first time.");
        // DTODOLANG
    }

    foreach (i; lines) {

    if      (i.text1 == cfg_user_name          ) user_name           = i.text2;
    else if (i.text1 == cfg_user_name_ask      ) user_name_ask       = i.nr1>0;

    else if (i.text1 == cfg_ip_last_used       ) ip_last_used        = i.text2;
    else if (i.text1 == cfg_ip_central_server  ) ip_central_server   = i.text2;

    else if (i.text1 == cfg_replay_auto_max    ) replay_auto_max     = i.nr1;
    else if (i.text1 == cfg_replay_auto_single ) replay_auto_single  = i.nr1;
    else if (i.text1 == cfg_replay_auto_multi  ) replay_auto_multi   = i.nr1;
    else if (i.text1 == cfg_replay_auto_next_s ) replay_auto_next_s  = i.nr1;
    else if (i.text1 == cfg_replay_auto_next_m ) replay_auto_next_m  = i.nr1;

    else if (i.text1 == cfg_screen_resolution_x) screen_resolution_x = i.nr1;
    else if (i.text1 == cfg_screen_resolution_y) screen_resolution_y = i.nr1;
    else if (i.text1 == cfg_screen_windowed_x  ) screen_windowed_x   = i.nr1;
    else if (i.text1 == cfg_screen_windowed_y  ) screen_windowed_y   = i.nr1;
    else if (i.text1 == cfg_screen_vsync       ) screen_vsync        = i.nr1>0;

    else if (i.text1 == cfg_sound_load_driver  ) sound_load_driver   = i.nr1>0;
    else if (i.text1 == cfg_server_port        ) server_port         = i.nr1;
    }
    // end foreach
}
// end function load()



void save()
{
    std.stdio.File f;

    try f = std.stdio.File(file_config.rootful, "w");
    catch (Exception e) {
        Log.log(e.msg);
        return;
    }

    f.writeln(IoLine.Dollar(cfg_user_name,               user_name));
    f.writeln(IoLine.Hash  (cfg_user_name_ask,           user_name_ask));
    f.writeln("");

    f.writeln(IoLine.Dollar(cfg_ip_last_used,            ip_last_used));
    f.writeln(IoLine.Dollar(cfg_ip_central_server,       ip_central_server));
    f.writeln(IoLine.Hash  (cfg_server_port,             server_port));
    f.writeln("");

    f.writefln("// If you set `%s/Y' both to 0, Lix will use your",
     cfg_screen_resolution_x);
    f.writeln(
     "// desktop resolution. To override that, enter the wanted resolution.");

    f.writeln(IoLine.Hash  (cfg_screen_resolution_x,     screen_resolution_x));
    f.writeln(IoLine.Hash  (cfg_screen_resolution_y,     screen_resolution_y));
    f.writeln(IoLine.Hash  (cfg_screen_windowed_x,       screen_windowed_x));
    f.writeln(IoLine.Hash  (cfg_screen_windowed_y,       screen_windowed_y));
    f.writeln(IoLine.Hash  (cfg_screen_vsync,            screen_vsync));
    f.writeln("");

    f.writeln(IoLine.Hash  (cfg_sound_load_driver,       sound_load_driver));
    f.writeln("");

    f.writeln(IoLine.Hash  (cfg_replay_auto_max,         replay_auto_max));
    f.writeln(IoLine.Hash  (cfg_replay_auto_single,      replay_auto_single));
    f.writeln(IoLine.Hash  (cfg_replay_auto_multi,       replay_auto_multi));
    f.writeln(IoLine.Hash  (cfg_replay_auto_next_s,      replay_auto_next_s));
    f.writeln(IoLine.Hash  (cfg_replay_auto_next_m,      replay_auto_next_m));

    f.close();
}
