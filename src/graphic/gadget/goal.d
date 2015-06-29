module graphic.gadget.goal;

import std.algorithm; // max

import basics.globals; // file_bitmap_mouse
import basics.help; // len
import game.tribe;
import graphic.cutbit;
import graphic.gadget;
import graphic.gralib;
import graphic.torbit;
import level.level;
import lix.enums;

/* owners are always drawn onto the goal, unless the owner is GARDEN.
 * When singleplayer time runs out, set draw_with_no_sign.
 */

class Goal : Gadget {

public:

    bool draw_with_no_sign;

    this(Torbit tb, in ref Pos levelpos)
    {
        super(tb, levelpos);
    }

    this(Goal rhs)
    {
        super(rhs);
        _tribes           = rhs._tribes.dup; // we don't own the tribes
        draw_with_no_sign = rhs.draw_with_no_sign;
    }

    bool has_tribe(in Tribe t) const
    {
        foreach (const(Tribe) tribe_in_array; _tribes)
            if (t is tribe_in_array)
                return true;
        return false;
    }

    void add_tribe(Tribe t)
    {
        if (! has_tribe(t))
            _tribes ~= t;
    }

private:

    Tribe[] _tribes;

protected:

    override void draw_game_extras()
    {
        if (! draw_with_no_sign) {
            // draw owners
            int offset = 0;
            foreach (const(Tribe) t; _tribes) {
                if (t.style == Style.GARDEN)
                    continue;
                const(Cutbit) c = graphic.gralib.get_lix(t.style);
                c.draw(ground,
                    x + tile.trigger_x + tile.trigger_xl / 2 - c.xl / 2
                      + (20 * offset++) - 10 * (_tribes.len - 1),
                    max(y, y + yl - 70),
                    0, ac_to_y_frame(Ac.WALKER));
            }
        }
        else {
            // draw no sign
            const(Cutbit) c = get_internal(file_bitmap_mouse);
            c.draw(ground,
                x + tile.trigger_x + tile.trigger_xl / 2 - c.xl / 2,
                y + tile.trigger_y + tile.trigger_yl / 2 - c.yl,
                2, 2); // (2,2) are the (xf,yf) of the international "no" sign
        }
    }

}
// end class Goal
