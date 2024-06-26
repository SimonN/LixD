module menu.lobby.lists;

/* Extra UI elements that appear only in menu.lobby:
 * The list of players in the room, and the netplay color selector.
 */

import std.array;
import std.algorithm;
import std.string;

import file.language;
import graphic.color;
import graphic.internal;
import gui;
import gui.picker.scrolist;
import menu.lobby.handicap;
import net.handicap;
import net.plnr;
import net.profile;
import net.versioning;

class PeerLine : Button {
private:
    Profile _profile;

public:
    this(Geom g, in Profile prof)
    {
        assert (g.xlg >= 220f);
        super(g);
        _profile = prof;
        {
            auto check = new CutbitElement(new Geom(0, 0, 20, 20),
                InternalImage.menuCheckmark.toCutbit);
            check.xf = prof.feeling;
            addChild(check);
        }
        if (prof.feeling != Profile.Feeling.observing) {
            addChild(new CutbitElement(new Geom(20, 0, 20, 20),
                Spritesheet.infoBarIcons.toCutbitFor(prof.style)));
        }
        if (prof.handicap == Handicap.init
            || prof.feeling == Profile.Feeling.observing
        ) {
            addText(40, 110, From.LEFT, color.guiText, prof.name);
            addText(2 * thickg, 70, From.RIGHT,
                color.guiTextDark, prof.clientVersion.toString);
        }
        else {
            addText(40, 80, From.LEFT, color.guiText, prof.name);
            addText(2 * thickg, xlg-120, From.RIGHT, color.guiText,
                prof.handicap.toUiTextAbbreviated);
        }
    }

    override int opCmp(Object o)
    {
        bool isObs(const typeof(this) pb) const pure nothrow @safe @nogc
        {
            return pb._profile.feeling == Profile.Feeling.observing;
        }

        const rhs = cast(typeof(this)) o;
        if (rhs is null) {
            return -1;
        }
        if (isObs(this) != isObs(rhs)) {
            // One is observing and the other isn't.
            return isObs(this) - isObs(rhs);
        }
        else if (isObs(this)) {
            // Both are observing.
            return _profile.name < rhs._profile.name ? -1
                : _profile.name > rhs._profile.name ? 1 : 0;
        }
        // Both want to (eventually) play the next game.
        return _profile.style != rhs._profile.style
            ? cast(int)(_profile.style) - cast(int)(rhs._profile.style)
            : _profile.name < rhs._profile.name ? -1
            : _profile.name > rhs._profile.name ? 1 : 0;
    }

    override void calcSelf()
    {
        on = false;
    }

private:
    void addText(in float x, in float xl, in From from,
        Alcol textCol, in string text
    ) {
        Label l = new Label(new Geom(x, 0, xl, 20, from), text);
        l.color = textCol;
        addChild(l);
    }
}

// ############################################################################

class PeerList : ScrollableButtonList {
public:
    this(Geom g) { super(g); }

    void recreateButtonsFor(in Profile[] players)
    {
        replaceAllButtons(
            cast(Button[])(
                players
                    .map!(prof => new PeerLine(newGeomForButton(), prof))
                    .array
                    .sort
                    .release));
    }
}

// ############################################################################

class RoomList : ScrollableButtonList {
private:
    // Button 0 is the make-new-room button, the room is generated by the
    // server. _ofButtonNPlusOne[0] remembers where button 1 moves to,
    // _ofButtonNPlusOne[1] remembers for botton 2, etc.
    const(RoomListEntry2022)[] _ofButtonNPlusOne;

public:
    this (Geom g) { super(g); }

    bool executeNewRoom() const
    {
        return buttons.length >= 1 && buttons[0].execute;
    }

    bool executeExistingRoom() const
    {
        return buttons.length >= 2 && buttons[1..$].any!(b => b.execute);
    }

    // You should only call this when execute() == true.
    // Returns the number of the room that (the player wants to move to).
    RoomListEntry2022 executeExistingRoomEntry() const
    {
        auto invalid = RoomListEntry2022();
        invalid.room = Room(0); // Caller will likely ignore remaining fields.

        if (buttons.length < 2 || buttons[0].execute) {
            return invalid;
        }
        assert (_ofButtonNPlusOne.length + 1 == buttons.length);
        immutable id = buttons[1..$].countUntil!(b => b.execute);
        return id >= 0 ? _ofButtonNPlusOne[id] : invalid;
    }

    void clearButtons()
    {
        super.replaceAllButtons([]);
        _ofButtonNPlusOne = [];
    }

    void recreateButtonsFor(in RoomListEntry2022[] rooms)
    {
        _ofButtonNPlusOne = rooms.dup;
        Button[] array = [ new TextButton(newGeomForButton(),
                                          Lang.winLobbyRoomCreate.transl) ];
        foreach (ref const entry; _ofButtonNPlusOne) {
            array ~= newTextButtonFor(entry);
        }
        replaceAllButtons(array);
    }

private:
    TextButton newTextButtonFor(in RoomListEntry2022 ro)
    {
        immutable left = ro.owner.clientVersion.compatibleWith(gameVersion)
            ? Lang.winLobbyRoomNumber.translf(ro.room)
            : format!"%s (%s)"(Lang.winLobbyRoomNumber.translf(ro.room),
                ro.owner.clientVersion.compatibles);
        immutable right = ro.numInhabitants < 2
            ? ro.owner.name
            : format!"%s, %s"(ro.owner.name,
                Lang.winLobbyRoomInhabitants.translf(ro.numInhabitants));
        return new TextButton(newGeomForButton(),
            format!"%s: %s"(left, right));
    }
}
