module basics.globconf;

/* global variables that may change during program run, and are saved
 * to the global config file. The global config file is different from the
 * user config file, it pertains to all users.
 */

import std.file;
import std.stdio;

import basics.globals;
import file.io;
import file.log;

string userName          = "";
string ipLastUsed        = "127.0.0.1";
string ipCentralServer   = "lixgame.com";
int    serverPort        = 22934;

void load()
{
    IoLine[] lines;
    try {
        lines = fillVectorFromFile(basics.globals.fileGlobalConfig);
    }
    catch (Exception e) {
        log("Can't load the global configuration:");
        log("    -> " ~ e.msg);
        log("    -> Falling back to the standard global configuration.");
        log("    -> This is normal when you run Lix for the first time.");
    }
    foreach (i; lines) {
        if      (i.text1 == cfgUserName       ) userName         = i.text2;
        else if (i.text1 == cfgIPLastUsed     ) ipLastUsed       = i.text2;
        else if (i.text1 == cfgIPCentralServer) ipCentralServer  = i.text2;
        else if (i.text1 == cfgServerPort     ) serverPort       = i.nr1;
    }
}

void save()
{
    if (userName == "")
        // don't save during noninteractive mode, where we didn't load the cfg
        return;
    try {
        std.stdio.File f = fileGlobalConfig.openForWriting();

        f.writeln(IoLine.Dollar(cfgUserName,        userName));
        f.writeln();
        f.writeln(IoLine.Dollar(cfgIPLastUsed,      ipLastUsed));
        f.writeln(IoLine.Dollar(cfgIPCentralServer, ipCentralServer));
        f.writeln(IoLine.Hash  (cfgServerPort,      serverPort));
        f.close();
    }
    catch (Exception e)
        log(e.msg);
}
