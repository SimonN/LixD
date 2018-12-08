module menu.preview;

/* A GUI element that displays a level thumbnail.
 * Part of package menu, not gui, because only the large menus use it.
 */

import std.format;

import basics.alleg5;
import basics.globals;
import basics.help; // rounding
import gui;
import file.language;
import graphic.color;
import graphic.graphic;
import graphic.internal;
import graphic.torbit;
import level.level;

class Preview : Frame {
private:
    Torbit  torbit; // the little canvas, sized like (this), to draw on
    Graphic iconStatus;
    Graphic iconTorus;

    immutable(string)[] _missingTiles;
    bool _warningTooLarge;
    Label _mtl; // (missing tiles)-label or printing too-large-warning

public:
    this(Geom g)
    {
        super(g);
        auto cb = getInternal(fileImagePreviewIcon);
        iconStatus = new Graphic(cb, guiosd);
        iconTorus  = new Graphic(cb, guiosd);
        iconTorus.yf = 1;

        _mtl = new Label(new Geom(0, 0, xlg, 20, From.TOP_LEFT));
        _mtl.undrawColor = color.transp;
        addChild(_mtl);
    }

    ~this()
    {
        if (torbit) destroy(torbit);
        torbit = null;
    }

    public @property void level(in Level level) // to clear, set level = 0
    {
        if (torbit)
            destroy(torbit);
        torbit        = null;
        iconStatus.xf = 0;
        iconTorus .xf = 0;

        if (level !is null) {
            torbit  = level.create_preview(
                (xs + xls).roundInt - xs.roundInt,
                (ys + yls).roundInt - ys.roundInt, color.screenBorder);
            iconStatus.xf = level.errorMissingTiles ? 3
                : level.errorNoHatches ? 1
                : level.warningNoGoals ? 2 : 0;
            iconTorus .xf = level.topology.torusX + 2 * level.topology.torusY;
            if (level.errorEmpty)
                iconStatus.xf = 0;
            _missingTiles = level.missingTiles;
            _warningTooLarge = level.warningTooLarge;
        }
        reqDraw();
    }

protected:
    override void drawSelf()
    {
        super.drawSelf();
        if (torbit) {
            assert (guiosd.isTargetTorbit);
            torbit.albit.drawToTargetTorbit(Point(xs.roundInt, ys.roundInt));
        }
        else
            // target is guiosd already, because we're in an Element's draw
            al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, undrawColor);
        drawWarningTexts();
        drawIcons();
    }

private:
    void drawIcons()
    {
        void stampAt(in float x, in float y)
        {
            iconStatus.loc = Point(x.roundInt, y.roundInt);
            iconStatus.draw();
        }
        stampAt(xs,                       ys);
        stampAt(xs,                       ys + yls - iconStatus.yl);
        stampAt(xs + xls - iconStatus.xl, ys);
        stampAt(xs + xls - iconStatus.xl, ys + yls - iconStatus.yl);
        iconTorus.loc = Point(xs.roundInt, ys.roundInt);
        iconTorus.draw();
    }

    void drawWarningTexts()
    {
        if (! _missingTiles.len && ! _warningTooLarge) {
            _mtl.hide();
            return;
        }
        al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, darkeningColor());
        _mtl.show();
        if (_missingTiles.len)
            drawMissingTiles();
        else
            drawWarningTooLarge();
    }

    void drawMissingTiles()
    {
        _mtl.resize(xlg - 2 * thickg - 2 * iconTorus.xl / stretchFactor, 20);
        _mtl.move(iconTorus.xl / stretchFactor + thickg,
                  iconTorus.yl / stretchFactor / 2f - 10);
        _mtl.text = Lang.previewMissingTiles.translf(_missingTiles.length);
        _mtl.draw();

        int i = 0; // number of tiles reported
        while (i < _missingTiles.length) {
            _mtl.resize(xlg - 2 * thickg, 20);
            _mtl.move(thickg, iconTorus.yl / stretchFactor + i * 20);
            if (_mtl.yg >= this.yg + this.ylg - iconStatus.yl)
                break;
            _mtl.text = _missingTiles[i];
            _mtl.draw();
            ++i;
        }
        if (i < _missingTiles.length) {
            _mtl.resize(xlg - 2*thickg - 2*iconTorus.xl/stretchFactor, 20);
            _mtl.move(iconTorus.xl / stretchFactor + thickg,
                      this.ylg - 10 - iconTorus.yl / stretchFactor / 2f);
            _mtl.text = Lang.previewMissingTilesMoreSee.translf(
                _missingTiles.length - i, fileLog.rootless);
            _mtl.draw();
        }
    }

    void drawWarningTooLarge()
    {
        void printLine(in int nthLine, in string str)
        {
            _mtl.resize(xlg - 2 * thickg, 20);
            _mtl.move(thickg, iconTorus.yl / stretchFactor + nthLine * 20);
            _mtl.text = str;
            _mtl.draw();
        }
        printLine(0, Lang.winTopologyWarnSize1.transl);
        printLine(1, formattedWinTopologyWarnSize2());
        printLine(2, Lang.winTopologyWarnSize3.transl);
    }
}

private Alcol darkeningColor()
{
    float r, g, b;
    al_unmap_rgb_f(color.screenBorder, &r, &g, &b);
    return al_map_rgba_f(r, g, b, 0.9f);
}
