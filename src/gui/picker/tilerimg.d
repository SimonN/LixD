module gui.picker.tilerimg;

// this is used in the editor's terrain browser.

import std.conv;
import std.range;
import std.string;
import std.typecons;

import basics.help; // roundInt
import gui;
import gui.picker.tiler;
import level.level;
import tile.tilelib;
import tile.abstile;

class ImageTiler(ButtonType : TerrainBrowserButton) : FileTiler {
public:
    this(Geom g) { super(g); }

    @property int coarseness() const { return buttonsPerPageX(); }
    @property int wheelSpeed() const { return buttonsPerPageX(); }

    @property int pageLen() const
    {
        return buttonsPerPageX * buttonsPerPageY;
    }

    int buttonsPerPageX() const { return 6 + 2 * roundInt(xls / 0x1D0); }
    int buttonsPerPageY() const { return 4 +     roundInt(yls / 0x160); }

protected:
    override TextButton newDirButton(Filename fn)
    {
        assert (fn);
        return new TextButton(new Geom(0, 0,
            xlg / buttonsPerPageX * dirSizeMultiplier,
            ylg / buttonsPerPageY), fn.dirInnermost);
    }

    override ButtonType newFileButton(Filename fn, in int fileID)
    {
        assert (fn);
        return new ButtonType(new Geom(0, 0,
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
            // Adding gui.thickg much of padding around the cutbit element.
            // Reason: We shall not draw on the button's 3D edge.
            // Adding + 1 to the thickness offset from the top.
            // Reason: The rounding is crap, neither +0 nor +1 is optimal right
            // now. I rather leave empty row than overwrite button thickness.
            _cbe = new CutbitElement(new Geom(0, gui.thickg + 1,
                xlg - 2*gui.thickg, ylg - 13, From.TOP), resolved.tile.cb);
            _cbe.allowUpscaling = false;
            addChild(_cbe);
        }
        _text = new Label(new Geom(0, 0, xlg - 2*gui.thickg, 12, From.BOTTOM),
            toLabel(fn));
        _text.font = djvuS;
        addChild(_text);
    }

protected:
    string toLabel(in Filename fn) const { return fn.fileNoExtNoPre; }
}

class GadgetBrowserButton : TerrainBrowserButton {
public:
    this(Geom g, Filename fn) { super(g, fn); }

protected:
    override string toLabel(in Filename fn) const
    {
        return fn.dirInnermost.walkLength <= 8
            ? fn.dirInnermost ~ fn.fileNoExtNoPre
            : fn.dirInnermost.take(6).chain("./", fn.fileNoExtNoPre).to!string;
    }
}
