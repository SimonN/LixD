module game.tweaker.tweaker;

/*
 * The replay editor that appears when we press the film-strip button.
 */

import std.algorithm;
import std.conv;
import std.range;

import optional;

import basics.help;
import file.language;
import file.replay;
import game.tweaker.nowline;
import game.tweaker.plyline;
import graphic.color;
import gui;
import lix.fields;

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
        in Phyu now,
        in Optional!Passport lixLinesToHighlight)
    out {
        assert (_entries.all!(e => e !is null));
    }
    do {
        const(Ply)[] cutDat = cullPliesSoTheyFitIntoOnePage(dat, now);
        resizeListOfGuiEntriesTo(cutDat.len);
        formatListOfGuiEntries(cutDat, now, lixLinesToHighlight);
        showOrHideEmptyListDescs();
    }

    bool suggestsChange() const pure nothrow @nogc
    {
        return _entries.any!(e => e.suggestsChange);
    }

    ChangeRequest suggestedChange() const pure nothrow @nogc
    in {
        assert (this.suggestsChange);
    }
    do {
        return _entries.find!(e => e.suggestsChange)[0].suggestedChange;
    }

protected:
    override void drawSelf()
    {
        draw3DButton(xs, ys, xls, yls, color.gui);
    }

private:
    mixin template liesInPast()
    {
        bool liesInPast(in Ply aPly) { return aPly.when <= now; }
    }

    static const(Ply)[] cullPliesSoTheyFitIntoOnePage(
        const(Ply)[] plies,
        in Phyu now
    ) {
        // 17 plies plus the NowLine fit on a screen.
        // If we have more plies, we cut around the NowLine to make it 17.
        // Consider a scrollbar instead? But that eats precious space.
        while (plies.len > 17) {
            mixin liesInPast;
            plies = plies.count!liesInPast > 9 ? plies[1..$] : plies[0..$-1];
        }
        return plies;
    }

    void resizeListOfGuiEntriesTo(in int newNumOfEntries)
    out {
        assert (_entries.all!(e => e !is null));
    }
    do {
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
        const(Ply)[] pliesToMatch,
        in Phyu now,
        in Optional!Passport lixToHighlight)
    in {
        assert (_entries.all!(e => e !is null));
    }
    do {
        mixin liesInPast;
        foreach (size_t id, ref PlyLine e; _entries) {
            immutable bool whi = shouldBeWhite(e, lixToHighlight);
            if (e.ply != pliesToMatch[id] || e.isWhite != whi) {
                e.ply = pliesToMatch[id];
                e.white = whi;
                reqDraw(); // redraw all our lines, they can't easily undraw
            }
            e.move(e.geom.x, 30 + 20 * id.to!float
                + (liesInPast(pliesToMatch[id]) ? 0 : 20f));
        }
        if (_nowLine.phyu != now) {
            _nowLine.phyu = now;
            reqDraw();
        }
        _nowLine.move(_nowLine.geom.x,
            30f + 20f * pliesToMatch.count!liesInPast);
    }

    void showOrHideEmptyListDescs() pure @nogc
    in {
        assert (_entries.all!(e => e !is null));
    }
    do {
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

private bool shouldBeWhite(in PlyLine plyLine, in Optional!Passport lix) pure
{
    if (lix.empty || ! plyLine.ply.isAssignment) {
        return false;
    }
    return lix.front.id == plyLine.ply.toWhichLix;
    /*
     * We don't check the style for equality. Reason: Passports know styles,
     * but Plies don't know styles, they only know player numbers. The
     * tweaker doesn't know how to get styles from player numbers, and it
     * shouldn't have to do that in singleplayer anyway.
     */
}
