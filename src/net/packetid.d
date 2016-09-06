module net.packetid;

enum : int {
    netPlayerNameMaxLen = 30,
    netChatMaxLen = 300,
    netPeersMax = 127,
    netRoomsMax = 127,
}

/* Player numbers are constant throughout a login session at the server.
 * enum values >= 1 and < 100 are in packets from the client to the server.
 * enum values >= 100 and < 200 are in packets from the server to a client.
 */
enum PacketCtoS : ubyte {
    hello = 2,

    toExistingRoom = 10, // We want to enter an existing room on the server.
    createRoom = 11, // Ask server to create a new room, entering is implicit.

    myProfile = 20, // I updated my profile, please broadcast to my room.
                    // This includes ready-or-not, it's part of the profile.
    chatMessage = 30,
    levelFile = 31,

    // To start a game, the peers set their player profiles to ready.
    myReplayData = 40,
}

enum PacketStoC : ubyte {
    // Responses to hello.
    // On success, we tell the peer his PlNr, constant for this session.
    youGoodHeresPlNr = 101,
    youTooOld = 102,
    youTooNew = 103,
    someoneTooOld = 104, // broadcast to all others when we send youTooOld
    someoneTooNew = 105,

    // Tell a person in the lobby about a new room. When they log on, they
    // get many such packets, one per existing non-lobby room. When a room
    // is created, entered, left, or closed, one packet goes to each lobbyist.
    // This packet tells about the room and the new number of people in it.
    // A room with 0 people is considered nonexistant.
    roomDescription = 110,

    peerJoinsYourRoom = 111,
    peersAlreadyInYourNewRoom = 112,
    peerLeftYourRoom = 113,
    peerDisconnected = 114,

    peerProfile = 120, // someone updated their profile, here it is

    peerChatMessage = 130,
    peerLevelFile = 131,

    // The players sort themselves by PlNr, because e,verybody in a room knows
    // everybody else's PlNr. The permutation decides the order in which the
    // players take hatches and goals.
    gameStartsWithPermu = 140,

    peerReplayData = 141,
    updatesToSync = 142,
}
