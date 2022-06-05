module net.client.richcli;

/*
 * Steward: A brain for a NetClient. This:
 *  - writes messages to a GUI console, intended for
 *      those messages that shall appear BOTH in game and in lobby
 *      (game or lobby would print the remaining messages themselves),
 *  - remembers the most recently received level and permu for later access.
 */

version (lixDaemon) {}
else:

import std.string;

import basics.globals : homepageURL;
import file.language;
import gui.console;
import level.level;
import net.client.client;

class RichClient : INetClient, NetClientObserver {
private:
    INetClient _inner; // we own one and expose it for callers' use.
    Console _console; // not owned
    Level _level; // owned, may be null
    Permu _permu;

    public string unsentChat; // carry unsent text between Lobby/Game

public:
    this(INetClient anInner, Console aConsole)
    {
        assert (anInner);
        assert (aConsole);
        _inner = anInner;
        _inner.register(this);
        console = aConsole;
    }

    inout(Console) console() inout { return _console; }
    inout(Level) level() inout { return _level; }
    inout(Permu) permu() inout { return _permu; }
    void console(Console c)
    {
        assert (c);
        if (_console)
            c.lines = _console.lines;
        _console = c;
    }

    void disconnectAndDispose()
    {
        _inner.unregister(this);
        _inner.disconnectAndDispose();
        _level = null;
        _console = null;
        _permu = Permu.init;
    }

    void printVersionMisfitFor(in RoomListEntry2022 misfitting)
    {
        printVersionMisfit(misfitting.owner.clientVersion, misfitting.room);
    }

    bool mayWeDeclareReady() const
    {
        return _inner.mayWeDeclareReady && _level && _level.playable;
    }

// ##### Remaining methods of INetClient that we merely forward ###############
    override void calc() { _inner.calc(); }
    void register(NetClientObserver obs) { _inner.register(obs); }
    void unregister(NetClientObserver obs) { _inner.unregister(obs); }
    bool connected() const pure { return _inner.connected(); }
    bool connecting() const pure { return _inner.connecting(); }

    string enetLinkedVersion() const { return _inner.enetLinkedVersion(); }
    const(Profile2022[PlNr]) profilesInOurRoom() const { return _inner.profilesInOurRoom(); }
    PlNr ourPlNr() const pure { return _inner.ourPlNr; }
    Room ourRoom() const pure { return _inner.ourRoom; }
    const(Profile2022) ourProfile() const pure { return _inner.ourProfile; }
    void setOurProfile(in Profile2022 prof) { _inner.setOurProfile(prof); }
    void gotoExistingRoom(Room r) { _inner.gotoExistingRoom(r); }
    void createRoom() { _inner.createRoom(); }

    void sendChatMessage(string chat) { _inner.sendChatMessage(chat); }
    void selectLevel(const(void[]) arr) { _inner.selectLevel(arr); }
    void sendPly(in Ply ply) { _inner.sendPly(ply); }

// ##### Implementation of NetClientObserver ##################################
    void onConnect() {}
    void onCannotConnect()
    {
        _console.add(Lang.netChatYouCannotConnect.transl);
    }

    void onVersionMisfit(in Version serverVersion)
    {
        printVersionMisfit(serverVersion, Room(0));
    }

    void onConnectionLost()
    {
        _console.add(Lang.netChatYouLostConnection.transl);
    }

    void onChatMessage(in string peerName, in string chat)
    {
        _console.addWhite("%s: %s".format(peerName, chat));
    }

    void onPeerDisconnect(in string peerName)
    {
        _console.add(Lang.netChatPeerDisconnected.translf(peerName));
    }

    void onPeerJoinsRoom(in Profile2022 prof)
    {
        _console.add(_inner.ourRoom == Room(0)
            ? Lang.netChatPlayerInLobby.translf(prof.name)
            : Lang.netChatPlayerInRoom.translf(prof.name, _inner.ourRoom));
    }

    void onPeerLeavesRoomTo(in string peerName, in Room toRoom)
    {
        _console.add(toRoom == 0
            ? Lang.netChatPlayerOutLobby.translf(peerName)
            : Lang.netChatPlayerOutRoom.translf(peerName, toRoom));
    }

    void onPeerChangesProfile(in Profile2022 old, in Profile2022 theNew)
    {
        // Print nothing during play. The lobby will print handicap.
    }

    void onWeChangeRoom(in Room toRoom)
    {
        _console.add(toRoom != 0
            ? Lang.netChatWeInRoom.translf(toRoom)
            : Lang.netChatWeInLobby.transl);
    }

    void onListOfExistingRooms(in RoomListEntry2022[]) {}
    void onLevelSelect(in string peerNameOfChooser, in ubyte[] levelRawText) {
        _level = new Level(cast (immutable(void)[]) levelRawText);
        // We don't write to console, the lobby will do that.
        // Reason: We don't want to write this during play.
    }

    void onGameStart(Permu pe) { _permu = pe; }
    void onPeerSendsPly(in Ply) {}
    void onMillisecondsSinceGameStart(in int millis) {}

// ######### End implementation of the interfaces. Now private helpers. #######
private:
    void printVersionMisfit(
        in Version theirVer,
        in Room theirRoom, // or 0 if the entire server misfits
    ) {
        immutable string cantJoinTheyHave = theirRoom == 0
            ? Lang.netChatVersionServerSuggests.translf(theirVer.compatibles)
            : Lang.netChatVersionRoomRequires.translf(
                theirRoom, theirVer.compatibles);
        immutable string butYouHave
            = Lang.netChatVersionYours.translf(gameVersion.toString);
        _console.add("%s %s".format(cantJoinTheyHave, butYouHave));
        if (gameVersion < theirVer) {
            _console.add("%s %s".format(
                Lang.netChatPleaseDownload.transl, homepageURL));
        }
    }
}
