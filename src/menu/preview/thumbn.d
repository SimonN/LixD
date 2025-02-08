module menu.preview.thumbn;

/*
 * LevelThumbnail: A GUI element that displays a level thumbnail.
 * Part of package menu, not gui, because only the large menus use it.
 *
 * Implements all methods of PreviewLevelOrReplay nontrivially,
 * but will only interpret the Level arguments of the methods, no Replay.
 */

import std.algorithm;

import basics.alleg5;
import basics.help; // rounding
import basics.globals : fileLog;
import gui;
import file.language;
import graphic.color;
import graphic.internal;
import graphic.torbit;
import level.level;
import menu.preview.base;

class LevelThumbnail : Frame, PreviewLevelOrReplay {
private:
    Torbit  torbit; // the little canvas, sized like (this), to draw on
    CornerStamp iconStatus;
    CornerStamp iconTorus;

    immutable(string)[] _missingTiles;
    bool _warningTooLarge;
    Label _mtl; // (missing tiles)-label or printing too-large-warning

public:
    this(Geom g)
    {
        super(g);
        iconTorus.yf = 1;
        _mtl = new Label(new Geom(0, 0, xlg, 20, From.TOP_LEFT));
        _mtl.undrawColor = color.transp;
        addChild(_mtl);
    }

    void dispose()
    {
        if (torbit) {
            destroy(torbit);
        }
        torbit = null;
        iconStatus.xf = 0;
        iconTorus .xf = 0;
    }

    void previewNone()
    {
        dispose();
        reqDraw();
    }

    void preview(in Level lev)
    {
        assert (lev, "call previewNone() to clear, not preview(null)");
        dispose();
        torbit = lev.create_preview(
            (xs + xls).roundInt - xs.ceilInt,
            (ys + yls).roundInt - ys.ceilInt, color.screenBorder);
        iconStatus.xf = lev.errorMissingTiles ? 3
            : lev.errorNoHatches ? 1
            : lev.warningNoGoals ? 2 : 0;
        iconTorus .xf = lev.topology.torusX + 2 * lev.topology.torusY;
        if (lev.errorEmpty)
            iconStatus.xf = 0;
        _missingTiles = lev.missingTiles;
        _warningTooLarge = lev.warningTooLarge;
        reqDraw();
    }

    void preview(in Replay ignored, in Filename ignoredToo, in Level lev)
    {
        preview(lev);
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
            immutable float centerLineY = ylg / 2f - 20f / 2f;
            immutable float nextLinePlusY = min(20f, ylg / 3f);
            _mtl.resize(xlg - 2 * thickg, 20);
            _mtl.move(thickg, centerLineY + nthLine * nextLinePlusY);
            _mtl.text = str;
            _mtl.draw();
        }
        printLine(-1, Lang.winTopologyWarnSize1.transl);
        printLine(0, formattedWinTopologyWarnSize2());
        printLine(1, Lang.winTopologyWarnSize3.transl);
    }
}

private Alcol darkeningColor()
{
    float r, g, b;
    al_unmap_rgb_f(color.screenBorder, &r, &g, &b);
    return al_map_rgba_f(r, g, b, 0.9f);
}

struct CornerStamp {
public:
    Point loc = Point(0, 0);
    int xf = 0;
    int yf = 0;

const:
    const(Cutbit) cutbit() const { return InternalImage.previewIcon.toCutbit; }
    int xl() const { return cutbit.xl; }
    int yl() const { return cutbit.yl; }
    void draw() const { cutbit.draw(loc, xf, yf); }
}
