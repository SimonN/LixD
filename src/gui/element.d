module gui.element;

import std.algorithm;
import std.string; // format, for string mixin GetSetWithDrawReq

import basics.alleg5;
import graphic.color;
import gui;
import hardware.mouse; // isMouseHere

abstract class Element : IRoot {
private:
    Geom  _geom;
    bool  _hidden;
    AlCol _undrawColor; // if != color.transp, then undraw
    Element[] _children;
    bool drawn;
    bool drawRequired;

public:
    this(Geom g)
    {
        _geom        = g;
        _undrawColor = color.guiM;
        drawRequired = true;
    }

    // these functions return the position/length in geoms. See geometry.d
    // for the difference between measuring in geoms and in screen pixels.
    @property float xg()  const { return _geom.xg;  }
    @property float yg()  const { return _geom.yg;  }
    @property float xlg() const { return _geom.xlg; }
    @property float ylg() const { return _geom.ylg; }

    @property float xs()  const { return _geom.xs;  }
    @property float ys()  const { return _geom.ys;  }
    @property float xls() const { return _geom.xls; }
    @property float yls() const { return _geom.yls; }

    // to edit the geom, use Element.move(x, y) and Element.resize(xl, yl).
    @property const(Geom) geom() const { return _geom; }

    @property AlCol undrawColor() const  { return _undrawColor;     }
    @property AlCol undrawColor(AlCol c) { return _undrawColor = c; }

    final void hide() { hidden = true;  }
    final void show() { hidden = false; }
    @property bool hidden() const { return _hidden; }
    @property bool hidden(in bool b) // virtual, b/c Button overrides this :-[
    {
        if (b != _hidden) {
            reqDraw();
            _hidden = b;
        }
        return _hidden;
    }

    // The children are a set, you can have each child only once in there.
    // The argument must be mutable, since e.geom.parent will be set.
    void addChildren(Element[] elems...) { elems.each!(e => addChild(e)); }
    void addChild(Element e)
    {
        assert (e !is null, "can't add null child");
        assert (_children.find!"a is b"(e) == [], "child was added before");
        assert (e._geom.parent is null, "child has a parent already");
        e._geom.parent = this._geom;
        _children ~= e;
    }

    void rmAllChildren() { while (_children.length) rmChild(_children[0]); }
    void rmChild(Element e)
    {
        assert (e !is null, "can't rm null child");
        auto found = _children.find!"a is b"(e);
        assert (found != [], "child doesn't exist, can't be removed");
        assert (found[0]._geom.parent is this._geom,
            "gui element in child list without its parent set");
        found[0]._geom.parent = null;
        // remove(n) removes the item with index n. We wish to remove fe.
        _children = _children.remove(_children.length - found.length);
    }

    void hideAllChildren() { _children.each!(e => e.hide()); }
    @property inout(Element[]) children() inout { return _children; }
    bool isParentOf(in Element ch) const { return _geom is ch._geom.parent; }

    void move(in float ax, in float ay)
    {
        if (_geom.x == ax && _geom.y == ay)
        reqDraw();
        _geom.x = ax;
        _geom.y = ay;
    }

    final void resize(in float axl, in float ayl)
    {
        if (_geom.xl == axl && _geom.yl == ayl)
            return;
        reqDraw();
        _geom.xl = axl;
        _geom.yl = ayl;
        resizeSelf();
    }

    // Require a redraw of the element and all its children, because some
    // data of the element has changed.
    void reqDraw()
    {
        drawRequired = true;
        foreach (child; _children)
            child.reqDraw();
    }

    bool isMouseHere() const
    {
        return ! _hidden && mouseX() >= xs && mouseX() < xs + xls
                         && mouseY() >= ys && mouseY() < ys + yls;
    }

    final void calc()
    {
        if (_hidden) return;
        _children.each!(c => c.calc);
        calcSelf();
    }

    final void work()
    {
        _children.each!(c => c.work);
        workSelf();
    }

    // draw() and undraw() assume that you've selected the correct target
    // bitmap! In the best scenario, these are only called by gui.root.
    // Register your important gui elements as elders or focus elements there.
    final void draw()
    {
        if (! _hidden) {
            if (drawRequired) {
                drawSelf();
                drawRequired = false;
                drawn = true;
            }
            // In the options menu, all stuff has to be undrawn first, then
            // drawn, so that rectangles don't overwrite proper things.
            // Look into this function (final void draw) below.
            foreach (c; _children) if (  c.hidden) c.draw();
            foreach (c; _children) if (! c.hidden) c.draw();
        }
        // hidden
        else
            undraw();
    }

    final void undraw()
    {
        if (drawn) {
            if (_undrawColor != color.transp)
                undrawSelf();
            drawn = false;
        }
        drawRequired = ! _hidden;
    }

    static final void
    draw3DButton(
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

protected:
    // override these
    void calcSelf() { } // do computations when GUI element has focus
    void workSelf() { } // do computations even when hidden or not in focus
    void drawSelf() { } // draw to the screen, this calls geom.get_xs() etc.

    void resizeSelf() { } // after element has been resized, xlg/ylg is new

    // Sometimes used if appropriate before drawing. You can still override.
    void undrawSelf()
    {
        al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, _undrawColor);
    }
}

template GetSetWithReqDraw(string s)
{
    enum string GetSetWithReqDraw = q{
        @property typeof(_%s) %s() const { return _%s; }
        @property typeof(_%s) %s(in typeof(_%s) arg)
        {
            if (_%s == arg)
                return arg;
            _%s = arg;
            reqDraw();
            return arg;
        }
    }.format(s, s, s, s, s, s, s, s);
}
