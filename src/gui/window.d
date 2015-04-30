module gui.window;

/* The Window class. Many windows derive from this.
 *
 *  override void hide_all_children(bool)
 *
 *      Does not hide the title bar, but all other children.
 */

import gui;
import graphic.color;

class Window : Element {

    static immutable title_ylg = 20;

    this(Geom g, string ti = "")
    {
        super(g);
        label_title = new Label(new Geom(0, 0, xlg, title_ylg, From.TOP));
        label_title.color = color.white;
        _title = ti;

        add_child(label_title);
        prepare();
    }

    @property auto torbit()   const   { return guiosd;    }
    @property auto title()    const   { return _title;    }
    @property auto subtitle() const   { return _subtitle; }
    @property void title   (string s) { _title    = s; prepare(); }
    @property void subtitle(string s) { _subtitle = s; prepare(); }

    override void hide_all_children()
    {
        foreach (child; children)
            if (child !is label_title)
                child.hidden = true;
    }

private:

    string _title;
    string _subtitle;

    Label  label_title;

    void prepare()
    {
        label_title.text = subtitle.length ? title ~ " - " ~ subtitle : title;
        req_draw();
    }



protected:

    override void draw_self()
    {
        // the main area
        draw_3d_button(xs, ys, xls, yls,
            color.gui_l, color.gui_m, color.gui_d);

        // the title bar
        // title label is drawn automatically afterwards, because it's a child
        draw_3d_button(xs, ys, xls, label_title.yls,
            color.gui_on_l, color.gui_on_m, color.gui_on_d);
    }

}
// end class Window
