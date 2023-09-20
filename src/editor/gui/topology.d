module editor.gui.topology;

import std.algorithm;
import std.math;

import enumap;

import basics.globals;
import basics.topology;
import file.option;
import editor.gui.okcancel;
import editor.undoable.topology;
import file.language;
import gui;
import gui.option;
import graphic.color;
import level.level;
import tile.occur;

/*
 * Hack: A global to pass input (to construct the Undoable) from the Window
 * to the Editor. The OkCancelWindow hierarchy works by applying things
 * directly to the level, we can't use that meaningfully for undo, we should
 * refactor that hierarchy. Until then, we pass via global variable.
 *
 * The editor shall check the bool. If it's true, he shall set it to false
 * and use the State element [0] once.
 */
bool __global__newResultForTheEditor = false;
TopologyChange.State[] __global__suggestedTopologyChangeState = [];
Point __global__moveAllTilesBy;

class TopologyWindow : OkCancelWindow {
private:
    immutable int _oldXl;
    immutable int _oldYl;
    NumPick _left;
    NumPick _right;
    NumPick _top;
    NumPick _bottom;
    Equation _eqXDec;
    Equation _eqXHex;
    Equation _eqYDec;
    Equation _eqYHex;
    BoolOption _torusX;
    BoolOption _torusY;
    Label[] _warnTooLarge;

    enum thisXl = 480;
    NumPick[3] _bgColors;
    int[3] _bgColorsToRevertToOnCancel;

public:
    this(Level level)
    {
        super(new Geom(0, 0, thisXl, 290, From.CENTER),
            Lang.winTopologyTitle.transl);
        __global__newResultForTheEditor = false;
        _oldXl = level.topology.xl;
        _oldYl = level.topology.yl;
        makeTopologyChildren(level);
        makeWarningChildren();
        makeColorChildren(level);
    }

protected:
    override void selfWriteChangesTo(Level level) const
    {
        level.bgColor = al_map_rgb(
            _bgColorsToRevertToOnCancel[0] & 0xFF,
            _bgColorsToRevertToOnCancel[1] & 0xFF,
            _bgColorsToRevertToOnCancel[2] & 0xFF);
        __global__suggestedTopologyChangeState = [];
        __global__suggestedTopologyChangeState ~= TopologyChange.State(
            new immutable Topology(
            suggestedXl, suggestedYl, _torusX.isChecked, _torusY.isChecked),
            suggestedColor);
        __global__moveAllTilesBy = Point(_left.number, _top.number);
        __global__newResultForTheEditor = true;
    }

    override void selfPreviewChangesOn(Level level) const
    {
        level.bgColor = suggestedColor;
    }

    override void selfRevertToNoChange()
    {
        foreach (id, e; _bgColors)
            e.number = _bgColorsToRevertToOnCancel[id];
    }

    override void calcSelf()
    {
        if (_left.execute || _right.execute) {
            _eqXDec.change = suggestedXl - _oldXl;
            _eqXHex.change = suggestedXl - _oldXl;
        }
        if (_top.execute || _bottom.execute) {
            _eqYDec.change = suggestedYl - _oldYl;
            _eqYHex.change = suggestedYl - _oldYl;
        }
        warnIfTooLarge();
    }

private:
    int suggestedXl() const
    {
        return clamp(_oldXl + _left.number + _right.number,
                     Level.minXl, Level.maxXl);
    }

    int suggestedYl() const
    {
        return clamp(_oldYl + _top.number + _bottom.number,
                     Level.minYl, Level.maxYl);
    }

    Alcol suggestedColor() const
    {
        return al_map_rgb(
            _bgColors[0].number & 0xFF,
            _bgColors[1].number & 0xFF,
            _bgColors[2].number & 0xFF);
    }

    void warnIfTooLarge()
    {
        immutable warnedBefore = _warnTooLarge[0].shown;
        immutable warnNow = (suggestedXl * suggestedYl >= levelPixelsToWarn);
        foreach (label; _warnTooLarge) {
            label.shown = warnNow;
        }
        if (warnNow != warnedBefore) {
            reqDraw(); // Text overlaps between warning and bool options.
        }
    }

    void makeWarningChildren()
    in {
        assert (_warnTooLarge.length == 0);
        assert (_torusX !is null);
    }
    do {
        const float textXl = this.xlg/2; // -> makeTopologyChildren.boolXl
        _warnTooLarge ~= new Label(new Geom(20, -this.yg + _torusX.yg,
            textXl, 20, From.TOP_RIGHT), Lang.winTopologyWarnSize1.transl);
        _warnTooLarge ~= new Label(new Geom(20, -this.yg + _torusX.yg + 15,
            textXl, 20, From.TOP_RIGHT), formattedWinTopologyWarnSize2());
        _warnTooLarge ~= new Label(new Geom(20, -this.yg + _torusX.yg + 30,
            textXl, 20, From.TOP_RIGHT), Lang.winTopologyWarnSize3.transl);
        foreach (label; _warnTooLarge) {
            addChild(label);
            label.color = color.red; // Color is a feeble attempt at
            // differentiating warnings from overlapped bool option text.
        }
        warnIfTooLarge();
    }

    void makeTopologyChildren(Level level)
    {
        enum butX   = 100f;
        enum textXl = 80f;
        enum boolXl = thisXl - 40; // overlaps makeWarningChildren.textXl
        void label(in float y, in Lang cap)
        {
            addChild(new Label(new Geom(20, y, textXl, 20), cap.transl));
        }
        label( 30, Lang.winTopologyL);
        label( 50, Lang.winTopologyR);
        label( 80, Lang.winTopologyU);
        label(100, Lang.winTopologyD);

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
        _eqXDec = new Equation( 30, _oldXl, Equation.Format.dec);
        _eqXHex = new Equation( 50, _oldXl, Equation.Format.hex);
        _eqYDec = new Equation( 80, _oldYl, Equation.Format.dec);
        _eqYHex = new Equation(100, _oldYl, Equation.Format.hex);
        _torusX = new BoolOption(new Geom(20, 140, boolXl, 20),
                                 Lang.winTopologyTorusX);
        _torusY = new BoolOption(new Geom(20, 170, boolXl, 20),
                                 Lang.winTopologyTorusY);
        _torusX.checked = level.topology.torusX;
        _torusY.checked = level.topology.torusY;
        addChildren(_left, _right, _top, _bottom,
                    _eqXDec, _eqXHex,
                    _eqYDec,   _eqYHex, _torusX, _torusY);
    }

    void makeColorChildren(Level level)
    {
        auto newPick(in float y, in int startValue, in Lang desc)
        {
            NumPickConfig cfg;
            cfg.digits     = 3; // the first one is '0x'
            cfg.sixButtons = true;
            cfg.hex        = true;
            cfg.max        = 0xFF;
            cfg.stepMedium = 0x04;
            cfg.stepBig    = 0x10;
            enum colorPickXl = 120 + 40 + 10;
            auto ret = new NumPick(new Geom(140, y, colorPickXl, 20,
                From.TOP_RIGHT), cfg);
            ret.number = startValue;
            this.addChild(ret);
            this.addChild(new Label(new Geom(20, y,
                xlg-colorPickXl - 100 - 60, 20), // -100 for OK, -60 for spaces
                desc.transl));
            return ret;
        }
        {
            ubyte r, g, b;
            al_unmap_rgb(level.bgColor, &r, &g, &b);
            _bgColors[0] = newPick(ylg-80, r, Lang.winLooksRed);
            _bgColors[1] = newPick(ylg-60, g, Lang.winLooksGreen);
            _bgColors[2] = newPick(ylg-40, b, Lang.winLooksBlue);
        }

        foreach (id, e; _bgColors)
            _bgColorsToRevertToOnCancel[id] = e.number;
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

    this(in float y, in int oldValue, in Format decOrHex)
    in {
        static assert (Level.maxXl < valueMax);
        static assert (Level.maxYl < valueMax);
    }
    do {
        super(new Geom(20f, y, 165f, 20f, From.TOP_RIGHT));
        undrawColor = color.gui.m; // erase old labels before writing
        _oldValue = oldValue;
        _decOrHex = decOrHex;
        _old    = new Label(new Geom(120, 0, 50, 0, From.TOP_RIGHT));
        _sign   = new Label(new Geom(105, 0, 15, 0, From.TOP_RIGHT));
        _change = new Label(new Geom( 60, 0, 50, 0, From.TOP_RIGHT));
        _equals = new Label(new Geom( 45, 0, 15, 0, From.TOP_RIGHT), "=");
        _result = new Label(new Geom(  0, 0, 50, 0, From.TOP_RIGHT));
        _old.text = formatEquationString(_oldValue);
        addChildren(_old, _sign, _change, _equals, _result);
        change = 0;
    }

    void change(in int aChange)
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
