module gui.option.explain;

// The wide rectangle that explains hovered options in the options menu.

import std.algorithm;

import file.language;
import gui;
import gui.option.base;

class Explainer : Element {
private:
    Frame _frame;
    Label[2] _lines;
    Option _alreadyExplained = null;

public:
    this(Geom g)
    {
        Label newExplainerLine(in int y)
        {
            return new Label(new Geom(gui.thickg, y, xlg-2*gui.thickg, 20));
        }
        super(g);
        _frame = new Frame(new Geom(0, 0, xlg, ylg));
        _lines[0] = newExplainerLine(0);
        _lines[1] = newExplainerLine(20);
        addChildren(_frame, _lines[0], _lines[1]);
    }

    void explain(Option opt)
    {
        if (opt is _alreadyExplained)
            return;
        _alreadyExplained = opt;
        reqDraw();
        auto range = opt !is null ? opt.lang.descr[] : [];
        foreach (line; _lines) {
            if (range.length == 0)
                line.hide();
            else {
                line.show();
                line.text = range[0];
                range = range[1 .. $];
            }
        }
    }

protected:
    // Complete repaint of our area
    override void drawSelf() { undrawSelf(); }
}
