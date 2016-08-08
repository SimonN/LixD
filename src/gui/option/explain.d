module gui.option.explain;

// The wide rectangle that explains hovered options in the options menu.

import std.algorithm;

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
            return new Label(new Geom(Geom.thickg, y, xlg-2*Geom.thickg, 20));
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
        if (opt is null) {
            _lines.each!(line => line.hide());
            return;
        }
        auto range = opt.explain().splitter('|');
        foreach (line; _lines) {
            if (range.empty)
                line.hide();
            else {
                line.show();
                line.text = range.front;
                range.popFront();
            }
        }
    }

protected:
    // Complete repaint of our area
    override void drawSelf() { undrawSelf(); }
}
