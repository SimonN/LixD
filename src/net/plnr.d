module net.plnr;

/*
 * Initial parts of most server-to-client and client-to-server packets:
 *  - Player numbers (PlNr),
 *  - room numbers (Room).
 * See header.d for how they're aggregrated into the binary message headers.
 */

// make function interfaces more typesafe
struct PlNr {
    enum int len = 1;
    enum int maxExclusive = 255;
    ubyte n;
    alias n this;
}

struct Room {
    enum int len = 1;
    enum int maxExclusive = 255;
    ubyte n;
    alias n this;
}
