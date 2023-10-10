module game.core.tooltip;

/*
 * The tooltip-displaying line.
 *
 * This is _not_ the definition of Tooltip, Tooltip.ID, Tooltip.IdSet:
 * Those are in game.panel.tooltip.
 */

import basics.alleg5;

import file.language;
import game.panel.tooltip;
import graphic.color;
import gui;

class TooltipLine : Element {
private:
    Label _labelMap; // Explains clicks into the map.
    Label _labelPanel; // Explains hovered things in the panel.
    Tips _wantedByCaller; // Nulled every calc(). Caller shall set it often.
    Tips _alreadyRendered; // Only avoid frequent reqDraw()s.

    struct Tips {
        Tooltip.IdSet idset = 0;
        Ac ac = Ac.nothing;
    }

public:
    this(Geom g)
    {
        super(g);
        undrawColor = color.transp;
        _labelMap = new Label(new Geom(0, 0, xlg, ylg, g.from));
        _labelMap.undrawBeforeDraw = true;
        _labelMap.undrawColor = color.transp;
        addChild(_labelMap);
        _labelPanel = new Label(new Geom(0, 0, xlg, 12f, g.from));
        _labelPanel.font = djvuS;
        _labelPanel.undrawBeforeDraw = true;
        _labelPanel.undrawColor = color.transp;
        addChild(_labelPanel);
    }

    void suggestTooltip(in Ac ac)
    {
        _wantedByCaller.ac = ac;
        if (_wantedByCaller.ac == _alreadyRendered.ac) {
            return;
        }
        reqDraw();
    }

    void suggestTooltip(in Tooltip.ID id)
    {
        _wantedByCaller.idset |= id;
        if (id & _alreadyRendered.idset) {
            return;
        }
        reqDraw();
    }

protected:
    override void calcSelf()
    {
        if (_wantedByCaller != Tips.init) {
            unhideAndFormatTooltip();
        }
        else if (_labelMap.shown || _labelPanel.shown) {
            _labelMap.hide();
            _labelPanel.hide();
            _alreadyRendered = Tips.init;
            reqDraw(); // Only a single time, to clear ourselves.
        }
        _wantedByCaller = Tips.init;
    }

    override void drawSelf()
    {
        forceUndrawToTransparent();
        if (_labelMap.shown) {
            drawDarkenedBg(_labelMap);
        }
        else if (_labelPanel.shown) {
            drawDarkenedBg(_labelPanel);
        }
    }

    override void undrawSelf()
    {
        forceUndrawToTransparent();
    }

private:
    void unhideAndFormatTooltip()
    {
        if (_wantedByCaller == _alreadyRendered) {
            return;
        }
        _labelMap.hide();
        _labelPanel.hide();

        string s = Tooltip.format(_wantedByCaller.idset);
        if (s == "" && _wantedByCaller.ac != Ac.nothing) {
            s = file.language.skillTransl(_wantedByCaller.ac).buttonTooltip;
        }
        bestLabelForWanted.show();
        bestLabelForWanted.text = s;
        _alreadyRendered = _wantedByCaller;
        reqDraw();
    }

    Label bestLabelForWanted() pure nothrow @safe @nogc
    {
        return Tooltip.isAboutMapClicks(_wantedByCaller.idset)
            ? _labelMap : _labelPanel;
    }

    void drawDarkenedBg(in Label la)
    {
        enum darkenedBg = Alcol(0, 0, 0, 0.4f);
        al_draw_filled_rectangle(
            la.xs + la.xls - la.textLgs - gui.thicks * 4,
            la.ys,
            la.xs + la.xls,
            la.ys + la.yls,
            darkenedBg);
    }
}
