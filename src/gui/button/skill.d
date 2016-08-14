module gui.button.skill;

import gui;
import graphic.color;
import graphic.internal;
import graphic.graphic;
import graphic.textout; // select small font
import lix.enums;

class SkillButton : Button {
private:
    Style _style = Style.max;
    int _number;
    Ac  _skill;

    SkillIcon _icon;
    Label _labelNumL;
    Label _labelNumM;

public:
    this(Geom g, Style sty = Style.garden)
    {
        super(g);
        style = sty;
        whenToExecute = WhenToExecute.whenMouseHeld;

        _labelNumL = new Label(new Geom(0, 2, g.xlg, 30, From.TOP));
        _labelNumL.color = color.white;
        _labelNumL.font  = djvuL;

        _labelNumM = new Label(new Geom(0, 3, g.xlg, 20, From.TOP));
        _labelNumM.color = color.white;
        _labelNumM.font  = djvuM;
        addChildren(_labelNumL, _labelNumM);
    }

    @property Ac skill() const { return _skill; }
    @property Ac skill(in Ac a)
    {
        if (_skill == a)
            return a;
        reqDraw();
        return _skill = a;
    }

    @property int number() const { return _number; }
    @property int number(in int i)
    {
        assert (i >= 0 || i == lix.enums.skillInfinity);
        if (_number == i)
            return i;
        _number = i;
        _labelNumL.text = "";
        _labelNumM.text = "";
        if (_number == lix.enums.skillInfinity)
            _labelNumL.text = "\u221E"; // lemniscate
        else if (_number >= 100)
            _labelNumM.number = _number;
        else if (_number >= 1)
            _labelNumL.number = _number;
        else if (number == 0)
            on = false;
        reqDraw();
        return _number;
    }

    @property Style style() const { return _style; }
    @property Style style(in Style st)
    {
        assert (st != Style.max);
        if (_style == st)
            return st;
        _style = st;

        if (_icon !is null)
            rmChild(_icon);
        _icon = new SkillIcon(new Geom(0, 0, xlg, ylg * 2f / 3f,
            From.BOTTOM), _style);
        addChild(_icon);
        reqDraw();
        return st;
    }

protected:

    override string hotkeyString() const
    {
        if (_number != 0)
            return super.hotkeyString();
        else
            return null;
    }

    override void calcSelf()
    {
        super.calcSelf();
        down = false;
    }

    override void drawOntoButton()
    {
        assert (_icon);
        _icon.yf = _number == 0 ? 1 : 0; // 0 == colorful, 1 == greyed out
        _icon.ac = _skill;
        _icon.draw(); // see comment in BitmapButton.drawOntoButton()
    }

}
// end class SkillButton
