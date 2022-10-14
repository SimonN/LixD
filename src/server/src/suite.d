module net.server.suite;

/*
 * The server keeps a hotel.
 * The hotel is divided into rooms, called suites; I chose the name Suite
 * because Room is already the struct for room IDs.
 *
 * One Suite is the Lobby.
 * The other suites are game rooms.
 *
 * Each game suite contains the players and a festival; the festival
 * is the central activitiy in that room.
 */

import std.algorithm;
import std.range;

import net.packetid;
import net.permu;
import net.plnr;
import net.profile;
import net.repdata;
import net.structs;
import net.server.festival;
import net.server.outbox;
import net.versioning;

interface Suite {
    void dispose();

    const pure nothrow @safe @nogc {
        Room room();
        int numInhabitants();
        final bool empty() { return numInhabitants() == 0; }
        bool contains(in PlNr);
        Profile2022 owner() in { assert (!empty); };
        Profile2022 profileOf(in PlNr pl) in { assert (contains(pl)); };
        bool allows(in Version);
    }

    void add(in PlNr nrOfNewbie, in Profile2022 newbie)
        in { assert (! contains(nrOfNewbie)); };
    Profile2022 pop(in PlNr who, in PopReason)
        in { assert (contains(who)); };
    /*
     * Hack to accept packets that contained Profile2016: The inbox had
     * to put some dummy version in the arguments. Ideally, the inbox
     * doesn't have to guess anything to pass us.
     */
    void changeProfileButKeepVersion(
        in PlNr ofWhom,
        in Profile2022 wish)
        in { assert (contains(ofWhom)); };

    void broadcastChat(in PlNr chatter, in string text);
    void receiveLevel(in PlNr chooser, const(ubyte[]) level);
    void receivePly(in Ply);
    void sendTimeSyncingPackets();
    void informLobbyistsAboutRooms(RoomListEntry2022[] listOfRooms);

    struct PopReason {
        enum Reason {
            movedToRoom,
            disconnected,
        }
        Reason whyHeLeft;
        Room whereHeWent; // Ignore unless whyHeLeft == Reason.movedToRoom.
    }
}

class GameSuite : Suite {
private:
    Room _room;
    Outbox _outbox;
    Festival _fe;
    Profile2022[PlNr] _players;

public:
    this(in Room ro, Outbox anOutbox)
    {
        _room = ro;
        _outbox = anOutbox;
    }

    void dispose() { _fe.dispose(); }

    int numInhabitants() const pure nothrow @safe @nogc
    {
        return _players.length & 0xFFFF;
    }

    Room room() const pure nothrow @safe @nogc
    {
        return _room;
    }

    bool contains(in PlNr who) const pure nothrow @safe @nogc
    {
        return (who in _players) !is null;
    }

    Profile2022 owner() const pure nothrow @safe @nogc
    in { assert (! empty); }
    do {
        const Profile2022* ret = _fe.owner in _players;
        assert (ret !is null, "should be ensured by housekeep()");
        return *ret;
    }

    Profile2022 profileOf(in PlNr who) const pure nothrow @safe @nogc
    in { assert (contains(who)); }
    do { return *(who in _players); }

    bool allows(in Version newbie) const pure nothrow @safe @nogc
    {
        return empty || newbie.compatibleWith(owner.clientVersion);
    }

    void add(in PlNr who, in Profile2022 newbie)
    {
        assert (who !in _players);
        _players[who] = newbie;
        unreadyAll();
        housekeep();
        _outbox.describePeersInRoom(who, room, _players, _fe.owner);
        if (_fe.level !is null) {
            _outbox.sendLevelByChooser(who, _fe.level, _fe.levelChooser);
        }
        foreach (receiv; _players.byKey.filter!(pl => pl != who)) {
            _outbox.sendPeerEnteredYourRoom(receiv, room, who, newbie);
        }
    }

    Profile2022 pop(in PlNr who, in PopReason reason)
    {
        assert (who in _players);
        const Profile2022 ret = *(who in _players);
        unreadyAll();
        _players.remove(who);
        housekeep();
        _players.notifyAboutBeingLeftBehind(who, reason, _outbox);
        return ret;
    }

    void changeProfileButKeepVersion(in PlNr ofWhom, in Profile2022 wish)
    {
        const(Profile2022*) old = ofWhom in _players;
        assert (old);
        if (old.wouldForceAllNotReadyOnReplace(wish)) {
            unreadyAll();
        }
        {
            immutable Version oldVer = _players[ofWhom].clientVersion;
            _players[ofWhom] = wish;
            _players[ofWhom].clientVersion = oldVer;
        }
        foreach (receiv; _players.byKey) {
            // Yes, to all in the room, including back to the sender.
            _outbox.sendProfileChangeBy(
                receiv, room, ofWhom, _players[ofWhom]);
        }
        maybeStartGame();
    }

    void broadcastChat(in PlNr chatter, in string text)
    {
        foreach (receiv; _players.byKey) {
            _outbox.sendChat(receiv, chatter, text);
        }
    }

    void receiveLevel(in PlNr chooser, const(ubyte[]) level)
    {
        // Any level data is okay, even an empty one, even a super-long one.
        if (! (chooser in _players)) {
            return;
        }
        unreadyAll();
        _fe.levelChooser = chooser;
        _fe.level = level; // Creates copy.
        foreach (plnr; _players.byKey) {
            // Relay to all, including sender.
            _outbox.sendLevelByChooser(plnr, _fe.level, _fe.levelChooser);
        }
    }

    void receivePly(in Ply ply)
    {
        // For now, we just relay. For more features, see:
        // Observe game in progress on joining room #393
        foreach (other; _players.byKey.filter!(pl => pl != ply.player)) {
            _outbox.sendPly(other, ply);
        }
    }

    void sendTimeSyncingPackets()
    {
        const since = _fe.millisecondsSinceGameStartOrZero;
        if (since <= 0) {
            return;
        }
        foreach (const receiv; _players.byKey) {
            _outbox.sendMillisecondsSinceGameStart(receiv, since);
        }
    }

    void informLobbyistsAboutRooms(RoomListEntry2022[] listOfRooms) {}

private:
    void unreadyAll() @nogc
    {
        // Only server-side; doesn't send packets.
        // The clients must do that on receiving peer-entered/left-room.
        // Somewhere else in the Suite code, we'll send those packets.
        foreach (ref Profile2022 pr; _players) {
            pr.setNotReady();
        }
    }

    void housekeep()
    {
        if (empty) {
            dispose();
        }
        else if (_fe.owner !in _players) {
            _fe.owner = _players.byKey.front;
        }
        assert (empty || _fe.owner in _players); // ...or always have an owner.
    }

    void maybeStartGame()
    {
        auto party() {
            return _players.byValue();
        }
        if ( ! party.any!(prof => prof.feeling == Profile2022.Feeling.ready)
            || party.any!(prof => prof.feeling == Profile2022.Feeling.thinking)
        ) {
            return;
        }
        // Yes, we'll really start the game.
        version (assert) {
            auto p = _fe.owner in _players;
            assert (p);
            assert (! party.empty);
        }
        immutable numTeams = numberOfDifferentTribes(_players);
        unreadyAll(); // Must happen after calling numberOfDifferentTribes.
        auto pa = StartGameWithPermuPacket(numTeams); // This shuffles.
        pa.header.packetID = PacketStoC.gameStartsWithPermu;
        pa.header.plNr = _fe.owner;

        _fe.startGame();
        foreach (receiv; _players.byKey) {
            _outbox.startGame(receiv, pa); // Everybody gets the same shuffle.
        }
    }
}

private int numberOfDifferentTribes(in Profile2022[PlNr] players) pure nothrow @safe @nogc
{
    auto styles = players.byValue
        .filter!(p => p.feeling == Profile2022.Feeling.ready)
        .map!(p => p.style);
    return 0xFFFF & styles.save.enumerate.count!(
        enuStyle => ! styles.save.take(enuStyle.index).canFind!(
            earlierStyle => earlierStyle == enuStyle.value));
}

unittest {
    import net.style;
    Profile2022[PlNr] a;
    Profile2022 p;
    p.feeling = Profile2022.Feeling.ready;
    a[PlNr(3)] = a[PlNr(5)] = a[PlNr(7)] = a[PlNr(9)] = p;
    a[PlNr(3)].style = Style.red;
    a[PlNr(5)].style = Style.yellow;
    a[PlNr(7)].style = Style.red;
    a[PlNr(9)].style = Style.green;
    assert (a.numberOfDifferentTribes == 3);
}

class Lobby : Suite {
    Outbox _outbox;
    Profile2022[PlNr] _lobbyists;

public:
    this(Outbox anOutbox)
    {
        _outbox = anOutbox;
    }

    void dispose() {}

    int numInhabitants() const pure nothrow @safe @nogc
    {
        return _lobbyists.length & 0xFFFF;
    }

    Room room() const pure nothrow @safe @nogc
    {
        return Room(0);
    }

    bool contains(in PlNr who) const pure nothrow @safe @nogc
    {
        return (who in _lobbyists) !is null;
    }

    Profile2022 owner() const pure nothrow @safe @nogc
    in { assert (!empty); }
    do {
        return Profile2022(); // shouldn't be called. Questionable OO.
    }

    Profile2022 profileOf(in PlNr who) const pure nothrow @safe @nogc
    in { assert (contains(who)); }
    do { return *(who in _lobbyists); }

    bool allows(in Version newbie) const pure nothrow @safe @nogc
    {
        return true;
    }

    void add(in PlNr who, in Profile2022 newbie)
    {
        version (assert) {
            import std.conv;
            assert (who !in _lobbyists, "who=" ~ who.to!string
                ~ " shouldn't be in _lobbyists=" ~ _lobbyists.to!string);
        }
        _lobbyists[who] = newbie;
        _outbox.describeLobbyists(who, _lobbyists);
        foreach (lobbyist; _lobbyists.byKey.filter!(pl => pl != who)) {
            _outbox.sendPeerEnteredYourRoom(lobbyist, room, who, newbie);
        }
    }

    Profile2022 pop(in PlNr who, in Suite.PopReason reason)
    {
        version (assert) {
            import std.conv;
            assert (who in _lobbyists, "who=" ~ who.to!string
                ~ " should be in _lobbyists=" ~ _lobbyists.to!string);
        }
        const Profile2022 ret = *(who in _lobbyists);
        _lobbyists.remove(who);
        _lobbyists.notifyAboutBeingLeftBehind(who, reason, _outbox);
        return ret;
    }

    void broadcastChat(in PlNr chatter, in string text)
    {
        foreach (receiv; _lobbyists.byKey) {
            _outbox.sendChat(receiv, chatter, text);
        }
    }

    void changeProfileButKeepVersion(in PlNr ofWhom, in Profile2022 wish)
    {
        {
            immutable Version oldVer = _lobbyists[ofWhom].clientVersion;
            _lobbyists[ofWhom] = wish;
            _lobbyists[ofWhom].clientVersion = oldVer;
        }
        foreach (receiv; _lobbyists.byKey) {
            // Yes, to all in the room, including back to the sender.
            _outbox.sendProfileChangeBy(
                receiv, room, ofWhom, _lobbyists[ofWhom]);
        }
    }

    void receiveLevel(in PlNr chooser, const(ubyte[]) level) {}
    void receivePly(in Ply) {}
    void sendTimeSyncingPackets() {}

    void informLobbyistsAboutRooms(RoomListEntry2022[] listOfRooms)
    {
        foreach (receiv, lobbyist; _lobbyists) {
            _outbox.informLobbyistAboutRooms(receiv,
                lobbyist.clientVersion, listOfRooms);
        }
    }
}

void notifyAboutBeingLeftBehind(
    in Profile2022[PlNr] comrades,
    in PlNr mover,
    in Suite.PopReason reason,
    Outbox outbox,
) {
    foreach (comrade; comrades.byKey) {
        final switch (reason.whyHeLeft) {
        case Suite.PopReason.Reason.movedToRoom:
            outbox.sendPeerLeftYourRoom(comrade, mover, reason.whereHeWent);
            break;
        case Suite.PopReason.Reason.disconnected:
            outbox.sendPeerDisconnected(comrade, mover);
            break;
        }
    }
}
