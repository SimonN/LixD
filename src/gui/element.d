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
    bool  _shown = true;
    Alcol _undrawColor; // if != color.transp, then undraw
    Element[] _children;
    bool drawn;
    bool drawRequired = true;

public:
    this(Geom g)
    {
        _geom        = g;
        _undrawColor = color.gui.m;
    }

    const nothrow @safe @nogc {
        // Return the position/length in geoms. See geometry.d
        // for the difference between measuring in geoms and in screen pixels.
        float xg() { return _geom.xg;  }
        float yg() { return _geom.yg;  }
        float xlg() pure { return _geom.xlg; }
        float ylg() pure { return _geom.ylg; }

        // Return position/length in screen pixels.
        float xs() { return _geom.xs;  }
        float ys() { return _geom.ys;  }
        float xls() { return _geom.xls; }
        float yls() { return _geom.yls; }
    }

    // to edit the geom, use Element.move(x, y) and Element.resize(xl, yl).
    const(Geom) geom() const pure nothrow @safe @nogc { return _geom; }

    Alcol undrawColor() const  { return _undrawColor;     }
    Alcol undrawColor(Alcol c) { return _undrawColor = c; }

    final void hide() pure nothrow @nogc { shown = false; }
    final void show() pure nothrow @nogc { shown = true; }

    // Both have to be virtual because Button overrides one >_>
    bool shown() const pure nothrow @nogc { return _shown; }
    bool shown(in bool b) pure nothrow @nogc
    {
        if (b != _shown) {
            reqDraw();
            _shown = b;
        }
        return _shown;
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

    inout(Element[]) children() inout pure nothrow @safe @nogc
    {
        return _children;
    }

    bool isParentOf(in Element ch) const pure nothrow @safe @nogc
    {
        return _geom is ch._geom.parent;
    }

    void move(in float ax, in float ay)
    {
        if (_geom.x == ax && _geom.y == ay)
            return;
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

    // Require a redraw because some data of the element has changed,
    // or because things that would be drawn below need a redraw.
    void reqDraw() nothrow pure @safe @nogc
    {
        drawRequired = true;
        _children.each!(c => c.reqDraw);
    }

    bool isMouseHere() const nothrow @safe @nogc
    {
        return _shown && mouseX() >= xs && mouseX() < xs + xls
                      && mouseY() >= ys && mouseY() < ys + yls;
    }

    final void calc()
    {
        if (! _shown)
            return;
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
    // Returns true iff this/any children recursively needed to be drawn.
    final bool draw()
    {
        if (_shown) {
            bool ret = false;
            if (drawRequired) {
                drawSelf();
                drawRequired = false;
                drawn = true;
                ret = true;
            }
            // In the options menu, all stuff has to be undrawn first, then
            // drawn, so that rectangles don't overwrite proper things.
            // Look into this function (final void draw) below.
            foreach (c; _children) if (! c.shown) ret = c.draw() || ret;
            foreach (c; _children) if (  c.shown) ret = c.draw() || ret;
            return ret;
        }
        // element is hidden, i.e., not shown
        else
            return undraw();
    }

    // Returns true if this drew things.
    final bool undraw()
    {
        bool ret = false;
        if (drawn && _undrawColor != color.transp) {
            undrawSelf();
            ret = true;
        }
        drawn = false;
        drawRequired = _shown;
        return ret;
    }

    final void forceUndrawToTransparent()
    {
        with (BlenderMinus) {
            al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, color.white);
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

template GetSetWithReqDraw(string s, string setterQualifiers = "")
{
    enum string GetSetWithReqDraw = q{
        typeof(_%s) %s() const pure nothrow @safe @nogc
        {
            return _%s;
        }

        typeof(_%s) %s(in typeof(_%s) arg) %s
        {
            if (_%s == arg)
                return arg;
            _%s = arg;
            reqDraw();
            return arg;
        }
    }.format(s, s, s, s, s, s, setterQualifiers, s, s);
}
