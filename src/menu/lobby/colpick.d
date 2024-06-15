module menu.lobby.colpick;

/*
 * This is the color selector including the observer button:
 *
 * +----+
 * |    |
 * |    | Color picker
 * |    |
 * +----+
 * |    | Observer button
 * +----+
 */

// unpruned imports
import std.conv;

import file.language;
import file.option.allopts;
import graphic.color;
import graphic.internal;
import gui;
import menu.lobby.handicap;
import net.handicap;
import net.profile;

class ColorSelector : Element {
private:
    ColorButton[] _buttons;
    BitmapButton _observe;
    bool _execute;

public:
    this(Geom g)
    {
        super(g);
        immutable int numButtons = Style.max - Style.red;
        immutable int buttonsPerRow = 2;
        immutable float numRows = (numButtons * 1f / buttonsPerRow) + 1f;
        foreach (int i; 0 .. numButtons) {
            _buttons ~= new ColorButton(new Geom(
                xlg/buttonsPerRow * (i % buttonsPerRow),
                ylg/numRows * (i / buttonsPerRow),
                xlg/buttonsPerRow,
                ylg/numRows), idToStyle(i));
            _buttons[$-1].xf = 1;
            addChild(_buttons[$-1]);
        }
        _observe = new BitmapButton(new Geom(0, 0, xlg, ylg/5f, From.BOTTOM),
            InternalImage.lobbySpec.toCutbit);
        addChild(_observe);
    }

    bool execute() const pure nothrow @safe @nogc { return _execute; }
    bool isObserving() const pure nothrow @safe @nogc { return _observe.on; }
    Style chosenStyle() const pure nothrow @safe @nogc
    {
        foreach (b; _buttons) {
            if (b.on) {
                return b.style;
            }
        }
        return Style.red;
    }

    void choose(in Profile wanted)
    {
        _observe.on = wanted.feeling == Profile.Feeling.observing;
        foreach (b; _buttons) {
            b.on = ! _observe.on && b.style == wanted.style;
        }
    }

protected:
    override void calcSelf()
    {
        _execute = false;
        if (_observe.execute && ! _observe.on) {
            _execute = true;
            _observe.on = true;
            foreach (otherColorButton; _buttons) {
                otherColorButton.on = false;
            }
        }
        foreach (const size_t i, b; _buttons) {
            if (b.execute && ! b.on) {
                _execute = true;
                _observe.on = false;
                foreach (otherColorButton; _buttons) {
                    otherColorButton.on = false;
                }
                b.on = true;
            }
        }
    }

private:
    Style idToStyle(Int)(Int i) const pure nothrow @safe
    {
        try {
            return to!Style(i + Style.red);
        }
        catch (Exception) {
            return Style.red;
        }
    }
}

///////////////////////////////////////////////////////////////////////////////
private: //////////////////////////////////////////////////////////////////////

class ColorButton : BitmapButton {
public:
    immutable Style style;

    this(Geom g, Style st)
    {
        style = st;
        super(g, Spritesheet.infoBarIcons.toCutbitFor(st));
    }

    override @property int yf() const { return 0; }
}
