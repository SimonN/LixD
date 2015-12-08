module gui.butskill;

import gui;
import graphic.color;
import graphic.gralib;
import graphic.graphic;
import graphic.textout; // select small font
import lix.enums;

class SkillButton : Button {

public:

    this(Geom g)
    {
        super(g);
        style = Style.garden;
        whenToExecute = WhenToExecute.whenMouseHeld;

        _labelNumL = new Label(new Geom(0, 2, g.xlg, 30, From.TOP));
        _labelNumL.color = color.white;
        _labelNumL.font  = djvuL;

        _labelNumM = new Label(new Geom(0, 3, g.xlg, 20, From.TOP));
        _labelNumM.color = color.white;
        _labelNumM.font  = djvuM;

        _label_hotkey = new Label(new Geom(0, 0, g.xlg, 20, From.BOT_RIG));
        _label_hotkey.font = graphic.textout.djvuS;
        addChildren(_labelNumL, _labelNumM, _label_hotkey);
    }

    @property Ac skill() const { return _skill; }
    @property Ac skill(in Ac a)
    {
        if (_skill == a)
            return a;
        reqDraw();
        return _skill = a;
    }

    @property string hotkey_label() const { return _label_hotkey.text; }
    @property string hotkey_label(in string s)
    {
        if (s == _label_hotkey.text)
            return s;
        reqDraw();
        return _label_hotkey.text = s;
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
            _labelNumL.text = "\u2135\u2080"; // aleph-null
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
        _icon = new Graphic(getSkillButtonIcon(_style), gui.guiosd);
        reqDraw();
        return st;
    }

private:

    Style _style = Style.max;
    int _number;
    Ac  _skill;

    Graphic _icon;
    Label   _labelNumL;
    Label   _labelNumM;
    Label   _label_hotkey;

protected:

    override void calcSelf()
    {
        super.calcSelf();
        down = false;
    }

    override void drawSelf()
    {
        super.drawSelf();
        _icon.x  = this.xs +   this.xls/2 - _icon.xl/2;
        _icon.y  = this.ys + 2*this.yls/3 - _icon.yl/2;
        _icon.yf = _number == 0 ? 1 : 0; // 0 == colorful, 1 == greyed out
        _icon.xf = _skill;
        _icon.draw(guiosd);
    }

}
// end class SkillButton
