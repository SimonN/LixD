module gui.button.text;

/* A button with text printed on it.
 *
 * The button may have a checkmark on its right-hand side. If present, the
 * maximal length for the text is shortened. Set checkFrame != 0 to get it.
 */

import std.conv;

import gui;
import graphic.color;
import graphic.cutbit;
import graphic.internal;

class TextButton : Button {
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

public:
    static float textXFromLeft()
    {
        // This gui.thickg is in addition to the thicks at left/right
        // from class Label.
        return gui.thickg;
    }

    static Geom newGeomForLeftAlignedLabelInside(in Geom g)
    {
        return new Geom(textXFromLeft, 0, g.xl - textXFromLeft, 0);
    }

    this(Geom g, string caption = "")
    {
        super(g);
        // the text should not be drawn on the 3D part of the button, but only
        // to the uniformly colored center. Each side has a thickness of 2.
        // The checkmark already accounts for this.
        // The checkmark is at the right of the button, for all text aligns.
        alias th  = textXFromLeft;
        alias ctr = Geom.From.CENTER;
        left        = new Label(newGeomForLeftAlignedLabelInside(g));
        leftCheck   = new Label(new Geom(th, 0, g.xl - th-chXlg, 0));
        center      = new Label(new Geom(0, 0, g.xl, 0, ctr));
        centerCheck = new Label(new Geom(0, 0, g.xl - 2*chXlg, 0, ctr));
        // See override this.onResize for copypasta

        checkGeom = new Geom(0, 0, chXlg, chXlg, Geom.From.RIGHT);
        checkGeom.parent = this.geom;

        addChildren(left, leftCheck, center, centerCheck);
        text = caption;
    }

    bool alignLeft() const { return _alignLeft; }
    bool alignLeft(bool b)
    {
        if (_alignLeft == b)
            return b;
        _alignLeft = b;
        reqDraw();
        return _alignLeft;
    }

    string text() const { return _text; }
    string text(in string s)
    {
        if (_text == s)
            return s;
        _text = s;
        reqDraw();
        return s;
    }

    int checkFrame() const { return _checkFrame; }
    int checkFrame(int i)
    {
        if (_checkFrame == i)
            return i;
        _checkFrame = i;
        reqDraw();
        return _checkFrame;
    }

protected:
    override void drawOntoButton()
    {
        auto labelList = [ center, centerCheck, left, leftCheck ];
        foreach (label; labelList)
            label.text = "";
        with (labelList[_alignLeft * 2 + (_checkFrame != 0)]) {
            text  = this._text;
            color = this.colorText();
        }

        // Draw the checkmark, which doesn't overlap with the children.
        // There's a (chXlg)x(chXlg) area reserved for the cutbit on the right.
        // Draw to the center of this square.
        if (_checkFrame != 0) {
            const cb = InternalImage.menuCheckmark.toCutbit;
            cb.draw(Point(to!int(checkGeom.xs + checkGeom.xls/2 - cb.xl/2),
                          to!int(checkGeom.ys + checkGeom.yls/2 - cb.yl/2)),
                _checkFrame, 2 * (on && ! down)
            );
        }
    }

    override void resizeSelf()
    {
        // See constructor for copypasta
        alias th  = textXFromLeft;
        left       .resize(xlg - th, left.ylg);
        leftCheck  .resize(xlg - th - chXlg, leftCheck.ylg);
        center     .resize(xlg, center.ylg);
        centerCheck.resize(xlg - 2 * chXlg, centerCheck.ylg);
    }
}
