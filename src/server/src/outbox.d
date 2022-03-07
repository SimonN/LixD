module net.server.outbox;

/*
 * Hotel uses an Outbox.
 * Server owns a Hotel and tells that Hotel to do things.
 * The server sets its dispatching outbox as the Hotel's Outbox.
 * The Hotel will then tell the Outbox what to send to everybody.
 *
 * This way, there is no tight coupling between the server and hotel.
 *
 * The server implements Outbox, but really contains several real Outboxes
 * (that will call the enet API) to which the server (as Outbox) forwards.
 */

import net.repdata;
import net.permu;
import net.plnr;
import net.profile;
import net.structs;
import net.versioning;

interface Outbox {
    void sendChat(in PlNr receiv, in PlNr fromChatter, in string text);

    void informLobbyistAboutRooms(
        in PlNr receiv,
        in Version ofReceiver, // Only needed to filter for 0.9.x clients
        RoomListEntry2022[] roomEntries);

    void describeLobbyists(in PlNr receiv, in Profile2022[PlNr] lobbyists);

    void describePeersInRoom(
        in PlNr receiv,
        in Room here,
        in Profile2022[PlNr] inhab,
        in PlNr ownerOfHere);

    void sendPeerEnteredYourRoom(
        in PlNr receiv,
        in Room here, // Only needed to send Profile2016 to 0.9.x clients
        in PlNr mover,
        in Profile2022 ofMover);

    void sendProfileChangeBy(
        in PlNr receiv,
        in Room here, // Only needed to send Profile2016 to 0.9.x clients
        in PlNr ofWhom,
        in Profile2022 full);

    void sendLevelByChooser(PlNr receiv, const(ubyte[]) level, PlNr from);

    void sendPeerLeftYourRoom(PlNr receiv, PlNr mover, in Room toWhere);

    void sendPeerDisconnected(PlNr receiv, PlNr disconnector);

    void startGame(in PlNr receiv, in StartGameWithPermuPacket alreadyRolled);
    void sendPly(PlNr receiv, Ply data);
    void sendMillisecondsSinceGameStart(PlNr receiv, int millis);
}
