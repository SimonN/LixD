module gui.buttext;

/* A button with text printed on it.
 *
 * The button may have a checkmark on its right-hand side. If present, the
 * maximal length for the text is shortened. Set checkFrame != 0 to get it.
 */

import std.conv;

import gui;
import basics.globals;
import graphic.color;
import graphic.cutbit;
import graphic.gralib;

class TextButton : Button {

    enum textXFromLeft = Geom.thickg * 2; // *2 for nice spacing at ends

    this(Geom g, string caption = "")
    {
        super(g);
        // the text should not be drawn on the 3D part of the button, but only
        // to the uniformly colored center. Each side has a thickness of 2.
        // The checkmark already accounts for this.
        // The checkmark is at the right of the button, for all text aligns.
        alias th  = textXFromLeft;
        alias lef = Geom.From.LEFT;
        alias ctr = Geom.From.CENTER;
        left        = new Label(new Geom(th, 0, g.xl - 2*th,     0, lef));
        leftCheck   = new Label(new Geom(th, 0, g.xl - th-chXlg, 0, lef));
        center      = new Label(new Geom(0,  0, g.xl - 1*th,     0, ctr));
        centerCheck = new Label(new Geom(0,  0, g.xl - 2*chXlg,  0, ctr));

        checkGeom = new Geom(0, 0, chXlg, chXlg, Geom.From.RIGHT);
        checkGeom.parent = this.geom;

        addChildren(left, leftCheck, center, centerCheck);

        if (caption != "")
            text = caption;
    }

    @property bool alignLeft() const { return _alignLeft;                }
    @property bool alignLeft(bool b) { _alignLeft = b; reqDraw();
                                        return _alignLeft;               }

    @property string text() const      { return _text;                   }
    @property string text(in string s) { _text = s; reqDraw(); return s; }

    @property int checkFrame() const { return _checkFrame;               }
    @property int checkFrame(int i)  { _checkFrame = i; reqDraw();
                                       return _checkFrame;               }

    override string toString() const { return "But-`" ~  _text ~ "'";   }

private:

    string _text;
    bool   _alignLeft;
    int    _checkFrame; // frame 0 is empty, then don't draw anything and
                         // don't shorten the text maximal length
    Label left;
    Label leftCheck;
    Label center;
    Label centerCheck;

    Geom  checkGeom;

    static immutable chXlg = 20; // size in geoms of checkbox



protected override void
drawSelf()
{
    super.drawSelf();

    auto labelList = [ center, centerCheck, left, leftCheck ];
    foreach (label; labelList)
        label.text = "";
    with (labelList[_alignLeft * 2 + (_checkFrame != 0)]) {
        text  = this._text;
        color = this.colorText();
    }

    // Draw the checkmark, which doesn't overlap with the children.
    // There's a (chXlg) x (chXlg) area reserved for the cutbit on the right.
    // Draw to the center of this square.
    if (_checkFrame != 0) {
        auto cb = getInternal(fileImageMenuCheckmark);
        cb.draw(guiosd,
            to!int(checkGeom.xs + checkGeom.xls/2 - cb.xl/2),
            to!int(checkGeom.ys + checkGeom.yls/2 - cb.yl/2),
            _checkFrame, 2 * (on && ! down)
        );
    }
}

}; // Klassenende
