module net.client.withserv;

/*
 * A networking client (to be created by the interactive game)
 * that contains a server and connects to that server.
 * This should be created when the interactive game wants to host.
 * This is not the command-line server app: See module net.server.daemon.
 */

version (lixDaemon) {}
else:

import net.client.client;
import net.client.impl;
import net.server.server;

class ClientWithServer : NetClient {
private:
    NetServer _server;

public:
    this(NetClientCfg cfg)
    {
        assert (cfg.hostname == "127.0.0.1" || cfg.hostname == "localhost");
        _server = new NetServer(cfg.port);
        super(cfg);
    }

    override void disconnectAndDispose()
    {
        super.disconnectAndDispose();
        _server.dispose();
    }

    override void calc()
    {
        super.calc();
        _server.calc();
    }
}
