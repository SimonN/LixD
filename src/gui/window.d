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

    @property auto torbit()   const   { return guiosd;    }
    @property auto title()    const   { return _title;    }
    @property auto subtitle() const   { return _subtitle; }
    @property void title   (string s) { _title    = s; prepare(); }
    @property void subtitle(string s) { _subtitle = s; prepare(); }

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
        labelTitle.text = subtitle.length ? title ~ " - " ~ subtitle : title;
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
