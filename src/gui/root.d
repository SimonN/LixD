module gui.root;

/* This was Api::Manager in C++/A4 Lix. Here, it's a module, not a singleton
 * class.
 *
 * Public functions:
 *
 *  void initialize();
 *  void deinitialize();
 *
 *  void add/rm_elder(Element);
 *  void add/rm_focus(Element);
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

    bool clear_next_draw = true;



public:

void
initialize()
{
    assert (display, "must create display before initializing gui");
    assert (guiosd is null);

    guiosd = new Torbit(al_get_display_width (display),
                        al_get_display_height(display));
    assert (guiosd);
    Geom.set_screen_xyls(guiosd.xl, guiosd.yl);
}



void
deinitialize()
{
    if (guiosd) destroy(guiosd);
    guiosd = null;
}



void
add_elder(Element to_add)
{
    if (elders.find!"a is b"(to_add) != []) return;
    elders ~= to_add;
}



void
rm_elder(Element to_rm)
{
    elders = elders.remove!(a => a is to_rm);
    clear_next_draw = true;
}



void
add_focus(Element to_add)
{
    size_t insert_here = focus.length;

    for (int i = 0; i < focus.length; ++i) {
        Element e = focus[i];
        // Erase all instances (should be at most one) of e in the queue,
        // we're going to add it to the end later.
        if (e is to_add) {
            focus.remove(i);
            --insert_here;
        }
        // Do not add a parent as a more important focus than its child.
        // This may happen: A parent's constructor may add the child as
        // focus immediately, but the parent-creating code will then add
        // the parent as focus, overriding the child.
        else if (to_add.is_parent_of(e) && insert_here == focus.length) {
            insert_here = i;
        }
    }
    focus = focus[0 .. insert_here] ~ to_add ~ focus[insert_here .. $];
}



void
rm_focus(Element to_rm)
{
    focus = focus.remove!(a => a is to_rm);
    clear_next_draw = true;
}


void
calc()
{
    if (focus.length > 0) {
        focus[$-1].calc();
    }
    else {
        foreach (e; elders) e.calc();
    }
    foreach (e; elders) e.work();
    foreach (e; focus ) e.work();
}



void
draw()
{
    assert (guiosd);

    if (clear_next_draw) {
        clear_next_draw = false;
        guiosd.clear_to_color(color.transp);
        foreach (element; elders) element.req_draw();
        foreach (element; focus)  element.req_draw();
    }

    auto drata = DrawingTarget(guiosd.albit);
    foreach (element; elders) element.draw();
    foreach (element; focus)  element.draw();

    guiosd.copy_to_screen();
}
