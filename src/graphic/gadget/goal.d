module graphic.gadget.goal;

import std.algorithm; // max

import basics.help;
import basics.globals; // fileImageMouse
import basics.help; // len
import game.tribe;
import graphic.cutbit;
import graphic.gadget;
import graphic.gralib;
import graphic.torbit;
import level.level;
import lix.enums;

/* owners are always drawn onto the goal, unless the owner is GARDEN.
 * When singleplayer time runs out, set drawWithNoSign.
 */

class Goal : Gadget {

public:

    bool drawWithNoSign;

    this(Torbit tb, in ref Pos levelpos)
    {
        super(tb, levelpos);
    }

    this(Goal rhs)
    {
        super(rhs);
        _tribes        = rhs._tribes.dup; // we don't own the tribes
        drawWithNoSign = rhs.drawWithNoSign;
    }

    mixin CloneableOverride;

    bool hasTribe(in Tribe t) const
    {
        foreach (const(Tribe) inArray; _tribes)
            if (t is inArray)
                return true;
        return false;
    }

    void addTribe(Tribe t)
    {
        if (! hasTribe(t))
            _tribes ~= t;
    }

private:

    Tribe[] _tribes;

protected:

    override void drawGameExtras()
    {
        if (! drawWithNoSign) {
            // draw owners
            int offset = 0;
            foreach (const(Tribe) t; _tribes) {
                if (t.style == Style.GARDEN)
                    continue;
                auto c = graphic.gralib.getPanelInfoIcon(t.style);
                c.draw(ground,
                    x + tile.triggerX + tile.triggerXl / 2 - c.xl / 2
                      + (20 * offset++) - 10 * (_tribes.len - 1),
                    max(y, y + yl - 70),
                    Ac.WALKER, 0);
            }
        }
        else {
            // draw no sign
            const(Cutbit) c = getInternal(fileImageMouse);
            c.draw(ground,
                x + tile.triggerX + tile.triggerXl / 2 - c.xl / 2,
                y + tile.triggerY + tile.triggerYl / 2 - c.yl,
                2, 2); // (2,2) are the (xf,yf) of the international "no" sign
        }
    }

}
// end class Goal
