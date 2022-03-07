module net.server.daemon;

/*
 * The daemon is the standalone Lix server application.
 * This instantiates a NetServer and lets that take connections.
 * This isn't used when you click (I want to be server) in the lobby;
 * instead, the main Lix application will create a NetServer itself.
 *
 * This file only compiles during the standalone server build as application.
 * This file doesn't compile for the standalone server's unittests.
 * This file doesn't compile for the main Lix build, neither as app nor tests.
 */

version (lixDaemon)
{
    import core.time;
    import core.thread;
    import std.stdio;
    import std.getopt;
    import net.server.server;

    struct CmdArgs {
        bool printHelp = false;
        int port = 22934; // the default port
    }

    void main(string[] args)
    {
        CmdArgs cmdArgs = parseCmdArgs(args);
        if (cmdArgs.printHelp) {
            writeln("Usage:");
            writeln("--help             ",
                "Show this help.");
            writeln("--port=<number>    ",
                "Listen on UDP port <number> instead of 22934.");
        }
        else {
            auto netServer = new NetServer(cmdArgs.port);
            scope (exit) {
                netServer.dispose();
            }
            writeln("Lix server is listening on UDP port ", cmdArgs.port, ".");
            while (true) {
                Thread.sleep(dur!"msecs"(netServer.anyoneConnected ? 5 : 200));
                netServer.calc();
            }
        }
    }

    CmdArgs parseCmdArgs(string[] args)
    {
        CmdArgs ret;
        try {
            getopt(args,
                "help|h", &ret.printHelp,
                "port", &ret.port);
        }
        catch (Exception e) {
            ret.printHelp = true;
            writeln(e.msg);
        }
        return ret;
    }
}
// end version (lixDaemon)
