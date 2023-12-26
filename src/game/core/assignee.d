module game.core.assignee;

import std.range;

import optional;

import basics.rect;
import opt = file.option.allopts; // hotkeys
import game.core.game;
import game.panel.tooltip;
import gui : SkillButton;
import hardware.mousecur;
import hardware.keyboard; // priority invert held
import net.ac;
import physics.lixxie.fields;
import physics.lixxie.lixxie;

struct Assignee {
    ConstLix lixxie; // Should never be null. Use Optional!Assignee otherwise.
    int id;
    int priority;
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
        return facingOkay && ! rhs.facingOkay ? true
            : ! facingOkay && rhs.facingOkay ? false
            : priority <= 1 && rhs.priority > 1 ? false
            : priority >  1 && rhs.priority <= 1 ? true
            : priority > rhs.priority ? ! opt.keyPriorityInvert.keyHeld
            : priority < rhs.priority ?   opt.keyPriorityInvert.keyHeld
            : distanceToCursor < rhs.distanceToCursor ? true
            : distanceToCursor > rhs.distanceToCursor ? false
            : id < rhs.id;
    }
}

bool forcingLeft() nothrow @safe @nogc
{
    return opt.keyForceLeft.keyHeld && ! opt.keyForceRight.keyHeld;
}

bool forcingRight() nothrow @safe @nogc
{
    return opt.keyForceRight.keyHeld && ! opt.keyForceLeft.keyHeld;
}

struct UnderCursor {
    Optional!Assignee best = no!Assignee;
    int numLix = 0;
    Tooltip.IdSet goodTooltips; // Suggestions for how to assign to hindmost.
}

UnderCursor findUnderCursor(
    Game game,
    in Ac chosenInPanel,
) {
    if (! game.isMouseOnLand) {
        return UnderCursor();
    }
    assert (game.localTribe);
    UnderCursor ret;

    assert (game.map.zoom > 0);
    immutable float cursorThicknessOnLand = 12 / game.map.zoom;
    immutable float mmldX = cursorThicknessOnLand +  2; // + lix thickness
    immutable float mmldU = cursorThicknessOnLand + 15; // + lix height
    immutable float mmldD = cursorThicknessOnLand +  0;
    immutable mol = game.map.mouseOnLand;

    foreach (id, ConstLix lixxie; game.localTribe.lixvec.enumerate!int) {
        immutable int distX = game.map.topology.distanceX(lixxie.ex, mol.x);
        immutable int distY = game.map.topology.distanceY(lixxie.ey, mol.y);
        if (   distX <= mmldX && distX >= -mmldX
            && distY <= mmldD && distY >= -mmldU
            && lixxie.cursorShouldOpenOverMe
        ) {
            ++ret.numLix;
            Assignee a = game.generateAssignee(
                chosenInPanel, lixxie, id, mol, mmldD - mmldU);
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
        // end if under cursor
    }
    // end loop through all lixes
    if (! ret.best.empty) {
        ret.goodTooltips |= tooltipsForTheBest(ret.best.front, chosenInPanel);
    }
    return ret;
}

// ############################################################################

private:

Assignee generateAssignee(
    Game game,
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
    ret.distanceToCursor = game.map.topology.hypotSquared(
        mouseOnLand.x, mouseOnLand.y, lixxie.ex,
                                      lixxie.ey + roundInt(dMinusU/2));
    ret.priority = lixxie.priorityForNewAc(chosenInPanel);
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
    if (best.priority != worse.priority && ! opt.keyPriorityInvert.keyHeld) {
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
