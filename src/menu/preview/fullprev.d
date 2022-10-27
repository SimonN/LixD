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
    this(Geom g,
        in float ylBetweenThumbnailAndNameplate,
        in float ylForNameplate // Use this much ylg from g for nameplate.
    ) {
        super(g);
        _thumbnail = new LevelThumbnail(new Geom(0, 0, xlg,
            ylg - ylBetweenThumbnailAndNameplate - ylForNameplate));
        _nameplate = new Nameplate(new Geom(0, 0, xlg,
            ylForNameplate, From.BOTTOM));
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

    void preview(in Replay rep, in Filename fnOfThatReplay, in Level lev)
    {
        _thumbnail.preview(rep, fnOfThatReplay, lev);
        _nameplate.preview(rep, fnOfThatReplay, lev);
    }
}
