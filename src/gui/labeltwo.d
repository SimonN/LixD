module gui.labeltwo;

import gui;
import graphic.color;

// Two labels:
// One left-aligned with a permanent caption, normal gui text color,
// Another left-aligned to the right of the first one, varying value, white.

class LabelTwo : Element {
private:
    Label _caption;
    Label _value;

public:
    this(Geom g, string cap)
    {
        super(g);
        _caption = new Label(new Geom(0, 0, xlg, ylg, From.LEFT), cap);
        _value   = new Label(new Geom(_caption.textLg + 6f, 0,
                                xlg - _caption.textLg - 6f, ylg, From.LEFT));
        _caption.color = color.guiOnM; // darker than value's colorText
        _value.undrawBeforeDraw = true;
        addChildren(_caption, _value);
    }

    @property string value(in string s) { return _value.text = s; }
    @property int    value(in int i)    { _value.number = i; return i; }
}
