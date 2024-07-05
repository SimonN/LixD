module graphic.gadget.goal;

import std.algorithm; // max
import std.math;

import basics.globals; // fileImageMouse
import basics.help; // len
import basics.styleset;
import basics.topology;
import graphic.cutbit;
import graphic.gadget;
import graphic.internal;
import graphic.torbit;
import net.ac;
import net.repdata;
import physics.tribe;
import tile.occur;

/* owners are always drawn onto the goal, unless the owner is GARDEN.
 * When overtime runs out, set drawWithNoSign.
 */

class Goal : Gadget {
private:
    StyleSet _owners;

public:
    this(const(Topology) top, in GadOcc levelpos) { super(top, levelpos); }
    this(in Goal rhs) { super(rhs); }
    override Goal clone() const { return new Goal(this); }

    void addOwner(in Style st) pure nothrow @safe @nogc { _owners.insert(st); }
    bool hasOwner(in Style st) const pure nothrow @safe @nogc
    {
        return _owners.contains(st);
    }

    override void drawExtrasOnTopOfLand(in Style st) const
    {
        drawOwner(st, 2);
    }

    void drawNoSign() const
    {
        const(Cutbit) c = InternalImage.mouse.toCutbit;
        c.draw(Point(
            this.loc.x + tile.trigger.x + tile.triggerXl / 2 - c.xl / 2,
            this.loc.y + tile.trigger.y + tile.triggerYl / 2 - c.yl),
            2, 2); // (2,2) are the (xf,yf) of the international "no" sign
    }

protected:
    override void onDraw(in Phyu now, in Style markWithArrow) const
    {
        foreach (st; _owners[]) {
            drawOwner(st, _owners.contains(markWithArrow) ? 1 : 0);
        }
    }

private:
    void drawOwner(in Style st, in int xf) const
    {
        if (st == Style.garden || ! _owners.contains(st))
            return;
        immutable int offset = _owners[].countUntil(st) & 0x7FFF_FFFF;
        auto icon = Spritesheet.goalMarkers.toCutbitFor(st);
        icon.draw(Point(this.loc.x + tile.trigger.x
            + tile.triggerXl/2 - icon.xl/2
            + 20 * offset - 10 * (_owners.len - 1),
            // Sit 12 pixels above the top of the trigger area.
            // Reason: Amanda's tent is very high, arrow should overlap tent.
            this.loc.y + tile.trigger.y - icon.yl - 12), xf, 0);
    }
}
