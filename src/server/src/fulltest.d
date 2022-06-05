module net.server.fulltest;

/*
 * Full-fledged client-server system test. We create a server and have him
 * listen on the real operating system's port 22934 (the default Lix port).
 * You can't run a server daemon while you're running this test.
 *
 * We create several clients and have them connect to the server via port
 * 22934.
 */

version (unittest):

import core.thread;
import core.time;

import std.algorithm;
import std.typecons;
import std.range;

import net.server.server;
import net.client.client;
import net.client.impl;
import net.style;
import net.plnr;
import net.profile;
import net.versioning;

unittest {
    FullTest fulltest;
    fulltest.setup();
    fulltest.cliAPicksYellow();
    fulltest.cliAOpensRoom();
    fulltest.teardown();
}

private struct FullTest {
private:
    NetServer _srv;
    NetClient _cliA;
    NetClient _cliB;
    NetClient _cliC;
    NetClient _cliD;

public:
    enum portDuringThisUnittest = 22934;

    void setup()
    {
        assert (_srv is null, "Don't setup twice.");
        // Server will initialize enet on new, deinitialize on its dispose().
        _srv = new NetServer(portDuringThisUnittest);
        _cliA = makeClient(Version(0, 9, 908), "A", Style.orange);
        _cliB = makeClient(Version(0, 9, 909), "B", Style.green);
        _cliC = makeClient(Version(0, 10, 911), "C", Style.blue);
        _cliD = makeClient(Version(0, 10, 912), "D", Style.purple);
        await("Client A connects to server", () => _cliA.connected);
        await("Client B connects to server", () => _cliB.connected);
        await("Client C connects to server", () => _cliC.connected);
        await("Client D connects to server", () => _cliD.connected);
    }

    void teardown()
    {
        assert (_srv, "Don't teardown twice.");
        _cliA.disconnectAndDispose();
        _cliA = null;
        _cliB.disconnectAndDispose();
        _cliB = null;
        _cliC.disconnectAndDispose();
        _cliC = null;
        _cliD.disconnectAndDispose();
        _cliD = null;
        _srv.dispose(); // This deinitializes enet.
        _srv = null;
    }

    void cliAPicksYellow()
    {
        assert (_cliA.connected);
        assert (_cliB.connected);
        assert (_cliA.ourProfile.name == "A");
        assert (_cliA.ourProfile.style == Style.orange);
        await("B got A's initial orange", ()
            => _cliB.profilesInOurRoom.byValue.canFind!(prof
                => prof.style == Style.orange));
        {
            Profile2022 prof = _cliA.ourProfile;
            prof.style = Style.yellow;
            _cliA.setOurProfile(prof);
        }
        await("A picks style, orange -> yellow", ()
            => _cliA.ourProfile.style == Style.yellow);
        await("B got A's style, orange -> yellow", ()
            => _cliB.profilesInOurRoom.byValue.canFind!(prof
                => prof.style == Style.yellow));
        assert (_cliB.ourProfile.style == Style.green);
    }

    void cliAOpensRoom()
    {
        assert (_cliA.ourRoom == Room(0));
        assert (_cliB.ourRoom == Room(0));
        assert (_cliC.ourRoom == Room(0));
        class Obs : BlackHole!NetClientObserver {
            bool success = false;
            override void onListOfExistingRooms(in RoomListEntry2022[] arr)
            {
                if (arr.canFind!(e => e.owner.name == "A")) {
                    success = true;
                }
            }
        }
        Obs[] obs = [ new Obs, new Obs ];
        _cliB.register(obs[0]);
        _cliC.register(obs[1]);
        _cliA.createRoom();
        await("A creates room", () => _cliA.ourRoom != Room(0));
        await("B sees A's room", () => obs[0].success);
        await("C sees A's room", () => obs[1].success);
        _cliB.unregister(obs[0]);
        _cliC.unregister(obs[1]);
    }

private:
    NetClient makeClient(in Version v, in string name, in Style st)
    {
        return new NetClient(NetClientCfg("localhost", portDuringThisUnittest,
            v, name, st));
    }

    void await(in string testName, bool delegate() successCondition)
    {
        const start = MonoTime.currTime;
        while (! successCondition()) {
            if (MonoTime.currTime > start + dur!"msecs"(500)) {
                throw new Exception("Timeout during: " ~ testName);
            }
            _srv.calc();
            _cliA.calc();
            _cliB.calc();
            _cliC.calc();
            _cliD.calc();
            Thread.sleep(dur!"msecs"(1));
        }
    }
}
