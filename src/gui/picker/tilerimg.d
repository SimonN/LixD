module gui.picker.tilerimg;

// this is used in the editor's terrain browser.

import std.conv;
import std.string;
import std.typecons;

import basics.help; // roundInt
import graphic.textout;
import gui;
import gui.picker.tiler;
import level.level;
import tile.tilelib;
import tile.abstile;

class ImageTiler : FileTiler {
public:
    this(Geom g) { super(g); }

    @property int coarseness() const { return buttonsPerPageX(); }
    @property int wheelSpeed() const { return buttonsPerPageX(); }

    @property int pageLen() const
    {
        return buttonsPerPageX * buttonsPerPageY;
    }

    int buttonsPerPageX() const { return 4 + 2 * roundInt(xls / 0x200); }
    int buttonsPerPageY() const { return 3 +     roundInt(yls / 0x100); }

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
        ResolvedTile resolved = resolveTileName(fn);
        if (resolved.tile) {
            // Adding Geom.thickg much of padding around the cutbit element.
            // Reason: We shall not draw on the button's 3D edge.
            // Adding + 1 to the thickness offset from the top.
            // Reason: The rounding is crap, neither +0 nor +1 is optimal right
            // now. I rather leave empty row than overwrite button thickness.
            _cbe = new CutbitElement(new Geom(0, Geom.thickg + 1,
                xlg - 2*Geom.thickg, ylg - 13, From.TOP), resolved.tile.cb);
            _cbe.allowUpscaling = false;
            addChild(_cbe);
        }
        _text = new Label(new Geom(0, 0, xlg - 2*Geom.thickg, 12, From.BOTTOM),
            fn.fileNoExtNoPre);
        _text.font = djvuS;
        addChild(_text);
    }
}
