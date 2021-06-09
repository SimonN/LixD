module gui.picker.scrolist;

import std.algorithm;
import std.math;
import std.conv;

import gui;
import gui.picker.scrollb;

// Use this interface, then a ScrolledList can work with you
interface IScrollable {
public:
    // Mouse wheel should scroll this many entries of size 1.
    // We don't scroll ourselves, The scrollbar checks the mouse wheel.
    // Coarseness suggests to always scroll in multiples of this size,
    // even if we leave empty space at the bottom of the list. Mouse wheel
    // speed should be a multiple of coarseness.
    @property int wheelSpeed() const;
    @property int coarseness() const;

    @property int pageLen() const;
    @property int totalLen() const;

    @property int top() const;
    @property int top(int newTop);
}

// ############################################################################

/*
 * This looks like a file picker, but doesn't know about files:
 * It's a scrollable list of anything. The file picker contains this.
 */
abstract class ScrolledList : Element {
private:
    Frame _frame;
    Scrollbar _scrollbar;

public:
    this(Geom g)
    {
        super(g);
        _frame = new Frame(new Geom(0, 0, xlg, ylg));
        _scrollbar = new Scrollbar(new Geom(xlg - 20f, 0, 20, ylg));
        addChildren(_frame, _scrollbar);
    }

protected:
    // This should behave like a this.member, but the subclass can put more
    // interesting classes here. Subclass should add the tiler as its
    // child, we don't do that anywhere.
    abstract @property inout(IScrollable) tiler() inout
    out (ret) { assert (ret !is null); }
    do { return null; }

    // Subclass should instantiate their tiler with this geom, then make
    // inout(Tiler) tiler() inout return that new tiler.
    Geom newGeomForTiler() const { return new Geom(0, 0, xlg - 20f, ylg); }

    override void workSelf()
    {
        // We expect that subclasses change the tiler. Catch changes.
        _scrollbar.pageLen    = tiler.pageLen;
        _scrollbar.totalLen   = tiler.totalLen;
        _scrollbar.coarseness = tiler.coarseness;
        _scrollbar.wheelSpeed = tiler.wheelSpeed;
        // The scrollbar can take focus, to disable everything else while
        // dragging the car. Only we should update our view for it.
        if (_scrollbar.execute)
            tiler.top = _scrollbar.pos;
        else
            _scrollbar.pos = tiler.top;
    }

    override void drawSelf() { _frame.undraw(); }
    override void undrawSelf() { _frame.undraw(); } // frame bigger than this.
}

// ############################################################################

/*
 * This has a scrollbar, and it's scrollable itself.
 * Normally, we'd use a Picker, who owns and mediates between a ScrolledList,
 * an Ls, and a Tiler to fill the ScrolledList. But sometimes, it's handy
 * to have a standalone button-filled list without a tiler attached.
 */
abstract class ScrollableButtonList : ScrolledList, IScrollable {
private:
    Button[] _buttons;
    int _top;

public:
    enum float buttonYlg = 20f;

    this(Geom g) { super(g); }

    @property int wheelSpeed() const { return pageLen() <= 10 ? 3 : 5; }
    @property int coarseness() const { return 1; }
    @property int pageLen() const { return (ylg / buttonYlg).floor.to!int; }
    @property int totalLen() const { return _buttons.length.to!int; }
    @property int top() const { return _top; }
    @property int top(int newTop)
    {
        newTop = max(0, min(newTop, totalLen - pageLen));
        if (newTop == _top)
            return _top;
        _top = newTop;
        alignButtons();
        return _top;
    }

protected:
    final override @property inout(IScrollable) tiler() inout { return this; }

    @property const(Button[]) buttons() const { return _buttons; }

    void replaceAllButtons(Button[] array)
    {
        _buttons.each!(b => rmChild(b));
        _buttons = array;
        _buttons.each!(b => addChild(b));
        // We would like to keep our scrolling position roughly the same.
        // top = top is not perfect, it errs towards scrolling too low
        // when buttons vanish, and too high when extra buttons appear
        top = top;
        alignButtons();
    }

    Geom newGeomForButton() const
    {
        auto g = newGeomForTiler();
        // We don't set the y-position. Call alignButtons() for that.
        g.yl = buttonYlg;
        return g;
    }

private:
    void alignButtons()
    {
        reqDraw();
        foreach (const size_t i, b; _buttons) {
            b.shown = (i >= _top && i < _top + pageLen);
            if (b.shown)
                b.move(0, (i - _top) * buttonYlg);
        }
    }
}
