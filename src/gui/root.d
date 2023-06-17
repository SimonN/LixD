module gui.root;

/* This was Api::Manager in C++/A4 Lix. Here, it's a module, not a singleton
 * class.
 */

import std.algorithm;
import std.range;

import basics.alleg5;
import graphic.color;
import graphic.graphic; // mouse cursor
import graphic.torbit;
import gui.iroot;
import gui.element;
import gui.geometry;

public Torbit guiosd; // other gui modules shall use this

private:
    IDrawable[] drawingOnlyElders; // we don't calc these, user calcs
    IRoot[] elders;
    Element[] focus;

    bool _clearNextDraw = true;

public:

void initialize(in int aScreenXl, in int aScreenYl)
{
    assert (guiosd is null);
    Torbit.Cfg cfg;
    cfg.xl = aScreenXl;
    cfg.yl = aScreenYl;
    guiosd = new Torbit(cfg);
}

void
deinitialize()
{
    if (guiosd) destroy(guiosd);
    guiosd = null;
}

void addElder(IRoot toAdd)
{
    if (chain(elders, drawingOnlyElders).canFind!"a is b"(toAdd))
        return;
    elders ~= toAdd;
}

void addDrawingOnlyElder(IDrawable toAdd)
{
    if (chain(elders, drawingOnlyElders).canFind!"a is b"(toAdd))
        return;
    drawingOnlyElders ~= toAdd;
}

void rmElder(IDrawable to_rm)
{
    elders = elders.remove!(a => a is to_rm);
    drawingOnlyElders = drawingOnlyElders.remove!(a => a is to_rm);
    _clearNextDraw = true;
}

void addFocus(Element toAdd) nothrow @safe
{
    focus = focus.remove!(e => e is toAdd);
    focus ~= toAdd;
    // Don't add a parent as a more important focus than its child.
    // This may happen: Parent constructor focuses on the child, but the
    // parent-creating code will focus on the parent.
    foreach (const size_t i, possibleParent; focus) {
        if (i > 0) {
            if (focus[i].isParentOf(focus[i-1])) {
                swap(focus[i-1], focus[i]);
}   }   }   }

void rmFocus(Element toRm) nothrow @safe
{
    focus = focus.remove!(a => a is toRm);
    _clearNextDraw = true;
}

bool hasFocus(Element elem) nothrow @safe @nogc
{
    return focus.length && focus[$-1] is elem;
}

void requireCompleteRedraw() { _clearNextDraw = true; }

void calc()
{
    if (focus.length)
        focus[$-1].calc();
    else
        foreach (e; elders) e.calc();
    foreach (e; elders) e.work();
    foreach (e; focus ) e.work();
}

void draw()
{
    assert (guiosd);
    if (_clearNextDraw) {
        _clearNextDraw = false;
        guiosd.clearToColor(color.transp);
        chain(drawingOnlyElders, elders, focus).each!(e => e.reqDraw);
    }
    auto targetTorbit = TargetTorbit(guiosd);

    // When the lobby receives new information, the lobby redraws.
    // That draws over the focussed level browser, thus redraw the browser.
    // e.draw() returns true if e or any children required drawing.
    bool redrawFocus = false;
    foreach (e; chain(drawingOnlyElders, elders))
        redrawFocus = e.draw() || redrawFocus;
    foreach (e; focus) {
        if (redrawFocus)
            e.reqDraw();
        redrawFocus = e.draw() || redrawFocus;
    }
    guiosd.copyToScreen();
}
