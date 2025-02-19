module net.client.client;

public import net.permu;
public import net.plnr;
public import net.profile;
public import net.repdata;
public import net.style;
public import net.versioning;

struct NetClientCfg {
    string hostname;
    int port;
    Version clientVersion;
    string ourPlayerName;
    Style ourStyle;
}

/*
 * Register an event callback. The class who implements NetClientObserver
 * should react to  message from the callback information. Usually, the
 * calling class wants to get profilesInOurRoom, too, to update the list
 * as a whole. The class should write one method that queries the profiles
 * from (this) and call that method in many of the callbacks here.
 */
interface NetClientObserver {
    void onConnect();
    void onCannotConnect();
    void onVersionMisfit(in Version serverVersion);
    void onConnectionLost();
    void onChatMessage(in Profile2022 from, in string chat);
    void onPeerDisconnect(in string peerName);
    void onPeerJoinsRoom(in Profile2022);
    void onPeerLeavesRoomTo(in string peerName, in Room toRoom);
    void onPeerChangesProfile(in Profile2022 old, in Profile2022 theNew);
    void onWeChangeRoom(in Room toRoom);

    void onListOfExistingRooms(in RoomListEntry2022[]);
    void onLevelSelect(in string peerNameOfChooser, in ubyte[] data);
    void onGameStart(Permu);
    void onPeerSendsPly(in Ply);

    // The server tells us how many milliseconds have passed.
    // The client adds his networking lag to that value, then calls the
    // delegate with the thereby-increased value of milliseconds.
    void onMillisecondsSinceGameStart(in int millis);
}

interface NetClient {
    void disconnectAndDispose(); // This unregisters all observers.
    /*
     * Call calc() frequently; this receives and sends all due networking
     * packets. The INetClient will then call its NetClinetObservers that
     * you registered beforehand with register().
     */
    void calc();

    void register(NetClientObserver);
    void unregister(NetClientObserver);

    const pure nothrow @safe @nogc {
        bool connected();
        bool connecting();
        const(Profile2022[PlNr]) profilesInOurRoom() in { assert(connected); }
        PlNr ourPlNr() in { assert(connected); }
        Room ourRoom() in { assert(connected); }
        const(Profile2022) ourProfile() in { assert(connected); }
        bool mayWeDeclareReady() in { assert(connected); }
    }

    void setOurProfile(in Profile2022);
    void gotoExistingRoom(Room);
    void createRoom();

    void sendChatMessage(string);
    void selectLevel(const(void[])); // accepts file that's read into a buffer
    void sendPly(in Ply);

    string enetLinkedVersion() const;
}
