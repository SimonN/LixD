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
import hardware.semantic; // force left/right held
import net.ac;
import physics.lixxie.fields;
import physics.lixxie.lixxie;

struct Assignee {
    ConstLix lixxie; // Should never be null. Use Optional!Assignee otherwise.
    int id;
    int priority;
    double distanceToCursor;

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
    bool isBetterThan(in Assignee rhs) const {
        return priority <= 1 && rhs.priority > 1 ? false
            : priority >  1 && rhs.priority <= 1 ? true
            : priority > rhs.priority ? ! opt.keyPriorityInvert.keyHeld
            : priority < rhs.priority ?   opt.keyPriorityInvert.keyHeld
            : distanceToCursor < rhs.distanceToCursor ? true
            : distanceToCursor > rhs.distanceToCursor ? false
            : id < rhs.id;
    }
}

Optional!Assignee findAndDescribePotentialAssignee(Game game)
{
    if (game.isMouseOnLand) {
        return game.findPotentialAssigneeAssumingMouseOnLand();
    }
    game.pan.describeTarget(null, Passport(), 0);
    return no!Assignee;
}

// ############################################################################

private:

/* Main function to determine lix under cursor.
 * Side effect: Calls pan.describeTarget with some other than the returned.
 */
Optional!Assignee findPotentialAssigneeAssumingMouseOnLand(Game game)
{ with (game)
{
    assert (localTribe);

    Optional!Assignee best; // clicks go to her, priority is already considered
    Optional!Assignee worst; // if different from best, make tooltip
    Optional!Assignee described; // her action is described on the panel
    int lixesUnderCursor = 0;
    bool leftFound  = false; // if both left/right true,
    bool rightFound = false; // make a tooltip

    assert (map.zoom > 0);
    immutable float cursorThicknessOnLand = 12 / map.zoom;
    immutable float mmldX = cursorThicknessOnLand +  2; // + lix thickness
    immutable float mmldU = cursorThicknessOnLand + 15; // + lix height
    immutable float mmldD = cursorThicknessOnLand +  0;
    immutable mol = map.mouseOnLand;

    foreach (id, ConstLix lixxie; localTribe.lixvec.enumerate!int) {
        immutable int distX = map.topology.distanceX(lixxie.ex, mol.x);
        immutable int distY = map.topology.distanceY(lixxie.ey, mol.y);
        if (   distX <= mmldX && distX >= -mmldX
            && distY <= mmldD && distY >= -mmldU
            && lixxie.cursorShouldOpenOverMe
        ) {
            ++lixesUnderCursor;
            Assignee a = game.generateAssignee(
                lixxie, id, mol, mmldD - mmldU);
            described = described.empty || a.isBetterThan(described.front)
                ? some(a) : described;
            comparePotentialWithBestWorst(a, best, worst,
                leftFound, rightFound);
        }
        // end if under cursor
    }
    // end loop through all lixes

    if (! best.empty && leftFound && rightFound)
        _panelExplainer.suggestTooltip(best.front.lixxie.facingLeft
            ? Tooltip.ID.forceRight : Tooltip.ID.forceLeft);
    else if (! best.empty && ! worst.empty
        && best.front.priority != worst.front.priority
        && ! opt.keyPriorityInvert.keyHeld
    ) {
        _panelExplainer.suggestTooltip(Tooltip.ID.priorityInvert);
    }
    mouseCursor.xf = (forcingLeft ? 1 : forcingRight ? 2 : mouseCursor.xf);
    mouseCursor.yf = ! best.empty;
    pan.describeTarget(
        described.empty ? null : described.front.lixxie,
        described.empty ? Passport() : described.front.passport,
        lixesUnderCursor);

    if (! best.empty && best.front.lixxie.ac == game.pan.chosenSkill) {
        if (best.front.lixxie.ac == Ac.builder)
            _panelExplainer.suggestTooltip(Tooltip.ID.queueBuilder);
        else if (best.front.lixxie.ac == Ac.platformer)
            _panelExplainer.suggestTooltip(Tooltip.ID.queuePlatformer);
    }
    return best;
}}

Assignee generateAssignee(
    Game game,
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
    ret.priority = lixxie.priorityForNewAc(game.pan.chosenSkill);
    return ret;
}

void comparePotentialWithBestWorst(
    Assignee a,
    ref Optional!Assignee best,
    ref Optional!Assignee worst,
    ref bool anyFoundLeft,
    ref bool anyFoundRight,
) {
    const ConstLix li = a.lixxie;
    assert (li !is null);
    if (li.facingLeft && forcingRight || li.facingRight && forcingLeft) {
        return;
    }
    anyFoundLeft = anyFoundLeft || li.facingLeft;
    anyFoundRight = anyFoundRight || li.facingRight;
    best = best.empty || a.isBetterThan(best.front) ? some(a) : best;
    worst = worst.empty || a.isBetterThan(worst.front) ? worst : some(a);
}

