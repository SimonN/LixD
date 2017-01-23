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
import hardware.display;
import gui.iroot;
import gui.element;
import gui.geometry;

public Torbit guiosd; // other gui modules shall use this

private:
    IDrawable[] drawingOnlyElders; // we don't calc these, user calcs
    IRoot[] elders;
    Element[] focus;

    bool clearNextDraw = true;

public:

void
initialize()
{
    assert (display, "must create display before initializing gui");
    assert (guiosd is null);

    Torbit.Cfg cfg;
    cfg.xl = al_get_display_width (display);
    cfg.yl = al_get_display_height(display);
    guiosd = new Torbit(cfg);
    Geom.setScreenXYls(guiosd.xl, guiosd.yl);
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
    clearNextDraw = true;
}

void addFocus(Element toAdd)
{
    focus = focus.remove!(e => e is toAdd);
    focus ~= toAdd;
    // Don't add a parent as a more important focus than its child.
    // This may happen: Parent constructor focuses on the child, but the
    // parent-creating code will focus on the parent.
    foreach (int i, possibleParent; focus)
        if (i > 0 && focus[i].isParentOf(focus[i-1]))
            swap(focus[i-1], focus[i]);
}

void rmFocus(Element toRm)
{
    focus = focus.remove!(a => a is toRm);
    clearNextDraw = true;
}

bool hasFocus(Element elem)
{
    return focus.length && focus[$-1] == elem;
}

void requireCompleteRedraw()
{
    chain(elders, drawingOnlyElders, focus).each!(e => e.reqDraw);
    clearNextDraw = true;
}

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
    if (clearNextDraw) {
        clearNextDraw = false;
        guiosd.clearToColor(color.transp);
        foreach (element; drawingOnlyElders) element.reqDraw();
        foreach (element; elders) element.reqDraw();
        foreach (element; focus)  element.reqDraw();
    }
    auto targetTorbit = TargetTorbit(guiosd);
    foreach (element; drawingOnlyElders) element.draw();
    foreach (element; elders) element.draw();
    foreach (element; focus)  element.draw();
    guiosd.copyToScreen();
}
