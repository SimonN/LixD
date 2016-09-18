module menu.lobbyui;

/* Extra UI elements that appear only in menu.lobby:
 * The list of players in the room, and the netplay color selector.
 */

import std.algorithm;
import std.conv;
import std.math;
import std.range;

import basics.globals;
import file.language;
import graphic.cutbit;
import graphic.internal;
import gui;
import gui.picker.scrolist;
import net.structs;
import net.style;

// This has a scrollbar, and it's scrollable itself.
private abstract class PeerOrRoomList : ScrolledList, IScrollable {
private:
    Button[] _buttons;
    int _top;

public:
    enum float buttonYlg = 20f;

    this(Geom g) { super(g); }

    @property int wheelSpeed() const { return 3; }
    @property int coarseness() const { return 1; }
    @property int pageLen() const { return (ylg / buttonYlg).floor.to!int; }
    @property int totalLen() const { return _buttons.length.to!int; }
    @property int top() const { return _top; }
    @property int top(int newTop)
    {
        // DTODOGUI: There is a bug left behind here.
        // When the list enlarges or shrinks due to newly-arrived data,
        // we would like to keep our scrolling position roughly the same.
        // Yet we should make sure that we aren't scrolled out of bounds.
        if (newTop == _top)
            return _top;
        _top = newTop;
        alignButtons();
        return _top;
    }

protected:
    final override @property inout(IScrollable) tiler() inout { return this; }

    void replaceAllButtons(Button[] array)
    {
        _buttons.each!(b => rmChild(b));
        _buttons = array;
        _buttons.each!(b => addChild(b));
    }

    Geom newGeomForButton(in int i) const
    {
        auto g = newGeomForTiler();
        g.y = i * buttonYlg;
        g.yl = buttonYlg;
        return g;
    }

    void alignButtons()
    {
        reqDraw();
        foreach (int i, b; _buttons)
        {
            b.shown = (i >= _top && i < _top + pageLen);
            b.move(0, (i - _top) * buttonYlg);
        }
    }
}

// ############################################################################

class PeerList : PeerOrRoomList {
public:
    this(Geom g) { super(g); }

    void recreateButtonsFor(const(Profile[]) players)
    {
        Button[] array;
        foreach (int i, profile; players) {
            TextButton b = new TextButton(newGeomForButton(i));
            b.alignLeft = true;
            b.text = profile.name;
            b.checkFrame = profile.feeling;
            array ~= b;
        }
        replaceAllButtons(array);
    }
}

class RoomList : PeerOrRoomList {
public:
    this (Geom g) { super(g); }

    void recreateButtonsFor() // DTODO: add arguments
    {
        auto b = new TextButton(newGeomForButton(0),
            Lang.winLobbyRoomCreate.transl);
        replaceAllButtons([ b ]);
    }
}

// ############################################################################

private class ColorButton : BitmapButton {
    this(Geom g, Style st) { super(g, getPanelInfoIcon(st)); }
    override @property int yf() const { return 0; }
}

class ColorSelector : Element {
private:
    ColorButton[] _buttons;
    BitmapButton _spec;
    bool _execute;

public:
    this(Geom g)
    {
        super(g);
        foreach (int i; 0 .. styleToId(Style.max)) {
            _buttons ~= new ColorButton(new Geom(xlg/2f * (i % 2),
                ylg/5f * (i / 2), xlg/2f, ylg/5f), idToStyle(i));
            _buttons[$-1].xf = 1;
            addChild(_buttons[$-1]);
        }
        _spec = new BitmapButton(new Geom(0, 0, xlg, ylg/5f, From.BOTTOM),
            getInternal(fileImageLobbySpec));
        addChild(_spec);
    }

    bool execute() const { return _execute; }
    @property bool spectating() const { return _spec.on; }
    @property Style style() const
    {
        foreach (int i, b; _buttons)
            if (b.on)
                return idToStyle(i);
        return idToStyle(0);
    }

    @property void setSpectating()
    {
        _buttons.each!(b => b.on = false);
        _spec.on = true;
    }

    @property Style style(Style st)
    {
        foreach (int i, b; _buttons)
            b.on = idToStyle(i) == st;
        _spec.on = false;
        return st;
    }

protected:
    override void calcSelf()
    {
        _execute = false;
        if (_spec.execute && ! spectating) {
            setSpectating();
            _execute = true;
        }
        foreach (int i, b; _buttons)
            if (b.execute && ! b.on) {
                style = idToStyle(i);
                _execute = true;
            }
    }

private:
    Style idToStyle(int i) const { return to!Style(i + Style.red); }
    int styleToId(Style st) const { return st - Style.red; }
}
