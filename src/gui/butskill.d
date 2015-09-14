module gui.butskill;

import gui;
import graphic.gralib;
import graphic.graphic;
import graphic.textout; // select small font
import lix.enums;

class SkillButton : Button {

public:

    this(Geom g)
    {
        super(g);
        style = Style.GARDEN;

        _label_number = new Label(new Geom(0, 0, g.xlg,  0, From.TOP    ));
        _label_hotkey = new Label(new Geom(0, 0, g.xlg, 20, From.BOT_RIG));
        _label_hotkey.font = graphic.textout.djvu_s;
        add_children(_label_number, _label_hotkey);
    }

    @property Ac  skill() const { return _skill;                 }
    @property skill(in Ac a)    { req_draw(); return _skill = a; }

    @property hotkey_label(in string s)
    {
        req_draw();
        return _label_hotkey.text = s;
    }

    @property int number() const { return _number; }

    @property number(in int i)
    {
        _number = i;
        if (_number == 0)
            _label_number.text = "";
        else if (_number == lix.enums.skill_infinity)
            _label_number.text = "*";
        else
            _label_number.number = _number;
        req_draw();
        return _number;
    }

    @property style(in Style style)
    {
        _icon = new Graphic(get_lix(style), gui.guiosd);
        req_draw();
    }

private:

    int _number;
    Ac  _skill;

    Graphic _icon;
    Label   _label_number;
    Label   _label_hotkey;

protected:

    override void draw_self()
    {
        super.draw_self();
        _icon.x  = this.xs +   this.xls/2 - _icon.xl/2;
        _icon.y  = this.ys + 2*this.yls/3 - _icon.yl/2;
        _icon.yf = ac_to_y_frame(_skill);
        _icon.xf = (_skill == Ac.NOTHING || _number == 0) ? 1 : 0;
        _icon.draw();
    }

}
