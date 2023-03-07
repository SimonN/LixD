module gui.option.explain;

// The wide rectangle that explains hovered options in the options menu.

import std.algorithm;

import optional;

import file.language;
import gui;

class Explainer : Element {
private:
    Frame _frame;
    Label[2] _lines;
    Optional!Lang _currentlyExplained;

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

    void explainNothing()
    {
        if (_currentlyExplained.empty) {
            return;
        }
        _currentlyExplained = no!Lang;
        reqDraw();
        foreach (line; _lines) {
            line.hide();
        }
    }

    void explain(Lang lang)
    {
        if (lang == _currentlyExplained) {
            return;
        }
        _currentlyExplained = lang;
        reqDraw();
        auto range = lang.descr[];
        foreach (line; _lines) {
            if (range.length == 0) {
                line.hide();
            }
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
