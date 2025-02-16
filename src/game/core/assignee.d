module game.core.assignee;

import std.range;

import optional;

import basics.rect;
import opt = file.option.allopts; // hotkeys
import game.core.game;
import graphic.camera.mapncam;
import game.panel.tooltip;
import gui : SkillButton;
import hardware.mousecur;
import hardware.keyboard; // priority invert held
import net.ac;
import physics.lixxie.fields;
import physics.lixxie.lixxie;
import physics.tribe;

struct Assignee {
    ConstLix lixxie; // Should never be null. Use Optional!Assignee otherwise.
    int id;
    Priority prio;
    double distanceToCursor;

    bool facingOkay() const nothrow @safe @nogc
    {
        return ! (lixxie.facingLeft && forcingRight)
            && ! (lixxie.facingRight && forcingLeft);
    }

    Passport passport() const pure nothrow @safe @nogc
    in { assert (lixxie !is null, "Wrap nulls in Optional!Assignee."); }
    do { return Passport(lixxie.style, id); }

    // Compare lixes for, priority:
    // 1. priority number from lixxie.priorityForNewAc
    // 2. what is closer to the mouse cursor (if priority is equal)
    // 3. what has spawned earlier (if still equal)
    // Holding the priority inversion key, or right mouse button (configurable
    // in the options) inverts the sorting of (1.), but not of the others.
    // Never invert priority for unclickable lix (priority == 0 or == 1).
    bool isBetterThan(in Assignee rhs) const nothrow @safe @nogc {
        return facingOkay != rhs.facingOkay ? facingOkay
            : prio.isAssignable != rhs.prio.isAssignable ? prio.isAssignable
            : prio > rhs.prio ? ! opt.keyPriorityInvert.isHeld
            : prio < rhs.prio ?   opt.keyPriorityInvert.isHeld
            : distanceToCursor < rhs.distanceToCursor ? true
            : distanceToCursor > rhs.distanceToCursor ? false
            : id < rhs.id;
    }
}

bool forcingLeft() nothrow @safe @nogc
{
    return opt.keyForceLeft.isHeld && ! opt.keyForceRight.isHeld;
}

bool forcingRight() nothrow @safe @nogc
{
    return opt.keyForceRight.isHeld && ! opt.keyForceLeft.isHeld;
}

struct UnderCursor {
    Optional!Assignee best = no!Assignee;
    int numLix = 0; // numLix == 0 if and only if best.empty.
    Tooltip.IdSet goodTooltips; // Suggestions for how to assign to hindmost.
}

UnderCursor findUnderCursor(
    Game game,
    in Ac chosenInPanel,
) {
    if (! game.isMouseOnLand) {
        return UnderCursor();
    }
    auto ret = findUnderCursor(game.map, game.localTribe, chosenInPanel);
    if (! game.view.canSeeEverybodysSkillsets) {
        return ret;
    }
    // When observing multiplayer or playtesting n-player maps alone:
    foreach (tri; game.cs.tribes.playerTribes) {
        if (tri.style == game.localStyle) {
            continue; // We've already searched this tribe above.
        }
        auto forSty = findUnderCursor(game.map, tri, chosenInPanel);
        if (forSty.numLix > 0 && (ret.best.empty
            || forSty.best.front.isBetterThan(ret.best.front))
        ) {
            ret = forSty;
        }
    }
    return ret;
}

// ############################################################################

private:

UnderCursor findUnderCursor(
    const(MapAndCamera) gameMap,
    const(Tribe) fromTribe,
    in Ac chosenInPanel,
) {
    UnderCursor ret;
    assert (gameMap.zoom > 0);
    immutable float cursorThicknessOnLand = 12 / gameMap.zoom;
    immutable float mmldX = cursorThicknessOnLand +  2; // + lix thickness
    immutable float mmldU = cursorThicknessOnLand + 15; // + lix height
    immutable float mmldD = cursorThicknessOnLand +  0;
    immutable mol = gameMap.mouseOnLand;

    foreach (id, ConstLix lixxie; fromTribe.lixvec.enumerate!int) {
        if (! lixxie.cursorShouldOpenOverMe)
            continue;
        immutable int distX = gameMap.topology.distanceX(lixxie.ex, mol.x);
        if (distX < -mmldX || distX > mmldX)
            continue;
        immutable int distY = gameMap.topology.distanceY(lixxie.ey, mol.y);
        if (distY < -mmldU || distY > mmldD)
            continue;

        // We found a lix under the cursor.
        ++ret.numLix;
        Assignee a = generateAssignee(
            gameMap, chosenInPanel, lixxie, id, mol, mmldD - mmldU);
        if (ret.best.empty) {
            ret.best = a;
        }
        else if (a.isBetterThan(ret.best.front)) {
            ret.goodTooltips |= tooltipsFor1Surpassing2(a, ret.best.front);
            ret.best = a;
        }
        else {
            ret.goodTooltips |= tooltipsFor1Surpassing2(ret.best.front, a);
        }
    }
    // end loop through all lixes
    if (! ret.best.empty) {
        ret.goodTooltips |= tooltipsForTheBest(ret.best.front, chosenInPanel);
    }
    return ret;
}

Assignee generateAssignee(
    const(MapAndCamera) onMap,
    in Ac chosenInPanel,
    in ConstLix lixxie,
    in int id,
    in Point mouseOnLand,
    in float dMinusU,
) {
    import basics.help;
    Assignee ret;
    ret.lixxie = lixxie;
    ret.id = id;
    ret.distanceToCursor = onMap.topology.hypotSquared(
        mouseOnLand.x, mouseOnLand.y, lixxie.ex,
                                      lixxie.ey + roundInt(dMinusU/2));
    ret.prio = lixxie.priorityForNewAc(chosenInPanel);
    return ret;
}

Tooltip.IdSet tooltipsFor1Surpassing2(in Assignee best, in Assignee worse)
{
    Tooltip.IdSet ret = 0;
    if (best.lixxie.facingLeft && worse.lixxie.facingRight) {
        ret |= Tooltip.ID.forceRight;
    }
    else if (best.lixxie.facingRight && worse.lixxie.facingLeft) {
        ret |= Tooltip.ID.forceLeft;
    }
    if (best.prio != worse.prio && ! opt.keyPriorityInvert.isHeld) {
        ret |= Tooltip.ID.priorityInvert;
    }
    return ret;
}

Tooltip.IdSet tooltipsForTheBest(in Assignee best, in Ac chosenInPanel)
{
    if (best.lixxie.ac != chosenInPanel) {
        return 0;
    }
    return chosenInPanel == Ac.builder ? Tooltip.ID.queueBuilder
        : chosenInPanel == Ac.platformer ? Tooltip.ID.queuePlatformer
        : 0;
}
