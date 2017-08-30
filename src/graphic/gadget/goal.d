module graphic.gadget.goal;

import std.algorithm; // max

import basics.globals; // fileImageMouse
import basics.help; // len
import basics.topology;
import game.tribe;
import graphic.cutbit;
import graphic.gadget;
import graphic.internal;
import graphic.torbit;
import tile.occur;
import net.ac;
import net.style;

/* owners are always drawn onto the goal, unless the owner is GARDEN.
 * When overtime runs out, set drawWithNoSign.
 */

class Goal : GadgetWithTribeList {
public:
    bool lockedWithNoSign = false;

    this(const(Topology) top, in ref GadOcc levelpos) { super(top, levelpos); }
    this(in Goal rhs) { super(rhs); }
    override Goal clone() const { return new Goal(this); }

protected:
    override void drawInner() const
    {
        drawOwners();
        drawNoSign();
    }

private:
    void drawOwners() const
    {
        int offset = 0;
        foreach (style; tribes) {
            if (style == Style.garden)
                continue;
            auto icon = graphic.internal.getSkillButtonIcon(style);
            icon.draw(Point(x + tile.trigger.x + tile.triggerXl/2 - icon.xl/2
                              + (20 * offset++) - 10 * (tribes.len - 1),
                            min(y, y + yl - 60)),
                      Ac.walker.acToSkillIconXf, 0);
        }
    }

    void drawNoSign() const
    {
        if (lockedWithNoSign) {
            const(Cutbit) c = getInternal(fileImageMouse);
            c.draw(Point(
                x + tile.trigger.x + tile.triggerXl / 2 - c.xl / 2,
                y + tile.trigger.y + tile.triggerYl / 2 - c.yl),
                2, 2); // (2,2) are the (xf,yf) of the international "no" sign
        }
    }
}
// end class Goal
