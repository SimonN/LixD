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

string ipLastUsed        = "127.0.0.1";
string ipCentralServer   = "asdfasdf.ethz.ch";
int    serverPort        = 22934;



void load()
{
    IoLine[] lines;
    try
        lines = fillVectorFromFile(basics.globals.fileGlobalConfig);
    catch (Exception e) {
        log(e.msg);
        log("Using standard config because config file was not found.");
        log("This is normal when you run Lix for the first time.");
    }

    foreach (i; lines) {

    if      (i.text1 == cfgUserName   ) userName    = i.text2;
    else if (i.text1 == cfgUserNameAsk) userNameAsk = i.nr1 > 0;

    else if (i.text1 == cfgIPLastUsed       ) ipLastUsed       = i.text2;
    else if (i.text1 == cfgIPCentralServer  ) ipCentralServer  = i.text2;

    else if (i.text1 == cfgScreenResolutionX) screenResolutionX = i.nr1;
    else if (i.text1 == cfgScreenResolutionY) screenResolutionY = i.nr1;
    else if (i.text1 == cfgScreenWindowedX  ) screenWindowedX   = i.nr1;
    else if (i.text1 == cfgScreenWindowedY  ) screenWindowedY   = i.nr1;
    else if (i.text1 == cfgScreenVsync      ) screenVsync       = i.nr1 > 0;

    else if (i.text1 == cfgServerPort      ) serverPort         = i.nr1;
    }
    // end foreach
}
// end function load()



void save()
{
    std.stdio.File f;

    try f = std.stdio.File(fileGlobalConfig.rootful, "w");
    catch (Exception e) {
        log(e.msg);
        return;
    }

    f.writeln(IoLine.Dollar(cfgUserName,               userName));
    f.writeln(IoLine.Hash  (cfgUserNameAsk,           userNameAsk));
    f.writeln("");

    f.writeln(IoLine.Dollar(cfgIPLastUsed,            ipLastUsed));
    f.writeln(IoLine.Dollar(cfgIPCentralServer,       ipCentralServer));
    f.writeln(IoLine.Hash  (cfgServerPort,             serverPort));
    f.writeln("");

    f.writefln("// If you set `%s/Y' both to 0, Lix will use your",
     cfgScreenResolutionX);
    f.writeln(
     "// desktop resolution. To force a different resolution, enter it here.");

    f.writeln(IoLine.Hash(cfgScreenResolutionX,     screenResolutionX));
    f.writeln(IoLine.Hash(cfgScreenResolutionY,     screenResolutionY));
    f.writeln(IoLine.Hash(cfgScreenWindowedX,       screenWindowedX));
    f.writeln(IoLine.Hash(cfgScreenWindowedY,       screenWindowedY));
    f.writeln(IoLine.Hash(cfgScreenVsync,           screenVsync));

    f.close();
}
