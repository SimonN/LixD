module editor.drawcol;

import basics.alleg5 : timerTicks;
import editor.editor;
import graphic.color;
import level.oil;
import tile.visitor;

// Always a value in 0 .. 255
int hoverColorLightness(in bool light)
{
    immutable int time  = timerTicks & 0x3F;
    immutable int subtr = time < 0x20 ? time : 0x40 - time;
    return (light ? 0xFF : 0xB0) - 2 * subtr;
}

void drawHovers(
    Editor editor,
    in OilSet list,
    in bool light
) {
    ColorVisitor visitor = new ColorVisitor(editor, light);
    foreach (oil; list) {
        const occ = oil.occ(editor.level);
        occ.tile.accept(visitor);
        editor._map.drawRectangle(occ.selboxOnMap, visitor.ret);
    }
}

/*
 * Determines the color of the hover frame to draw around a tile.
 * Doesn't do anything with the color; usercode shall read it from (Alcol ret).
 */
private class ColorVisitor : TileVisitor {
public:
    Alcol ret;

private:
    Editor _editor;
    immutable int _lig; // Cached value of hoverColorLightness

public:
    this(Editor ed, in bool light)
    {
        _editor = ed;
        _lig = hoverColorLightness(light);
    }

protected:
    override void visit(const(TerrainTile))
    {
        ret = color.makecol(_lig, _lig, _lig);
    }

    override void visit(const(GadgetTile))
    {
        ret = color.makecol(_lig, _lig, _lig/2);
    }

    override void visit(const(TileGroup))
    {
        ret = color.makecol(_lig/2, _lig*2/3, _lig);
    }
}
