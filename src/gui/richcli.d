module gui.richcli;

/* A net client wrapper that:
 *  - writes messages to a GUI console,
 *  - remembers the most recently received level and permu.
 *
 * This alias-this'se to INetClient. To send a level, tell it to that class.
 */

import std.string;

import basics.globals : homepageURL;
import file.language;
import gui.console;
import level.level;
import net.iclient;
import net.permu;
import net.phyu;
import net.structs;
import net.versioning;

class RichClient {
private:
    INetClient _inner; // should be treated as owned, but externally c'tored
    Console _console; // not owned
    Level _level;
    Permu _permu;

    public string unsentChat; // carry unsent text between Lobby/Game

public:
    this(INetClient aInner, Console aConsole)
    {
        assert (aInner);
        _inner = aInner;
        console = aConsole;

        onCannotConnect(null);
        onVersionMisfit(null);
        onConnectionLost(null);
        onPeerDisconnect(null);
        onChatMessage(null);
        onPeerJoinsRoom(null);
        onPeerLeavesRoomTo(null);
        onWeChangeRoom(null);
        onGameStart(null);
    }

    alias inner this;
    @property inout(INetClient) inner() inout { return _inner; }
    @property inout(Console) console() inout { return _console; }
    @property inout(Level) level() inout { return _level; }
    @property inout(Permu) permu() inout { return _permu; }

    @property void console(Console c)
    {
        assert (c);
        if (_console)
            c.lines = _console.lines;
        _console = c;
    }

    bool mayWeDeclareReady() const
    {
        return _inner.mayWeDeclareReady && _level && _level.playable;
    }

    @property void onCannotConnect(void delegate() f)
    {
        _inner.onCannotConnect = delegate void()
        {
            _console.add(Lang.netChatYouCannotConnect.transl);
            if (f)
                f();
        };
    };

    @property void onVersionMisfit(void delegate(Version serverVersion) f)
    {
        _inner.onVersionMisfit = delegate void(Version serverVersion)
        {
            _console.add(serverVersion > gameVersion
                ? Lang.netChatWeTooOld.transl : Lang.netChatWeTooNew.transl);
            _console.add("%s %s. %s %s.".format(
                Lang.netChatVersionYours.transl, gameVersion,
                Lang.netChatVersionServer.transl, serverVersion.compatibles));
            _console.add("%s %s".format(
                Lang.netChatPleaseDownload.transl, homepageURL));
            if (f)
                f(serverVersion);
        };
    }

    @property void onConnectionLost(void delegate() f)
    {
        _inner.onConnectionLost = delegate void()
        {
            _console.add(Lang.netChatYouLostConnection.transl);
            if (f)
                f();
        };
    };

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

    @property void onLevelSelect(void delegate(string, const(ubyte[])) f)
    {
        _inner.onLevelSelect = delegate void(string plName, const(ubyte[]) lev)
        {
            _level = new Level(cast (immutable(void)[]) lev);
            // We don't write to console, the lobby will do that.
            // Reason: We don't want to write this during play.
            if (f)
                f(plName, lev);
        };
    }

    @property void onGameStart(void delegate(Permu) f)
    {
        _inner.onGameStart = delegate void(Permu pe)
        {
            _permu = pe;
            if (f)
                f(pe);
        };
    }
}
