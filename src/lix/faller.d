module lix.faller;

import lix;

mixin template FallerFields() {
    struct {
        int pixelsFallen;
        int ySpeed;
    }
}

void becomeFaller(Lixxie lixxie) { with (lixxie)
{
    becomeDefault(Ac.FALLER);
    ySpeed = 4;
}}



void updateFaller(Lixxie lixxie, in UpdateArgs ua) { with (lixxie)
{
    moveDown(ySpeed);
    ++ySpeed;
    /+
    for (int i = 0; i <= l.get_special_y() && l.get_ac() == LixEn::FALLER;++i){
        // a bit kludgy, we can't do such a thing for flingers etc, since
        // they might be nonconstant.
        if (l.get_foot_encounters() & Lookup::bit_trampoline) {
            // stop falling, so the trampoline can be used
            break;
        }
        else if (l.is_solid(0, i+2)) {
            l.move_down(i);
            l.set_special_x(l.get_special_x() + i);

            // Schirm in letzter Sekunde?
            if (l.get_special_x() > Lixxie::distance_safe_fall
                && !l.get_floater()
            ) {
                l.become(LixEn::SPLATTER);
                l.play_sound(ua, Sound::SPLAT);
                // Nicht explodieren lassen, das täte er bei 76 :-)
                if (l.get_updates_since_bomb() == 75
                    || ua.st.tribes.size() <= 1 // singleplayer
                ) {
                    l.set_updates_since_bomb(0);
                }
            }
            else if ((l.get_special_x() <= 9 && l.get_frame() < 1)
             ||       l.get_special_x() == 0) {
                l.become(LixEn::WALKER);
                if (l.get_runner()) l.set_frame(6);
                else                l.set_frame(8);
            }
            else if (l.get_frame() < 2) {
                l.become(LixEn::WALKER);
                l.set_frame(0);
            }
            else if (l.get_frame() < 3) {
                l.become(LixEn::LANDER);
                l.set_frame(1);
            }
            else {
                l.become(LixEn::LANDER);
                // use the regular frame 0
            }
        }
    }

    if (l.get_ac() == LixEn::FALLER) {
        l.set_special_x(l.get_special_x() + l.get_special_y());
        l.move_down(l.get_special_y());

        if (l.get_special_y() < 8) l.set_special_y(l.get_special_y() + 1);

        // The last two frames alternate, the first frames are just the
        // initial frames of falling.
        if (l.is_last_frame()) l.set_frame(l.get_frame() - 1);
        else l.next_frame();

        if (l.get_floater()
         && l.get_special_x() >= Lixxie::distance_float) {
            const int sy = l.get_special_y();
            l.become(LixEn::FLOATER);
            l.set_special_y(sy);
        }
    }
    +/
}}
