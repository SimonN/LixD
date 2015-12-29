module gui.window;

/* The Window class. Many windows derive from this.
 *
 *  override void hideAllChildren(bool)
 *
 *      Does not hide the title bar, but all other children.
 */

import gui;
import graphic.color;

class Window : Element {

    static immutable titleYlg = 20;

    this(Geom g, string ti = "")
    {
        super(g);
        labelTitle = new Label(new Geom(0, 0, xlg, titleYlg, From.TOP));
        labelTitle.color = color.white;
        _title = ti;

        addChild(labelTitle);
        prepare();
    }

    @property torbit()         const   { return guiosd;    }
    @property windowTitle()    const   { return _title;    }
    @property windowSubtitle() const   { return _subtitle; }
    @property windowTitle   (string s) { _title    = s; prepare(); return s; }
    @property windowSubtitle(string s) { _subtitle = s; prepare(); return s; }

    override void hideAllChildren()
    {
        foreach (child; children)
            if (child !is labelTitle)
                child.hidden = true;
    }

private:

    string _title;
    string _subtitle;

    Label  labelTitle;

    void prepare()
    {
        labelTitle.text = _subtitle.length
            ? _title ~ " \u2013 " ~ _subtitle // unicode glyph is the en-dash
            : _title;
        reqDraw();
    }



protected:

    override void drawSelf()
    {
        // the main area
        draw3DButton(xs, ys, xls, yls,
            color.guiL, color.guiM, color.guiD);

        // the title bar
        // title label is drawn automatically afterwards, because it's a child
        draw3DButton(xs, ys, xls, labelTitle.yls,
            color.guiOnL, color.guiOnM, color.guiOnD);
    }

}
// end class Window
