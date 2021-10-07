module menu.preview.fullprev;

/*
 * FullPreview: A LevelThumbnail with the Nameplate below.
 * See other classes in package menu.preview.
 */

import gui;
import menu.preview.base;
import menu.preview.namepl;
import menu.preview.thumbn;

class FullPreview : Element, PreviewLevelOrReplay {
private:
    LevelThumbnail _thumbnail;
    Nameplate _nameplate;

public:
    this(Geom g)
    {
        super(g);
        immutable float ySpacing = g.ylg >= 220f ? 20f : 5f;
        immutable float ylNamepl = g.ylg >= 220f ? 60f : 54f;
        _thumbnail = new LevelThumbnail(
            new Geom(0, 0, xlg, ylg - ySpacing - ylNamepl));
        _nameplate = new Nameplate(
            new Geom(0, 0, xlg, ylNamepl, From.BOTTOM));
        addChildren(_thumbnail, _nameplate);
    }

    void setUndrawBeforeDraw()
    {
        _nameplate.setUndrawBeforeDraw();
    }

    void dispose()
    {
        _thumbnail.dispose();
    }

    void previewNone()
    {
        _thumbnail.previewNone();
        _nameplate.previewNone();
    }

    void preview(in Level lev)
    {
        _thumbnail.preview(lev);
        _nameplate.preview(lev);
    }

    void preview(in Replay rep, in Level lev)
    {
        _thumbnail.preview(rep, lev);
        _nameplate.preview(rep, lev);
    }
}
