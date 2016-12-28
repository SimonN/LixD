module net.iclient;

import net.permu;
import net.structs;
import net.style;

interface INetClient {
    void calc(); // call this frequently, this shovels incoming networking
                 // data into refined structs to fetch from other methods
    void sendChatMessage(string);

    @property bool connected() const;
    @property bool connecting() const;
    void disconnect();

    @property string enetLinkedVersion() const;

    @property const(Profile[PlNr]) profilesInOurRoom();
    @property PlNr ourPlNr() const;
    @property const(Profile) ourProfile() const;
    @property bool mayWeDeclareReady() const;

    // Call this when the GUI has chosen a new Lix style.
    // The GUI may update ahead of time, but what the server knows, decides.
    // Feeling is readiness, and whether we want to observe.
    @property void ourStyle(Style sty);
    @property void ourFeeling(Profile.Feeling feel);
    void gotoExistingRoom(Room);
    void createRoom();

    void selectLevel(const(void[])); // accepts file that's read into a buffer

    // Register an event callback. The class who designs the callback functions
    // should display a message from the callback information. Usually, the
    // calling class wants to get profilesInOurRoom, too, to update the list
    // as a whole. The class should write one method that queries the profiles
    // from (this) and call that method in many of the callbacks here.
    @property void onConnect(void delegate());
    @property void onCannotConnect(void delegate());
    @property void onConnectionLost(void delegate());
    @property void onChatMessage(void delegate(string name, string chat));
    @property void onPeerDisconnect(void delegate(string name));
    @property void onPeerJoinsRoom(void delegate(const(Profile*)));
    @property void onPeerLeavesRoomTo(void delegate(string name, Room toRoom));
    @property void onPeerChangesProfile(void delegate(const(Profile*)));
    @property void onWeChangeRoom(void delegate(Room toRoom));

    // Structure of arrays: The n-th room ID from the first array belongs
    // to the n-th player from the second array.
    @property void onListOfExistingRooms(void delegate(const(Room[]),
                                                       const(Profile[])));
    @property void onLevelSelect(void delegate(string name, const(ubyte[]) data));
    @property void onGameStart(void delegate(Permu));
}
