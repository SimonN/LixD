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
    LevelStatus _status;
    Torbit  torbit; // the little canvas, sized like (this), to draw on
    Graphic iconStatus;
    Graphic iconTorus;

    immutable(string)[] _missingTiles;
    Label _mtl; // (missing tiles)-label

public:
    this(Geom g)
    {
        super(g);
        _status = LevelStatus.BAD_EMPTY;
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

    @property LevelStatus status() { return _status; }

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
            _status = level.status;
            iconStatus.xf = status;
            iconTorus .xf = level.topology.torusX + 2 * level.topology.torusY;
            if (_status == LevelStatus.BAD_EMPTY)
                iconStatus.xf = 0;
            _missingTiles = level.missingTiles;
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
        drawMissingTiles();
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

    void drawMissingTiles()
    {
        if (_missingTiles.length == 0) {
            _mtl.hide();
            return;
        }
        al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, darkeningColor());

        _mtl.show();
        _mtl.resize(xlg - 2 * thickg - 2 * iconTorus.xl / stretchFactor, 20);
        _mtl.move(iconTorus.xl / stretchFactor + thickg,
                  iconTorus.yl / stretchFactor / 2f - 10);
        _mtl.text = format!"%d %s"(_missingTiles.length,
            Lang.previewMissingTiles.transl);
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
            _mtl.text = format!"%d %s `%s'"(
                _missingTiles.length - i,
                Lang.previewMissingTilesMoreSee.transl,  fileLog.rootless);
            _mtl.draw();
        }
    }
}

private Alcol darkeningColor()
{
    float r, g, b;
    al_unmap_rgb_f(color.screenBorder, &r, &g, &b);
    return Alcol(r, g, b, 0.9f);
}
