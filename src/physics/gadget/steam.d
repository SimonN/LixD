module physics.gadget.steam;

import std.format;

import basics.topology;
import file.language;
import physics.gadget.gadget;
import physics.tribe;
import tile.gadtile;
import tile.occur;
import net.phyu;

alias Fire = Water;

final class Water : Gadget {
public:
    this(const(Topology) top, in GadOcc levelpos) { super(top, levelpos); }
    this(in Water rhs) { super(rhs); }
    override Water clone() const { return new Water(this); }

    override string tooltip(in Phyu now, in Tribe viewer) const nothrow @safe
    {
        return tile.type == GadType.fire
            ? Lang.tooltipFire.transl
            : Lang.tooltipWater.transl;
    }
}

final class Steam : Gadget {
public:
    this(const(Topology) top, in GadOcc levelpos) { super(top, levelpos); }
    this(in Steam rhs) { super(rhs); }
    override Steam clone() const { return new Steam(this); }

    override string tooltip(in Phyu now, in Tribe viewer) const nothrow @safe
    {
        return Lang.tooltipSteam.translf(
            tile.tooltipFlingXName, tile.tooltipFlingXValue,
            tile.tooltipFlingYName, tile.tooltipFlingYValue);
    }
}

string tooltipFlingXName(in GadgetTile tile) pure nothrow @safe @nogc
{
    return tile.flingForward ? "+"
        : tile.specialX < 0 ? "\u2190" // arrow left
        : tile.specialX > 0 ? "\u2192" // arrow right
        : "\u2194"; // double arrow left-right
}

int tooltipFlingXValue(in GadgetTile tile) pure nothrow @safe @nogc
{
    return tile.flingForward || tile.specialX >= 0
        ? tile.specialX : -tile.specialX;
}

string tooltipFlingYName(in GadgetTile tile) pure nothrow @safe @nogc
{
    return tile.specialY < 0 ? "\u2191" // arrow up
        : tile.specialX > 0 ? "\u2193" // arrow down
        : "\u2195"; // double arrow up-down
}

int tooltipFlingYValue(in GadgetTile tile) pure nothrow @safe @nogc
{
    return tile.specialY >= 0 ? tile.specialY : -tile.specialY;
}
