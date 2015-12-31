module gui.butbit;

import std.conv; // to!int for drawing the cutbit

import basics.globals; // name of checkmark bitmap
import graphic.cutbit;
import graphic.gralib;
import gui;

class BitmapButton : Button {

    this(Geom g, const(Cutbit) cb)
    {
        super(g);
        _cbe = new CutbitElement(new Geom(0, 0, xlg, ylg, From.CENTER), cb);
        addChild(_cbe);
    }

    @property int xf(in int i) { reqDraw(); return _cbe.xf = i; }
    @property int xf()  const  { return _cbe.xf;  }
    @property int xfs() const  { return _cbe.xfs; }

private:

    CutbitElement _cbe;

protected:

    override void drawOntoButton()
    {
        _cbe.yf = (this.on && ! this.down) ? 1 : 0;
        // Force drawing _cbe right now, even though it's a child and would be
        // drawn later otherwise. The graphic must go behind the button hotkey
        // that is drawn in final super.drawSelf().
        _cbe.draw();
    }
}
// end class BitmapButton



class Checkbox : BitmapButton {

    this(Geom g)
    {
        g.xl = 20;
        g.yl = 20;
        super(g, getInternal(fileImageMenuCheckmark));
        this.onExecute = (){ this.toggle; };
    }

    @property bool checked(bool b) { xf = (b ? xfCheckmark : 0);
                                     reqDraw(); return b; }
    @property bool checked() const { return xf == xfCheckmark;   }
    bool toggle()                  { return checked = ! checked; }

    private enum xfCheckmark = 2;

}
// end class Checkbox
