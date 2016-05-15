module editor.gui.topology;

import std.algorithm;
import std.math;

import basics.topology;
import basics.user;
import editor.gui.okcancel;
import file.language;
import gui;
import graphic.color;
import level.level;
import tile.occur;

class TopologyWindow : OkCancelWindow {
private:
    immutable int _oldXl;
    immutable int _oldYl;
    NumPick _left;
    NumPick _right;
    NumPick _top;
    NumPick _bottom;
    Equation _horizontalDec;
    Equation _horizontalHex;
    Equation _verticalDec;
    Equation _verticalHex;
    BoolOption _torusX;
    BoolOption _torusY;

    enum thisXl = 400;

public:
    this(Level level)
    {
        super(new Geom(0, 0, thisXl, 300, From.CENTER),
            Lang.winTopologyTitle.transl);
        _oldXl = level.topology.xl;
        _oldYl = level.topology.yl;
        makeAllChildren();
        _torusX.checked = level.topology.torusX;
        _torusY.checked = level.topology.torusY;
    }

protected:
    override void selfWriteChangesTo(Level level) const
    {
        level.topology.resize(suggestedXl, suggestedYl);
        level.topology.setTorusXY(_torusX.checked, _torusY.checked);

        immutable Point moveAllTilesBy = ()
        {
            Point ret = Point(_left.number, _top.number);
            // Defend against going over the max, but allow shifting
            // by adding and removing similar same area on opposing sides.
            if (_right.number == 0) {
                immutable defend = abs(_oldXl - suggestedXl);
                ret.x = clamp(ret.x, -defend, +defend);
            }
            if (_bottom.number == 0) {
                immutable defend = abs(_oldYl - suggestedYl);
                ret.y = clamp(ret.y, -defend, defend);
            }
            return ret;
        }();
        if (moveAllTilesBy != Point(0, 0)) {
            void fun(Occurrence occ)
            {
                occ.point = level.topology.wrap(occ.point + moveAllTilesBy);
            }
            level.terrain.each!fun;
            level.pos[].each!(occList => occList.each!fun);
        }
    }

    override void calcSelf()
    {
        if (_left.execute || _right.execute) {
            _horizontalDec.change = suggestedXl - _oldXl;
            _horizontalHex.change = suggestedXl - _oldXl;
        }
        if (_top.execute || _bottom.execute) {
            _horizontalDec.change = suggestedYl - _oldYl;
            _horizontalHex.change = suggestedYl - _oldYl;
        }
    }

private:
    @property int suggestedXl() const
    {
        return clamp(_oldXl + _left.number + _right.number,
                     Level.minXl, Level.maxXl);
    }

    @property int suggestedYl() const
    {
        return clamp(_oldYl + _top.number + _bottom.number,
                     Level.minYl, Level.maxYl);
    }

    void makeAllChildren()
    {
        enum butX   = 100f;
        enum textXl = 80f;
        enum boolXl = thisXl - 3*20 - 100; // 100 is super's button xlg
        void label(in float y, in Lang cap)
        {
            addChild(new Label(new Geom(20, y, textXl, 20), cap.transl));
        }
        label( 30, Lang.winTopologyL);
        label( 50, Lang.winTopologyR);
        label( 80, Lang.winTopologyU);
        label(100, Lang.winTopologyD);
        label(130, Lang.winTopologyX);
        label(180, Lang.winTopologyY);

        NumPick newSidePick(in float y, in int valMax)
        {
            assert (valMax > 0);
            NumPickConfig cfg;
            cfg.sixButtons = true;
            cfg.digits     = 5; // four digits and a minus sign
            cfg.stepSmall  = 2;
            cfg.stepMedium = 0x10;
            cfg.stepBig    = 0x80;
            cfg.min = -valMax;
            cfg.max = +valMax;
            return new NumPick(new Geom(butX, y, 180, 20), cfg);
        }
        _left   = newSidePick( 30, Level.maxXl);
        _right  = newSidePick( 50, Level.maxXl);
        _top    = newSidePick( 80, Level.maxYl);
        _bottom = newSidePick(100, Level.maxYl);
        _horizontalDec = new Equation(butX, 130, _oldXl, Equation.Format.dec);
        _horizontalHex = new Equation(butX, 150, _oldXl, Equation.Format.hex);
        _verticalDec   = new Equation(butX, 180, _oldYl, Equation.Format.dec);
        _verticalHex   = new Equation(butX, 200, _oldYl, Equation.Format.hex);
        _torusX = new BoolOption(new Geom(20, 230, boolXl, 20),
                                 Lang.winTopologyTorusX.transl, null);
        _torusY = new BoolOption(new Geom(20, 260, boolXl, 20),
                                 Lang.winTopologyTorusY.transl, null);
        addChildren(_left, _right, _top, _bottom,
                    _horizontalDec, _horizontalHex,
                    _verticalDec,   _verticalHex, _torusX, _torusY);
    }
}

/* private class Equation: The geoms are hardcoded to allow for exactly 4
 * digits in the old value, the change, and the result. The maximal level
 * size is 5 C++ screens in each direction: 3200 x 2000 pixels. These values
 * fit into 4 digits, and into 3 hex digits with a leading "0x" subscript,
 * because 0xFFF == 16^^3 - 1 == 4095 > 3200.
 */
private class Equation : Element {
private:
    Label _old, _sign, _change, _equals, _result;
    immutable Format _decOrHex;
    immutable int _oldValue;

public:
    enum Format { dec, hex }
    enum valueMax = 16^^3;

    this(in float x, in float y, in int oldValue, in Format decOrHex)
    in {
        static assert (Level.maxXl < valueMax);
        static assert (Level.maxYl < valueMax);
    }
    body {
        super(new Geom(x, y, 150f, 20f, From.TOP_LEFT));
        undrawColor = color.guiM; // erase old labels before writing
        _oldValue = oldValue;
        _decOrHex = decOrHex;
        _old    = new Label(new Geom(110, 0, 40, 0, From.TOP_RIGHT));
        _sign   = new Label(new Geom( 95, 0, 15, 0, From.TOP_RIGHT));
        _change = new Label(new Geom( 55, 0, 40, 0, From.TOP_RIGHT));
        _equals = new Label(new Geom( 40, 0, 15, 0, From.TOP_RIGHT), "=");
        _result = new Label(new Geom(  0, 0, 40, 0, From.TOP_RIGHT));
        _old.text = formatEquationString(_oldValue);
        addChildren(_old, _sign, _change, _equals, _result);
        change = 0;
    }

    @property void change(in int aChange)
    {
        _sign  .text = (aChange >= 0 ? "+" : "\u2212"); // unicode minus sign
        _change.text = formatEquationString(aChange.abs);
        _result.text = formatEquationString(_oldValue + aChange);
        _sign  .color = (aChange == 0 ? color.guiText : color.guiTextOn);
        _change.color = _sign.color;
        _result.color = _change.color;
        reqDraw();
    }

protected:
    override void drawSelf()
    {
        undraw();
        super.drawSelf();
    }

private:
    string formatEquationString(int val)
    {
        assert (val.abs < valueMax);
        if (val == 0)
            return "0";
        else if (val < 0)
            return "< 0";
        string ret;
        while (val != 0) {
            int lastDigit = val % (_decOrHex == Format.dec ? 10 : 16);
            val -= lastDigit;
            val /= (_decOrHex == Format.dec ? 10 : 16);
            ret = "0123456789ABCDEF"[lastDigit] ~ ret;
        }
        return _decOrHex == Format.dec ? ret
            :  "\u2080\u2093" ~ ret; // subscript 0x
    }
}
