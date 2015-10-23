module gui.frame;

/* A rectangular frame
 *
 * Drawing this frame, and -- if gui.element.ELement.undrawColor is set,
 * then undrawing too -- affects a range larger than the frame's size!
 * The drawing/undrawing size is about 2 geoms larger in all four directions.
 *
 * We don't measure in geoms, however, but use Geom.thickness for precision.
 * Otherwise, we could get rounding errors.
 */

import basics.alleg5;
import graphic.color;
import gui;

class Frame : Element {

    this(Geom g)
    {
        super(g);
    }

protected:

    override void drawSelf()
    {
        alias th = Geom.thicks;
        draw3DButton(xs - th, ys - th, xls + 2*th, yls + 2*th,
            color.guiD, color.transp, color.guiL);
    }

    override void undrawSelf()
    {
        alias th = Geom.thicks;
        al_draw_filled_rectangle(xs - th, ys - th,
            xs + xls + th, ys + yls + th, undrawColor);
    }

}
// end class Frame
