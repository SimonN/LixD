module game.tweaker.tweaker;

/*
 * The replay editor that appears when we press the film-strip button.
 */

import std.algorithm;
import std.conv;
import std.range;

import basics.help;
import file.language;
import file.replay;
import game.tweaker.nowline;
import game.tweaker.plyline;
import graphic.color;
import gui;

class Tweaker : Element {
private:
    TweakerHeader _header;

    /*
     * _entries doesn't contain the NowLine.
     * Across _entries, the entries' geom.y doesn't grow linearly.
     * geom.y may skip to make space for the NowLine that's not in _entries.
     */
    PlyLine[] _entries;

    NowLine _nowLine; // never null, but is hidden when _entries.empty

    /*
     * Hackish way to determine whether we need a reqDraw() even though no
     * _entries were removed. This caches the number of entries in the past.
     * If _nowLine has to change position, we'll undraw everything.
     * Elements can't move and then undraw properly; that has never been
     * supported in my GUI library so far.
     */
    int _numEntriesInThePastReqDrawOnChange;

    Label _emptyListTitle;
    Label[] _emptyListDescs;

public:
    this(Geom g)
    {
        super(g);
        _header = new TweakerHeader(new Geom(10, 10, xlg-20, 20));
        _nowLine = new NowLine(new Geom(10, 0, xlg-20, 20));
        _emptyListTitle = new Label(new Geom(0, -40, xlg-10, 20, From.CENTER),
            Lang.tweakerEmptyListTitle.transl);
        _emptyListDescs = [
            new Label(new Geom(0, 0, xlg-10, 20, From.CENTER),
            Lang.tweakerEmptyListDesc1.transl),
            new Label(new Geom(0, 20, xlg-10, 20, From.CENTER),
            Lang.tweakerEmptyListDesc2.transl),
            new Label(new Geom(0, 40, xlg-10, 20, From.CENTER),
            Lang.tweakerEmptyListDesc3.transl),
        ];
        addChildren(_header, _nowLine, _emptyListTitle);
        foreach (e; _emptyListDescs) {
            addChild(e);
        }
        showOrHideEmptyListDescs();
        /*
         * We don't undraw the Tweaker when we hide it.
         * color.transp means don't undraw. (Bad convention?)
         * Instead of undrawing, the Game will redraw all GUI, a hack.
         */
        import graphic.color;
        undrawColor = color.transp;
    }

    void formatButtonsAccordingTo(
        const(Ply)[] dat,
        in Phyu now)
    out {
        assert (_entries.all!(e => e !is null));
    }
    body {
        // Here, min(dat.len, 18) is a hack to keep the list short enough
        // for a single screen. Add a scrollbar instead.
        resizeListOfGuiEntriesTo(min(dat.len, 18));
        formatListOfGuiEntries(dat, now);
        showOrHideEmptyListDescs();
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

private:
    void resizeListOfGuiEntriesTo(in int newNumOfEntries)
    out {
        assert (_entries.all!(e => e !is null));
    }
    body {
        while (_entries.len > newNumOfEntries) {
            rmChild(_entries[$-1]);
            _entries[$-1] = null;
            _entries = _entries[0 .. $-1];
            reqDraw(); // Paint over the missing buttons that didn't get any
                       // chance to undraw before we removed them as children
        }
        while (_entries.len < newNumOfEntries) {
            // Add it with geom.y == 0. Other functions will set proper y.
            _entries ~= new PlyLine(new Geom(10, 0, xlg-20, 20));
            addChild(_entries[$-1]);
        }
    }

    /*
     * When this is called, some of the new entries
     * from resizeListOfGuiEntriesTo() may be null
     */
    void formatListOfGuiEntries(
        const(Ply)[] dat,
        in Phyu now)
    in {
        assert (_entries.all!(e => e !is null));
    }
    body {
        bool liesInPast(in Ply aPly) {
            return aPly.update <= now;
        }
        foreach (size_t id, ref PlyLine e; _entries) {
            e.ply = dat[id];
            e.move(e.geom.x, 30 + 20 * id.to!float
                + (liesInPast(dat[id]) ? 0 : 20f));
        }
        _nowLine.phyu = now;
        _nowLine.move(_nowLine.geom.x, 30f + 20f * dat.count!liesInPast);
        immutable inPast = dat.count!liesInPast.to!int;
        if (inPast != _numEntriesInThePastReqDrawOnChange) {
            _numEntriesInThePastReqDrawOnChange = inPast;
            reqDraw();
        }
    }

    void showOrHideEmptyListDescs() pure @nogc
    in {
        assert (_entries.all!(e => e !is null));
    }
    body {
        if (_entries.empty != _emptyListTitle.shown) {
            // Switch between presentation of empty and of nonempty list.
            // Neither header nor the empty-list descriptions can undraw.
            reqDraw();
        }
        _header.shown = _entries.length >= 1;
        _nowLine.shown = _entries.length >= 1;
        _emptyListTitle.shown = _entries.empty;
        _emptyListDescs.each!(e => e.shown = _entries.empty);
    }
}
