module net.enetglob;

/* Globals for NetServer and NetClient to bookkeep enet initialization.
 * User code (outside of package net) should not call these funcs, instead, it
 * should instantiate NetClient or NetServer, and let those call these funcs.
 */

import std.string;
import derelict.enet.enet;

private bool _enetDllLoaded = false;
private bool _enetIsInitialized = false;

package:

void initializeEnet()
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

void deinitializeEnet()
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

string enetLinkedVersion()
{
    assert (_enetDllLoaded);
    immutable ver = enet_linked_version();
    return format("%d.%d.%d", ENET_VERSION_GET_MAJOR(ver),
        ENET_VERSION_GET_MINOR(ver), ENET_VERSION_GET_PATCH(ver));
}
