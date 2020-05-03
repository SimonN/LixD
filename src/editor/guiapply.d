module editor.guiapply;

import std.algorithm;
import std.range;

import basics.topology;
import editor.editor;
import editor.gui.topology;
import editor.undoable.base;
import editor.undoable.compound;
import editor.undoable.move;
import editor.undoable.topology;
import level.level;
import level.oil;
import tile.occur;

package void maybeApplyTopologyWindowResult(Editor editor)
{
    if (! __global__newResultForTheEditor) {
        return;
    }
    Undoable uOrNull = topologyChangeOrNull(editor.level,
        __global__suggestedTopologyChangeState[0],
        __global__moveAllTilesBy);
    __global__newResultForTheEditor = false;
    if (uOrNull !is null)
        editor.apply(uOrNull);
}

private Undoable topologyChangeOrNull(
    in Level l,
    in TopologyChange.State goal,
    in Point moveAllTilesBy,
) {
    Undoable[] ret;
    if (! l.topology.matches(goal.topology) || l.bgColor != goal.bgColor) {
        ret ~= new TopologyChange(TopologyChange.State(
            new immutable Topology(l.topology), l.bgColor), goal);
    }
    void appendSingleMove(const(Occurrence) occ)
    {
        immutable(Point) dest = goal.topology.wrap(occ.loc + moveAllTilesBy);
        if (dest != occ.loc) {
            ret ~= new CoordinateFix(
                cast (immutable(Oil)) Oil.makeViaLookup(l, occ),
                occ.loc, dest);
        }
    }
    l.terrain.each!appendSingleMove;
    l.gadgets[].each!(occList => occList.each!appendSingleMove);
    return ret.empty ? null : ret.toCompoundUndoable;
}
