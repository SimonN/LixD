module menu.lobbyui;

/* Extra UI elements that appear only in menu.lobby:
 * The list of players in the room, and the netplay color selector.
 */

import std.algorithm;
import std.conv;
import std.math;
import std.range;

import basics.globals;
import graphic.cutbit;
import graphic.internal;
import gui;
import net.structs;
import net.style;

// Opportunity for refactoring: Make the buttons tileable with the scrollbar
// from the picker. Need an interface for a tileable list of elements.
class PeerList : Element {
private:
    Frame _frame;
    TextButton[] _buttons;

public:
    this(Geom g)
    {
        super(g);
        _frame = new Frame(new Geom(0, 0, xlg, ylg));
        addChild(_frame);
    }

    @property float buttonYlg() const { return 20f; }
    @property int maxButtons() const { return (ylg / buttonYlg).floor.to!int; }

    void recreateButtonsFor(const(Profile[]) players)
    {
        reqDraw();
        foreach (b; _buttons)
            rmChild(b);
        _buttons = [];
        foreach (i, profile; players.take(maxButtons)) {
            auto b = new TextButton(new Geom(0, i*buttonYlg, xlg, buttonYlg));
            b.alignLeft = true;
            b.text = profile.name;
            b.checkFrame = profile.feeling;
            _buttons ~= b;
            addChild(b);
        }
    }

protected:
    override void drawSelf() { _frame.undraw(); }
    override void undrawSelf() { _frame.undraw(); } // frame bigger than this.
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
