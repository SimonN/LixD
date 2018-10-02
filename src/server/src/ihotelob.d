module net.server.ihotelob;

/* Hotel uses an IHotelObserver.
 * Server is an IHotelObserver.
 * Server owns a Hotel and sets itself as the Hotel's IHotelObserver.
 *
 * This way, there is no tight coupling between the server and hotel.
 */

import net.repdata;
import net.structs;

interface IHotelObserver {
    const(Profile[PlNr]) allPlayers() const @nogc;

    void broadcastDisconnectionOfAndRemove(PlNr);
    void unreadyAllInRoom(Room);

    void sendLevelByChooser(PlNr receiv, const(ubyte[]) level, PlNr from);
    void sendReplayData(PlNr receiv, ReplayData data);
    void describeRoom(PlNr receiv, const(ubyte[]) level, PlNr from);
    void informLobbyistAboutRooms(PlNr receiv);

    void sendPeerEnteredYourRoom(PlNr receiv, PlNr mover);
    void sendPeerLeftYourRoom(PlNr receiv, PlNr mover);

    void startGame(PlNr roomOwner, int permuLength);
    void sendMillisecondsSinceGameStart(PlNr receiv, int millis);
}
