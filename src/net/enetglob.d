module net.enetglob;

/* Globals for NetServer and NetClient to bookkeep enet initialization.
 * User code (outside of package net) should not call these funcs, instead, it
 * should instantiate NetClient or NetServer, and let those call these funcs.
 */

import derelict.enet.enet;

private bool _enetDllLoaded = false;
private bool _enetIsInitialized = false;

package void initializeEnet()
{
    if (! _enetDllLoaded) {
        _enetDllLoaded = true;
        DerelictENet.load();
    }
    if (! _enetIsInitialized) {
        _enetIsInitialized = true;
        if (enet_initialize() != 0)
            assert (false, "error initializing enet");
    }
}

package void deinitializeEnet()
{
    if (_enetIsInitialized) {
        _enetIsInitialized = false;
        enet_deinitialize();
    }
}

ENetPacket* createPacket(T)(T wantLen) nothrow
    if (is (T == int) || is (T == size_t))
{
    return enet_packet_create(null, wantLen & 0x7FFF_FFFF,
        ENET_PACKET_FLAG_RELIABLE);
}
