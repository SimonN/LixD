module gui.picker.tilerimg;

// this is used in the editor's terrain browser.

import std.conv;
import std.string;
import std.typecons;

import graphic.textout;
import gui;
import gui.picker.tiler;
import level.level;
import tile.tilelib;
import tile.abstile;

class ImageTiler : Tiler {
public:
    enum buttonsPerPageX = 10;
    enum buttonsPerPageY = 6;
    this(Geom g) { super(g); }

    override @property int pageLen() const
    {
        return buttonsPerPageX * buttonsPerPageY;
    }

protected:
    override TextButton newDirButton(Filename fn)
    {
        assert (fn);
        return new TextButton(new Geom(0, 0,
            xlg / buttonsPerPageX * dirSizeMultiplier,
            ylg / buttonsPerPageY), fn.dirInnermost);
    }

    override TerrainBrowserButton newFileButton(Filename fn, in int fileID)
    {
        assert (fn);
        return new TerrainBrowserButton(new Geom(0, 0,
            xlg / buttonsPerPageX,
            ylg / buttonsPerPageY), fn);
    }

    override float buttonXg(in int idFromTop) const
    {
        return xlg * (idFromTop % buttonsPerPageX) / buttonsPerPageX;
    }

    override float buttonYg(in int idFromTop) const
    {
        return ylg * (idFromTop / buttonsPerPageX) / buttonsPerPageY;
    }
}

class TerrainBrowserButton : Button {
private:
    CutbitElement _cbe;
    Label _text;

public:
    this(Geom g, Filename fn)
    {
        assert (fn);
        super(g);
        Rebindable!(const(AbstractTile)) tile = get_terrain(fn.rootlessNoExt);
        if (! tile)
            tile = get_gadget(fn.rootlessNoExt);
        if (tile) {
            // Adding Geom.thickg much of padding around the cutbit element.
            // Reason: We shall not draw on the button's 3D edge.
            _cbe = new CutbitElement(new Geom(0, Geom.thickg,
                xlg - 2*Geom.thickg, ylg - 13, From.TOP), tile.cb);
            _cbe.shrink = true;
            addChild(_cbe);
        }
        _text = new Label(new Geom(0, 0, xlg - 2*Geom.thickg, 13, From.BOTTOM),
            fn.fileNoExtNoPre);
        _text.font = djvuS;
        addChild(_text);
    }
}
