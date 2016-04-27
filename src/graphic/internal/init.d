module graphic.internal.init;

import std.string; // format
import std.algorithm;

import basics.alleg5;
import basics.globals;
import basics.help;
import basics.matrix;
import basics.rect;
import file.filename;
import graphic.color;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.vars;
import hardware.display; // show progress during startup, maybe make this lazy
import lix.enums;
import lix.fields;

package:

void implInitializeInteractive()
{
    nullCutbit = new Cutbit(cast (Cutbit) null);
}

void implInitializeVerify()
{
    nullCutbit = new Cutbit(cast (Cutbit) null);
    noninteractiveMode = true;
}

void implDeinitialize()
{
    destroyArray(skillButtonIcons);
    destroyArray(panelInfoIcons);
    destroyArray(spritesheets);
    destroyArray(internal);
    destroy(nullCutbit);
    nullCutbit = null;
}

private:

void createEyeCoordinateMatrix()
{
    // Each frame of the Lix spritesheet has the eyes in some position.
    // The exploder fuse shall start at that position, let's calculate it.
    // It's also important for physics, eyes touching fire will kill.
    Cutbit cb = getLixRawSprites();
    Albit b = cb.albit;
    auto lock = LockReadOnly(b);
    assert (b, "apparently your gfx card can't store the Lix spritesheet");

    lix.fields.countdown = new Matrix!Point(cb.xfs, cb.yfs);
    // fx, fy = which x- respective y-frame
    // x,  y  = which pixel inside this frame, offset from frame's top left
    for  (int fy = 0; fy < cb.yfs; ++fy)
     for (int fx = 0; fx < cb.xfs; ++fx) {
        for  (int y = 0; y < cb.yl; ++y )
         for (int x = 0; x < cb.xl; ++x ) {
            // Is it the pixel of the eye?
            const int real_x = 1 + fx * (cb.xl + 1) + x;
            const int real_y = 1 + fy * (cb.yl + 1) + y;
            if (al_get_pixel(b, real_x, real_y) == color.lixFileEye) {
                countdown.set(fx, fy, Point(x, y-1));
                goto GOTO_NEXTFRAME;
            }
            // If not yet gone to GOTO_NEXTFRAME:
            // Use the Point of the frame left to the current one if there was
            // nothing found, and a default value for the leftmost frames.
            // Frames (0, y) and (1, y) are the skill button images.
            if (y == cb.yl - 1 && x == cb.xl - 1) {
                if (fx < 3) countdown.set(fx, fy, Point(cb.xl / 2 - 1, 12));
                else        countdown.set(fx, fy, countdown.get(fx - 1, fy));
            }
        }
        GOTO_NEXTFRAME:
        if (fy == Ac.blocker) {
            Point blockerEyes = countdown.get(fx, fy);
            blockerEyes.x = lix.enums.exOffset;
            countdown.set(fx, fy, blockerEyes);
        }
    }
    // All pixels of the entire spritesheet have been examined.
}
