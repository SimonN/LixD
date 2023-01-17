module game.tweaker.oneline;

import std.format;
import basics.help;
import file.replay.tweakrq;
import graphic.color;
import gui;

class OneLine : Element {
private:
    Label _phyuText;
    Phyu _phyu;

protected:
    enum butXlg = 20;
    enum phyuXlg = 40;

public:
    this(Geom g)
    in { assert(g.xlg >= 4 * butXlg, "no space for row of text"); }
    do {
        super(g);
        /*
         * We don't set an undraw color. Even though we want to be undrawn
         * when deleted, we will be deleted before we get a chance to undraw.
         * Therefore, our owner will redraw itself entirely after deleting us.
         * It's a hack.
         */
        _phyuText = new Label(new Geom(
            thickg + 2 * butXlg, 0, phyuXlg - thickg + 5f, // +5 to be lenient.
            g.ylg, From.RIGHT)); // +5 is necessary for 5 digits on 640x480.
        _phyuText.abbreviateNear = Label.AbbreviateNear.beginning;
        addChild(_phyuText);
    }

    @property Phyu phyu() const pure nothrow @nogc
    {
        return _phyu;
    }

    @property Phyu phyu(in Phyu aPhyu)
    {
        if (_phyu == aPhyu) {
            return _phyu;
        }
        _phyu = aPhyu;
        _phyuText.text = tweakerFormat(_phyu);
        reqDraw(); // labels can't easily undraw
        return _phyu;
    }

protected:
    override void drawSelf()
    {
        undrawColor = color.gui.m; // Erase the labels, they can't undraw
        undraw();
    }

private:
    string tweakerFormat(in Phyu n) const pure @safe
    {
        if (n < 10_000) {
            return format("%d", n);
        }
        return format("%s%03d", expressWithTheseDigits(n / 1000, subscript),
            n % 1000);
    }
}
