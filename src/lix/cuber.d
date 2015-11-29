module lix.cuber;

import lix;

/+
static this()
{
    acFunc[Ac.CUBER]     .leaving = true;
}
+/

class Cuber : PerformedActivity {

    mixin(CloneByCopyFrom!"Cuber");

    override @property bool blockable() const { return false; }

    // DTODOVRAM: Implement this in the physics drawing class, and have
    // the cuber send several terrain change requests to that

    // Draws the the rectangle specified by xs, ys, ws, hs of the
    // specified animation frame onto the level map at position (xd, yd),
    // as diggable terrain. (xd, yd) specifies the top left of the destination
    // rectangle relative to the lix's position
    private void drawFrameToMapAsTerrain
    (
        int frame, int anim,
        int xs, int ys, int ws, int hs,
        int xd, int yd
    ) {
        assert (false, "DTODO: implement this function (as terrain => speed!");
        /*
        for (int y = 0; y < hs; ++y) {
            for (int x = 0; x < ws; ++x) {
                const AlCol col = cutbit.get_pixel(frame, anim, xs+x, ys+y);
                if (col != color.transp && ! getSteel(xd + x, yd + y)) {
                    addLand(xd + x, yd + y, col);
                }
            }
        }
        */
    }

}
