module gui.conscli;

/* A net client decorator that writes messages to a console.
 * This alias-this'se to INetClient.
 *
 * Maybe this isn't designed well? Maybe the superclass shouldn't expose
 * onStuff(delegate), but rather abstract onStuff() { } to override?
 * How would that work together with decorators?
 */

import std.string;

import file.language;
import gui.console;
import net.iclient;
import net.structs;

class ConsoleNetClient {
private:
    INetClient _inner; // should be treated as owned, but externally c'tored
    Console _console; // not owned

public:
    this(INetClient aInner, Console aConsole)
    {
        assert (aInner);
        _inner = aInner;
        console = aConsole;

        onPeerDisconnect(null);
        onChatMessage(null);
        onPeerJoinsRoom(null);
        onPeerLeavesRoomTo(null);
        onWeChangeRoom(null);
    }

    alias inner this;
    @property inout(INetClient) inner() inout { return _inner; }
    @property inout(Console) console() inout { return _console; }
    @property void console(Console c)
    {
        assert (c);
        if (_console)
            c.lines = _console.lines;
        _console = c;
    }

    @property void onChatMessage(void delegate(string, string) f)
    {
        _inner.onChatMessage = delegate void(string name, string chat)
        {
           _console.addWhite("%s: %s".format(name, chat));
            if (f)
                f(name, chat);
        };
    }

    @property void onPeerDisconnect(void delegate(string) f)
    {
        _inner.onPeerDisconnect = delegate void(string name)
        {
            _console.add("%s %s".format(name,
                                        Lang.netChatPeerDisconnected.transl));
            if (f)
                f(name);
        };
    }

    @property void onPeerJoinsRoom(void delegate(const(Profile*)) f)
    {
        _inner.onPeerJoinsRoom = delegate void(const(Profile*) profile)
        {
            assert (profile, "the network shouldn't send null pointers");
            if (profile.room == 0)
                _console.add("%s %s".format(profile.name,
                    Lang.netChatPlayerInLobby.transl));
            else
                _console.add("%s %s%d%s".format(profile.name,
                    Lang.netChatPlayerInRoom.transl, profile.room,
                    Lang.netChatPlayerInRoom2.transl));
            if (f)
                f(profile);
        };
    }

    @property void onPeerLeavesRoomTo(void delegate(string, Room) f)
    {
        _inner.onPeerLeavesRoomTo = delegate void(string name, Room toRoom)
        {
            if (toRoom == 0)
                _console.add("%s %s".format(name,
                    Lang.netChatPlayerOutLobby.transl));
            else
                _console.add("%s %s%d%s".format(name,
                    Lang.netChatPlayerOutRoom.transl, toRoom,
                    Lang.netChatPlayerOutRoom2.transl));
            if (f)
                f(name, toRoom);
        };
    }

    @property void onWeChangeRoom(void delegate(Room) f)
    {
        _inner.onWeChangeRoom = delegate void(Room toRoom)
        {
            _console.add(toRoom != 0
                ? "%s%d%s".format(Lang.netChatWeInRoom.transl, toRoom,
                                  Lang.netChatWeInRoom2.transl)
                : Lang.netChatWeInLobby.transl);
            if (f)
                f(toRoom);
        };
    }
}
