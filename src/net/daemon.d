module net.daemon;

/* A standalone daemon application.
 * This instantiates a NetServer and lets that take connections.
 * This isn't used when you click (I want to be server) in the lobby,
 * instead, the main Lix application will run
 */

version (lixDaemon)
{
    import core.time;
    import core.thread;

    import net.server;

    enum defaultPort = 22934;

    void main()
    {
        auto netServer = new NetServer(defaultPort);
        scope (exit)
            destroy(netServer);

        while (true) {
            Thread.sleep(dur!"msecs"(netServer.anyoneConnected ? 5 : 300));
            netServer.calc();
        }
    }
}
// end version (lixDaemon)
