module gui.root;

/* This was Api::Manager in C++/A4 Lix. Here, it's a module, not a singleton
 * class.
 *
 * Public functions:
 *
 *  void initialize();
 *  void deinitialize();
 *
 *  void add/rmElder(Element);
 *  void add/rmFocus(Element);
 *
 *  void calc_gui();
 *  void draw_gui_and_this_cursor_then_blit_to_screen(Graphic = null);
 */

import std.algorithm;

import basics.alleg5;
import graphic.color;
import graphic.graphic; // mouse cursor
import graphic.torbit;
import hardware.display;
import gui;

public Torbit guiosd; // other gui modules shall use this

private:

    Element[] elders;
    Element[] focus;

    bool clearNextDraw = true;



public:

void
initialize()
{
    assert (display, "must create display before initializing gui");
    assert (guiosd is null);

    guiosd = new Torbit(al_get_display_width (display),
                        al_get_display_height(display));
    assert (guiosd);
    Geom.setScreenXYls(guiosd.xl, guiosd.yl);
}



void
deinitialize()
{
    if (guiosd) destroy(guiosd);
    guiosd = null;
}



void
addElder(Element toAdd)
{
    if (elders.find!"a is b"(toAdd) != []) return;
    elders ~= toAdd;
}



void
rmElder(Element to_rm)
{
    elders = elders.remove!(a => a is to_rm);
    clearNextDraw = true;
}



void
addFocus(Element toAdd)
{
    size_t insertHere = focus.length;

    for (int i = 0; i < focus.length; ++i) {
        Element e = focus[i];
        // Erase all instances (should be at most one) of e in the queue,
        // we're going to add it to the end later.
        if (e is toAdd) {
            focus.remove(i);
            --insertHere;
        }
        // Do not add a parent as a more important focus than its child.
        // This may happen: A parent's constructor may add the child as
        // focus immediately, but the parent-creating code will then add
        // the parent as focus, overriding the child.
        else if (toAdd.isParentOf(e) && insertHere == focus.length) {
            insertHere = i;
        }
    }
    focus = focus[0 .. insertHere] ~ toAdd ~ focus[insertHere .. $];
}



void
rmFocus(Element toRm)
{
    focus = focus.remove!(a => a is toRm);
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
        foreach (element; elders) element.reqDraw();
        foreach (element; focus)  element.reqDraw();
    }
    auto drata = DrawingTarget(guiosd.albit);
    foreach (element; elders) element.draw();
    foreach (element; focus)  element.draw();
    guiosd.copyToScreen();
}
