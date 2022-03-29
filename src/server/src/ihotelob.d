module net.server.ihotelob;

/*
 * Hotel uses an Outbox.
 * Server is an Outbox.
 * Server owns a Hotel and tells that Hotel to do things.
 * The server sets itself as the Hotel's Outbox.
 * The Hotel will then tell the Outbox what to send to everybody.
 *
 * This way, there is no tight coupling between the server and hotel.
 */

import net.repdata;
import net.plnr;
import net.profile;
import net.structs;
import net.permu;

interface Outbox {
    void sendChat(in PlNr receiv, in PlNr fromChatter, in string text);
    void sendProfileChangeBy(in PlNr receiv, in PlNr ofWhom, in Profile full);
    void sendLevelByChooser(PlNr receiv, const(ubyte[]) level, PlNr from);
    void sendPly(PlNr receiv, Ply data);

    void describeRoom(in PlNr receiv, in Profile[PlNr]);
    void informLobbyistAboutRooms(PlNr receiv, in RoomListPacket);
    void sendPeerEnteredYourRoom(PlNr receiv, PlNr mover, in Profile ofMover);
    void sendPeerLeftYourRoom(PlNr receiv, PlNr mover, in Room toWhere);
    void sendPeerDisconnected(PlNr receiv, PlNr disconnector);

    void startGame(in PlNr receiv, in StartGameWithPermuPacket alreadyRolled);
    void sendMillisecondsSinceGameStart(PlNr receiv, int millis);
}
