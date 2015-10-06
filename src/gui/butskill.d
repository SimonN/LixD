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
        style = Style.GARDEN;

        _label_num_l = new Label(new Geom(0, 2, g.xlg, 30, From.TOP));
        _label_num_l.color = color.white;
        _label_num_l.font  = djvu_l;

        _label_num_m = new Label(new Geom(0, 3, g.xlg, 20, From.TOP));
        _label_num_m.color = color.white;
        _label_num_m.font  = djvu_m;

        _label_hotkey = new Label(new Geom(0, 0, g.xlg, 20, From.BOT_RIG));
        _label_hotkey.font = graphic.textout.djvu_s;
        add_children(_label_num_l, _label_num_m, _label_hotkey);
    }

    @property Ac  skill() const { return _skill;                 }
    @property skill(in Ac a)    { req_draw(); return _skill = a; }

    @property hotkey_label(in string s)
    {
        req_draw();
        return _label_hotkey.text = s;
    }

    @property int number() const { return _number; }

    @property int number(in int i)
    {
        assert (i >= 0 || i == lix.enums.skill_infinity);
        _number = i;
        _label_num_l.text = "";
        _label_num_m.text = "";
        if (_number == lix.enums.skill_infinity)
            _label_num_l.text = "\u2135\u2080"; // aleph-null
        else if (_number >= 100)
            _label_num_m.number = _number;
        else if (_number >= 1)
            _label_num_l.number = _number;
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
    Label   _label_num_l;
    Label   _label_num_m;
    Label   _label_hotkey;

protected:

    override void draw_self()
    {
        super.draw_self();
        _icon.x  = this.xs +   this.xls/2 - _icon.xl/2;
        _icon.y  = this.ys + 2*this.yls/3 - _icon.yl/2;
        _icon.yf = ac_to_y_frame(_skill);
        _icon.xf = _number == 0 ? 1 : 0; // 0 == colorful, 1 == greyed out
        _icon.draw();
    }

}
// end class SkillButton
