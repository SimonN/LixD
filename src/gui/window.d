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

    this(in int x  = 0,   in int y  =   0,
         in int xl = 640, in int yl = 480,
         in string ti = "")
    {
        this(Geom.From.CENTER, x, y, xl, yl);
    }

    this(Geom.From from,
        in int x  = 0,   in int y  =   0,
        in int xl = 640, in int yl = 480,
        in string ti = "")
    {
        super(from, x, y, xl, yl);
        label_title = new Label(Geom.From.TOP, 0, 0, xl);
        label_title.color = color.white;
        title = ti;

        add_child(label_title);
    }

    @property torbit()   const   { return guiosd;    }
    @property title()    const   { return _title;    }
    @property subtitle() const   { return _subtitle; }
    @property title   (string s) { _title    = s; req_draw(); }
    @property subtitle(string s) { _subtitle = s; req_draw(); }

    @property exit() const       { return _exit; }
    @property exit(bool b)
    {
        _exit = b;
        if (_exit)
            gui.rm_focus(this);
    }

    override void hide_all_children()
    {
        foreach (child; get_children())
            if (child !is label_title)
                child.set_hidden();
    }

private:

    bool   _exit;
    string _title;
    string _subtitle;

    Label  label_title;

protected:

    override void draw_self()
    {
        label_title.text = subtitle.length ? title ~ " - " ~ subtitle : title;

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
