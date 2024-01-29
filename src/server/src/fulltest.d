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
    fulltest.github480joinerDesync();
    fulltest.teardown();
}

private struct FullTest {
private:
    NetServer _srv;
    NetClient _cli9; // Still uses the 0.9 protocol from 2021 and earlier.
    NetClient _cliA; // Current minor version.
    NetClient _cliB; // Current minor version.
    NetClient _cliC; // Current minor version.

public:
    enum portDuringThisUnittest = 22934;

    void setup()
    {
        assert (_srv is null, "Don't setup twice.");
        // Server will initialize enet on new, deinitialize on its dispose().
        _srv = new NetServer(portDuringThisUnittest);
        _cli9 = makeClient(Version(0, 9, 907), "9", Style.grey);
        _cliA = makeClient(Version(0, 10, 908), "A", Style.orange);
        _cliB = makeClient(Version(0, 10, 909), "B", Style.green);
        _cliC = makeClient(Version(0, 10, 910), "C", Style.blue);
        await("Client A connects to server", () => _cliA.connected);
        await("Client B connects to server", () => _cliB.connected);
        await("Client C connects to server", () => _cliC.connected);
    }

    void teardown()
    {
        assert (_srv, "Don't teardown twice.");
        _cli9.disconnectAndDispose();
        _cli9 = null;
        _cliA.disconnectAndDispose();
        _cliA = null;
        _cliB.disconnectAndDispose();
        _cliB = null;
        _cliC.disconnectAndDispose();
        _cliC = null;
        _srv.dispose(); // This deinitializes enet.
        _srv = null;
    }

    void cliAPicksYellow()
    {
        assertAllInLobby();
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
        assertAllInLobby();
        class Obs : BlackHole!NetClientObserver {
            bool success = false;
            override void onListOfExistingRooms(in RoomListEntry2022[] arr)
            {
                if (arr.canFind!(e => e.owner.name == "9")) {
                    success = true;
                }
            }
        }
        Obs obs = new Obs();
        _cliA.register(obs);
        _cli9.createRoom();
        await("v9 creates room", () => _cli9.ourRoom != Room(0));
        await("A sees v9's room", () => obs.success);
        _cli9.gotoExistingRoom(Room(0));
        await("v9 comes back to lobby", () => _cli9.ourRoom == Room(0));
        _cliA.unregister(obs);
        assertAllInLobby();
    }

    void github480joinerDesync()
    {
        assertAllInLobby();
        _cliA.createRoom();
        await("A creates room", () => _cliA.ourRoom == Room(1));
        _cliB.gotoExistingRoom(Room(1));
        await("B joins room", () => _cliB.ourRoom == Room(1));
        {
            Profile2022 prof = _cliA.ourProfile;
            prof.feeling = Profile2022.Feeling.ready;
            _cliA.setOurProfile(prof);
        }
        bool heIsReady(in Profile2022 guy) {
            return guy.feeling == Profile2022.Feeling.ready;
        }
        bool nobodyIsReady(in Profile2022[PlNr] guys) {
            return guys.length == 3 && guys.byValue.all!(
                guy => guy.feeling == Profile2022.Feeling.thinking);
        }
        await("B sees that A is ready",
            () => _cliB.profilesInOurRoom.byValue.any!heIsReady);
        await("C is still in the lobby", () => _cliC.ourRoom == Room(0));
        _cliC.gotoExistingRoom(Room(1));
        await("C joins room", () => _cliC.ourRoom == Room(1));
        await("B sees that A isn't ready anymore because C joined",
            () => nobodyIsReady(_cliB.profilesInOurRoom));
        await("C obviously sees everybody as not ready",
            () => nobodyIsReady(_cliC.profilesInOurRoom));
        _cliA.gotoExistingRoom(Room(0));
        _cliB.gotoExistingRoom(Room(0));
        _cliC.gotoExistingRoom(Room(0));
        await("All are back in lobby", () => _cliC.ourRoom == Room(0));
        assertAllInLobby();
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
            _cli9.calc();
            _cliA.calc();
            _cliB.calc();
            _cliC.calc();
            Thread.sleep(dur!"msecs"(1));
        }
    }

    void assertAllInLobby()
    {
        assert (_cli9.connected);
        assert (_cliA.connected);
        assert (_cliB.connected);
        assert (_cliC.connected);
        assert (_cli9.ourRoom == Room(0));
        assert (_cliA.ourRoom == Room(0));
        assert (_cliB.ourRoom == Room(0));
        assert (_cliC.ourRoom == Room(0));
    }
}
