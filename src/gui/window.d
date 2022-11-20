module gui.window;

/* The Window class. Many windows derive from this.
 */

import gui;
import graphic.color;

class Window : Element {
private:
    Label _labelTitle;

public:
    enum titleYlg = 20;

    this(Geom g, string ti = "")
    {
        super(g);
        _labelTitle = new Label(new Geom(0, 0, xlg, titleYlg, From.TOP));
        _labelTitle.color = color.white;
        _labelTitle.text = ti;
        addChild(_labelTitle);
    }

    @property torbit() const { return guiosd; }
    @property windowTitle() const { return _labelTitle.text; }
    @property windowTitle(string s)
    {
        _labelTitle.text = s;
        reqDraw();
    }

protected:
    override void drawSelf()
    {
        // the main area
        draw3DButton(xs, ys, xls, yls, color.gui);
        // the title bar
        // title label is drawn automatically afterwards, because it's a child
        draw3DButton(xs, ys, xls, _labelTitle.yls, color.guiOn);
    }
}
// end class Window
