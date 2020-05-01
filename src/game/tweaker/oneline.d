module game.tweaker.oneline;

import file.replay.tweakrq;
import graphic.color;
import gui;

class OneLine : Element {
private:
    Label _phyuText;
    Phyu _phyu;

protected:
    enum butXlg = 20;

public:
    this(Geom g)
    in { assert(g.xlg >= 4 * butXlg, "no space for row of text"); }
    body {
        super(g);
        /*
         * We don't set an undraw color. Even though we want to be undrawn
         * when deleted, we will be deleted before we get a chance to undraw.
         * Therefore, our owner will redraw itself entirely after deleting us.
         * It's a hack.
         */
        _phyuText = new Label(new Geom(
            thickg + 2 * butXlg, 0, 60, g.ylg, From.RIGHT));
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
        _phyuText.number = _phyu;
        reqDraw(); // labels can't easily undraw
        return _phyu;
    }

protected:
    override void drawSelf()
    {
        undrawColor = color.guiM; // Erase the labels, they can't undraw
        undraw();
    }
}
