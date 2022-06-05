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
    void onChatMessage(in string peerName, in string chat);
    void onPeerDisconnect(in string peerName);
    void onPeerJoinsRoom(in Profile2022);
    void onPeerLeavesRoomTo(in string peerName, in Room toRoom);
    void onPeerChangesProfile(in Profile2022 old, in Profile2022 theNew);
    void onWeChangeRoom(in Room toRoom);

    // Structure of arrays: The n-th room ID from the first array belongs
    // to the n-th player from the second array.
    void onListOfExistingRooms(in RoomListEntry2022[]);
    void onLevelSelect(in string peerNameOfChooser, in ubyte[] data);
    void onGameStart(Permu);
    void onPeerSendsPly(in Ply);

    // The server tells us how many milliseconds have passed.
    // The client adds his networking lag to that value, then calls the
    // delegate with the thereby-increased value of milliseconds.
    void onMillisecondsSinceGameStart(in int millis);
}

interface INetClient {
    void disconnectAndDispose(); // This unregisters all observers.
    void calc(); // call this frequently, this shovels incoming networking
                 // data into refined structs to fetch from other methods

    void register(NetClientObserver);
    void unregister(NetClientObserver);

    bool connected() const pure;
    bool connecting() const pure;

    string enetLinkedVersion() const;
    const(Profile2022[PlNr]) profilesInOurRoom() const in { assert(connected); }
    PlNr ourPlNr() const pure in { assert(connected); }
    Room ourRoom() const pure in { assert(connected); }
    const(Profile2022) ourProfile() const pure in { assert(connected); }
    bool mayWeDeclareReady() const in { assert(connected); }

    void setOurProfile(in Profile2022);
    void gotoExistingRoom(Room);
    void createRoom();

    void sendChatMessage(string);
    void selectLevel(const(void[])); // accepts file that's read into a buffer
    void sendPly(in Ply);
}
