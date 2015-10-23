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

string userName          = "";
bool   userNameAsk       = false;

int    screenResolutionX =   0;
int    screenResolutionY =   0;
int    screenWindowedX   = 640;
int    screenWindowedY   = 480;
bool   screenVsync       = false;

int    replayAutoMax     = 60;
int    replayAutoSingle  =  1;
int    replayAutoMulti   =  1;
int    replayAutoNextS   =  0;
int    replayAutoNextM   =  0;

string ipLastUsed        = "127.0.0.1";
string ipCentralServer   = "asdfasdf.ethz.ch";
int    serverPort        = 22934;



void load()
{
    IoLine[] lines;
    try
        lines = fillVectorFromFile(basics.globals.fileGlobalConfig);
    catch (Exception e) {
        Log.log(e.msg);
        Log.log("Using standard config because config file was not found.");
        Log.log("This is normal when you run Lix for the first time.");
    }

    foreach (i; lines) {

    if      (i.text1 == cfgUserName   ) userName    = i.text2;
    else if (i.text1 == cfgUserNameAsk) userNameAsk = i.nr1 > 0;

    else if (i.text1 == cfgIp_last_used       ) ipLastUsed       = i.text2;
    else if (i.text1 == cfgIp_central_server  ) ipCentralServer  = i.text2;

    else if (i.text1 == cfgReplay_auto_max    ) replayAutoMax    = i.nr1;
    else if (i.text1 == cfgReplay_auto_single ) replayAutoSingle = i.nr1;
    else if (i.text1 == cfgReplay_auto_multi  ) replayAutoMulti  = i.nr1;
    else if (i.text1 == cfgReplay_auto_next_s ) replayAutoNextS  = i.nr1;
    else if (i.text1 == cfgReplay_auto_next_m ) replayAutoNextM  = i.nr1;

    else if (i.text1 == cfgScreenResolutionX) screenResolutionX = i.nr1;
    else if (i.text1 == cfgScreenResolutionY) screenResolutionY = i.nr1;
    else if (i.text1 == cfgScreenWindowedX  ) screenWindowedX   = i.nr1;
    else if (i.text1 == cfgScreenWindowedY  ) screenWindowedY   = i.nr1;
    else if (i.text1 == cfgScreenVsync      ) screenVsync       = i.nr1 > 0;

    else if (i.text1 == cfgServer_port      ) serverPort         = i.nr1;
    }
    // end foreach
}
// end function load()



void save()
{
    std.stdio.File f;

    try f = std.stdio.File(fileGlobalConfig.rootful, "w");
    catch (Exception e) {
        Log.log(e.msg);
        return;
    }

    f.writeln(IoLine.Dollar(cfgUserName,               userName));
    f.writeln(IoLine.Hash  (cfgUserNameAsk,           userNameAsk));
    f.writeln("");

    f.writeln(IoLine.Dollar(cfgIp_last_used,            ipLastUsed));
    f.writeln(IoLine.Dollar(cfgIp_central_server,       ipCentralServer));
    f.writeln(IoLine.Hash  (cfgServer_port,             serverPort));
    f.writeln("");

    f.writefln("// If you set `%s/Y' both to 0, Lix will use your",
     cfgScreenResolutionX);
    f.writeln(
     "// desktop resolution. To override that, enter the wanted resolution.");

    f.writeln(IoLine.Hash(cfgScreenResolutionX,     screenResolutionX));
    f.writeln(IoLine.Hash(cfgScreenResolutionY,     screenResolutionY));
    f.writeln(IoLine.Hash(cfgScreenWindowedX,       screenWindowedX));
    f.writeln(IoLine.Hash(cfgScreenWindowedY,       screenWindowedY));
    f.writeln(IoLine.Hash(cfgScreenVsync,           screenVsync));
    f.writeln("");

    f.writeln(IoLine.Hash(cfgReplay_auto_max,       replayAutoMax));
    f.writeln(IoLine.Hash(cfgReplay_auto_single,    replayAutoSingle));
    f.writeln(IoLine.Hash(cfgReplay_auto_multi,     replayAutoMulti));
    f.writeln(IoLine.Hash(cfgReplay_auto_next_s,    replayAutoNextS));
    f.writeln(IoLine.Hash(cfgReplay_auto_next_m,    replayAutoNextM));

    f.close();
}
