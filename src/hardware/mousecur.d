module hardware.mousecur;

/* This is only for the drawable mouse cursor.
 * To read mouse input, look at the module hardware.mouse.
 *
 *  void initialize()
 *  void deinitialize();
 *  void draw();
 *
 *  public Graphic mouse; -- work with this object however you wish
 */

import basics.globals;
import graphic.cutbit;
import graphic.gralib;
import graphic.graphic;
import hardware.mouse;

public Graphic mouse;

void
initialize()
{
    assert (mouse is null, "mouse cursor is already initialized");
    const(Cutbit) cb = get_internal(file_bitmap_mouse);
    assert (cb, "mouse cursor bitmap is not loaded or missing");
    assert (cb.is_valid(), "mouse cursor bitmap is not valid");

    mouse = new Graphic(cb, null);
}



void
deinitialize()
{
    if (mouse) {
        destroy(mouse);
        mouse = null;
    }
}



void
draw()
{
    assert (mouse, "call hardware.mousecur.initialize() before drawing mouse");
    mouse.set_x(get_mx() - mouse.get_xl()/2 + 1);
    mouse.set_y(get_my() - mouse.get_yl()/2 + 1);
    mouse.draw_directly_to_screen();
}
