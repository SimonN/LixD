module game.repedit.repedit;

/*
 * The replay editor that appears when we press the film-strip button.
 */

import std.algorithm;
import std.conv;

import basics.help;
import file.replay;
import game.repedit.oneline;
import graphic.color;
import gui;

class Tweaker : Element {
private:
    OneLine[] _entries;

public:
    this(Geom g)
    {
        super(g);
        /*
         * We don't undraw the Tweaker when we hide it.
         * color.transp means don't undraw. (Bad convention?)
         * Instead of undrawing, the Game will redraw all GUI, a hack.
         */
        import graphic.color;
        undrawColor = color.transp;
    }

    void formatButtonsAccordingTo(const(Ply[]) dat)
    out {
        assert (_entries.all!(e => e !is null));
    }
    body {
        for (int i = dat.len; i < _entries.len; ++i) {
            rmChild(_entries[i]);
            _entries[i] = null;
            reqDraw(); // Paint over the missing buttons that didn't get any
                       // chance to undraw before we removed them as children
        }
        _entries.length = dat.length;
        foreach (size_t id, ref OneLine e; _entries) {
            if (e is null) {
                immutable float entryY = 10 + 20 * id.to!float;
                e = new OneLine(new Geom(10, entryY, xlg-20, 20));
                addChild(e);
            }
            e.ply = dat[id];
        }
    }

    @property bool suggestsChange() const pure nothrow @nogc
    {
        return _entries.any!(e => e.suggestsChange);
    }

    @property ChangeRequest suggestedChange() const pure nothrow @nogc
    in {
        assert (this.suggestsChange);
    }
    body {
        return _entries.find!(e => e.suggestsChange)[0].suggestedChange;
    }

protected:
    override void drawSelf()
    {
        draw3DButton(xs, ys, xls, yls, color.guiL, color.guiM, color.guiD);
    }
}
