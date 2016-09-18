module gui.picker.scrolist;

/* This looks like a file picker, but doesn't know about files:
 * It's a scrollable list of anything. The file picker contains this.
 */

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
    body { return null; }

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
