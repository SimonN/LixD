module gui.button.skill;

public import net.ac;
public import net.style;

import gui;
import graphic.color;
import graphic.internal;

class SkillOrScissorsButton : Button {
private:
    CutbitElement _iconOrNull;
    Label _big;
    Label _med;

public:
    this(Geom g)
    do {
        super(g);
        _big = new Label(new Geom(0, 2, xlg, 30, From.TOP));
        _big.font = djvuL;
        _big.color = color.white;
        _med = new Label(new Geom(0, 3, xlg, 20, From.TOP));
        _med.font = djvuM;
        _med.color = color.white;
        addChildren(_big, _med);
    }

    abstract bool available() const pure nothrow @safe @nogc;

protected:
    inout(Label) largeLabel() inout pure nothrow @safe @nogc { return _big; }
    inout(Label) mediumLabel() inout pure nothrow @safe @nogc { return _med; }

    IconT replaceIcon(IconT, Args...)(Args args)
        if (is (IconT : CutbitElement))
    {
        if (_iconOrNull !is null)
            rmChild(_iconOrNull);
        auto ret = new IconT(new Geom(0, 0, xlg, ylg * 2f / 3f, From.BOTTOM),
            args);
        _iconOrNull = ret;
        addChild(_iconOrNull);
        return ret;
    }

    final override string hotkeyString() const
    {
        return available ? super.hotkeyString() : null;
    }

    final override void drawOntoButton()
    {
        if (_iconOrNull is null) {
            return;
        }
        _iconOrNull.yf = 1 - available; // 0 == colorful, 1 == greyed out
        _iconOrNull.draw(); // see comment in BitmapButton.drawOntoButton()
    }
}

class SkillButton : SkillOrScissorsButton {
private:
    Style _style = Style.max;
    int _number;
    Ac  _skill;
    SkillIcon _icon; // The very same object as in SkillOrScissorsButton.

public:
    this(Geom g, Style sty = Style.garden)
    {
        super(g);
        whenToExecute = WhenToExecute.whenMouseHeld;
        style = sty;
    }

    override bool available() const pure nothrow @safe @nogc
    {
        return _number != 0;
    }

    Ac skill() const pure nothrow @safe @nogc { return _skill; }
    void skill(in Ac a) pure nothrow @safe @nogc
    {
        if (_skill == a)
            return;
        _skill = a;
        _icon.ac = _skill;
        reqDraw();
    }

    int number() const pure nothrow @safe @nogc { return _number; }
    void number(in int i) nothrow @safe
    {
        assert (i >= 0 || i == skillInfinity);
        if (_number == i)
            return;
        _number = i;
        if (_number == skillInfinity) {
            largeLabel.text = "\u221E"; // lemniscate
            mediumLabel.text = "";
        }
        else if (_number >= 100) {
            largeLabel.text = "";
            mediumLabel.number = _number;
        }
        else if (_number >= 1) {
            largeLabel.number = _number;
            mediumLabel.text = "";
        }
        else if (number == 0) {
            largeLabel.text = "";
            mediumLabel.text = "";
            on = false;
        }
        reqDraw();
    }

    Style style() const pure nothrow @safe @nogc { return _style; }
    void style(in Style st)
    {
        assert (st != Style.max);
        if (_style == st)
            return;
        _style = st;
        _icon = replaceIcon!SkillIcon(_style);
        _icon.ac = _skill;
        reqDraw();
    }
}
