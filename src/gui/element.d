module gui.element;

import std.algorithm;

import basics.alleg5;
import graphic.color;
import gui;
import hardware.mouse; // is_mouse_here

abstract class Element {

/*  this([Geom.From], x, y, xl, yl);
 *
 *      has the same constructors as class Geom
 *
 *  ~this();
 *
 *      un-parents all children
 */
    // these functions return the position/length in geoms. See geometry.d
    // for the difference between measuring in geoms and in screen pixels.
    @property float xg()  const { return geom.xg;  }
    @property float yg()  const { return geom.yg;  }
    @property float xlg() const { return geom.xlg; }
    @property float ylg() const { return geom.ylg; }

    @property float xs()  const { return geom.xs;  }
    @property float ys()  const { return geom.ys;  }
    @property float xls() const { return geom.xls; }
    @property float yls() const { return geom.yls; }

    void set_x (float i) { geom.x  = i; req_draw(); }
    void set_y (float i) { geom.y  = i; req_draw(); }
    void set_xl(float i) { geom.xl = i; req_draw(); }
    void set_yl(float i) { geom.yl = i; req_draw(); }

    const(Geom) get_geom() const { return geom; }

    AlCol get_undraw_color() const  { return undraw_color; }
    void  set_undraw_color(AlCol c) { undraw_color = c;    }

    bool get_hidden() const        { return hidden; }
    void set_hidden(bool b = true) { hidden = b; req_draw(); }
    void hide() { set_hidden(true);  }
    void show() { set_hidden(false); }

    void hide_all_children() { foreach (child; children) child.hide(); }

    inout(Element[]) get_children() inout { return children; }

    bool is_parent_of(in Element chi) const { return geom is chi.geom.parent; }

/*  bool is_mouse_here() const;
 *
 *  void req_draw();
 *
 *      Require a redraw of the element and all its children, because some
 *      data of the element has changed.
 *
 *  bool add_child   (Element e);
 *  bool add_children(Element[] ...);
 *  bool rm_child    (Element e);
 *
 *      The children are a set, you can have each child only once in there.
 *      The functions return true if the set of children has been changed,
 *      i.e., if the add added a new child, or the rm has found its arg.
 *
 *      The argument must be mutable, since e.geom.parent will be set.
 *
 *      add_children(Element[] ...) returns true iff all individual calls
 *      to add_child() return true.
 *
 *  final void calc();
 *  final void work();
 *  final void draw();
 *  final void undraw();
 *
 *      draw() and undraw() assume that you've selected the correct target
 *      bitmap! In the best scenario, these are only called by gui.root.
 *      Register your important gui elements as elders or focus elements there.
 */

protected:

    // override these
    void calc_self()   { } // do computations when GUI element has focus
    void work_self()   { } // do computations always, even when not in focus
    void draw_self()   { } // draw to the screen, this calls geom.get_xs() etc.

/*  void undraw_self();    // Called if appropriate before drawing. This
 *                            is implemented, you can override, don't have to.
 *
 *  static final void draw_3d_rectangle(xs, ys, xls, yls, col, col, col)
 *
 *      Used by subclasses Frame, Button, Window. The 2nd color can be transp,
 *      then that is ignored.
 *
 *      I wanted to use a Geom object for the coordinates, but that gave
 *      rounding errors with class gui.frame.Frame.
 */


private:

    Geom geom;
    bool hidden;
    AlCol undraw_color; // if != color.transp, then undraw

    bool drawn;
    bool draw_required;

    Element[] children;



public:

this(in int x = 0, in int y = 0, in int xl = 20, in int yl = 20)
{
    this(Geom.From.TOP_LEFT, x, y, xl, yl);
}



this(in Geom.From from, in int x  = 0,  in int  y =  0,
                        in int xl = 20, in int yl = 20)
{
    geom          = new Geom(from, x, y, xl, yl);
    undraw_color  = color.transp;
    draw_required = true;
}



~this()
{
    foreach (child; children) {
        assert (child.geom.parent is this.geom,
            "upon destruction, child without properly-set parent exists");
        child.geom.parent = null;
    }
}



bool add_child(Element e)
{
    if (children.find!"a is b"(e) != []) return false;
    if (e.geom.parent !is null) return false;

    e.geom.parent = this.geom;
    children ~= e;
    return true;
}



bool add_children(Element[] elements ...)
{
    bool ret = true;
    foreach (e; elements) ret = add_child(e) && ret;
    return ret;
}



bool rm_child(Element e)
{
    auto found = children.find!"a is b"(e);
    if (found == []) return false;

    auto fe = found[0];
    assert (fe.geom.parent is this.geom,
        "gui element in child list without its parent set");
    fe.geom.parent = null;
    // remove(n) removes the item with index n. We wish to remove fe.
    children.remove(children.length - found.length);
    return true;
}



void
req_draw()
{
    draw_required = true;
    foreach (child; children) child.draw_required = true;
}




bool is_mouse_here() const
{
    if (! hidden
     && get_mx() >= xs && get_mx() < xs + xls
     && get_my() >= ys && get_my() < ys + yls) return true;
    else return false;
}



final void calc()
{
    if (hidden) return;
    foreach (child; children) child.calc_self();
    calc_self();
}



final void work()
{
    if (hidden) return;
    foreach (child; children) child.work_self();
    work_self();
}



final void draw()
{
    if (! hidden) {
        if (draw_required) {
            draw_required = false;
            draw_self();
            drawn = true;
        }
        // In the options menu, all stuff has to be undrawn first, then
        // drawn, so that rectangles don't overwrite proper things.
        // Look into this function (final void draw) below.
        foreach (c; children) if (c.get_hidden())   c.draw();
        foreach (c; children) if (! c.get_hidden()) c.draw();
    }
    // hidden
    else
        undraw();
}



final void undraw()
{
    if (drawn) {
        if (undraw_color != color.transp) undraw_self();
        drawn = false;
    }
    draw_required = ! hidden;
}



void undraw_self()
{
    al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, undraw_color);
}



static final void
draw_3d_button(
    float xs, float ys, float xls, float yls,
    in AlCol top, in AlCol mid, in AlCol bot
) {
    alias al_draw_filled_rectangle rf;

    foreach (int i; 0 .. Geom.thicks) {
        rf(xs      +i, ys    +1+i, xs    +1+i, ys+yls-1-i, top); // left
        rf(xs    +1+i, ys      +i, xs+xls-1-i, ys    +1+i, top); // top
        rf(xs+xls-1-i, ys    +1+i, xs+xls  -i, ys+yls-1-i, bot); // right
        rf(xs    +1+i, ys+yls-1-i, xs+xls-1-i, ys+yls  -i, bot); // bttom

        // draw single pixels in the corners where same-colored strips meet
        rf(xs      +i, ys      +i, xs  +1+i, ys  +1+i, top);
        rf(xs+xls-1-i, ys+yls-1-i, xs+xls-i, ys+yls-i, bot);
    }
    if (mid != color.transp) {
        // draw single pixels in the bottom-left and top-right corners
        foreach (int i; 0 .. Geom.thicks) {
            rf(xs      +i, ys+yls-1-i, xs  +1+i, ys+yls-i, mid);
            rf(xs+xls-1-i, ys      +i, xs+xls-i, ys  +1+i, mid);
        }
        // draw the large interior
        alias Geom.thicks i;
        rf(xs + i, ys + i, xs + xls - i, ys + yls - i, mid);
    }
}

}
// end class
