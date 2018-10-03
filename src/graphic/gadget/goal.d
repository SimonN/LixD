module graphic.gadget.goal;

import std.algorithm; // max
import std.math;

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
import net.repdata;

/* owners are always drawn onto the goal, unless the owner is GARDEN.
 * When overtime runs out, set drawWithNoSign.
 */

class Goal : GadgetWithTribeList {
public:
    bool lockedWithNoSign = false;

    this(const(Topology) top, in ref GadOcc levelpos) { super(top, levelpos); }
    this(in Goal rhs) { super(rhs); }
    override Goal clone() const { return new Goal(this); }

    override void drawExtrasOnTopOfLand(in Style st) const
    {
        drawOwner(st, 1);
    }

protected:
    override void drawInner() const
    {
        foreach (st; tribes) {
            drawOwner(st, 0);
        }
        drawNoSign();
    }

private:
    void drawOwner(in Style st, in int xf) const
    {
        if (lockedWithNoSign || st == Style.garden || ! tribes.canFind(st))
            return;
        int offset = tribes.countUntil(st) & 0x7FFF_FFFF;
        auto icon = graphic.internal.getGoalMarker(st);
        icon.draw(Point(x + tile.trigger.x + tile.triggerXl/2 - icon.xl/2
                          + (20 * offset++) - 10 * (tribes.len - 1),
            // Sit 12 pixels above the top of the trigger area.
            // Reason: Amanda's tent is very high, arrow should overlap tent.
            y + tile.trigger.y - icon.yl - 12), xf, 0);
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
