module game.core.highli;

import std.range;

import basics.rect;
import file.option; // hotkeys
import game.core.game;
import game.panel.tooltip;
import gui : SkillButton;
import hardware.mousecur;
import hardware.keyboard; // priority invert held
import hardware.semantic; // force left/right held
import lix;

struct PotentialAssignee {
    ConstLix lixxie;
    int id;
    int priority;
    double distanceToCursor;

    Passport passport() const pure nothrow @safe @nogc
    in { assert (lixxie !is null); }
    do { return Passport(lixxie.style, id); }

    // Compare lixes for, priority:
    // 1. priority number from lixxie.priorityForNewAc
    // 2. what is closer to the mouse cursor (if priority is equal)
    // 3. what has spawned earlier (if still equal)
    // Holding the priority inversion key, or right mouse button (configurable
    // in the options) inverts the sorting of (1.), but not of the others.
    // Never invert priority for unclickable lix (priority == 0 or == 1).
    bool isBetterThan(in PotentialAssignee rhs) const {
        return lixxie    is null ? false
            : rhs.lixxie is null ? true
            : priority <= 1 && rhs.priority >  1 ? false
            : priority >  1 && rhs.priority <= 1 ? true
            : priority > rhs.priority ? ! keyPriorityInvert.keyHeld
            : priority < rhs.priority ?   keyPriorityInvert.keyHeld
            : distanceToCursor < rhs.distanceToCursor ? true
            : distanceToCursor > rhs.distanceToCursor ? false
            : id < rhs.id;
    }
}

PotentialAssignee findAndDescribePotentialAssignee(Game game)
{
    if (game.isMouseOnLand) {
        return game.findPotentialAssigneeAssumingMouseOnLand();
    }
    game.pan.describeTarget(null, 0);
    return PotentialAssignee(null);
}

// ############################################################################

private:

/* Main function to determine lix under cursor.
 * Side effect: Calls pan.describeTarget with some other than the returned.
 */
PotentialAssignee findPotentialAssigneeAssumingMouseOnLand(Game game) { with (game)
{
    assert (localTribe);

    PotentialAssignee best; // clicks go to her, priority is already considered
    PotentialAssignee worst; // if different from best, make tooltip
    PotentialAssignee described; // her action is described on the panel
    int lixesUnderCursor = 0;
    bool leftFound  = false; // if both left/right true,
    bool rightFound = false; // make a tooltip

    const(SkillButton) currentSkill = game.pan.currentSkill;
    assert (map.zoom > 0);

    immutable float cursorThicknessOnLand = 12 / map.zoom;
    immutable float mmldX = cursorThicknessOnLand +  2; // + lix thickness
    immutable float mmldU = cursorThicknessOnLand + 15; // + lix height
    immutable float mmldD = cursorThicknessOnLand +  0;
    immutable mol = map.mouseOnLand;

    foreach (id, ConstLix lixxie; localTribe.lixvec.enumerate!int) {
        immutable int distX = map.distanceX(lixxie.ex, mol.x);
        immutable int distY = map.distanceY(lixxie.ey, mol.y);
        if (   distX <= mmldX && distX >= -mmldX
            && distY <= mmldD && distY >= -mmldU
            && lixxie.cursorShouldOpenOverMe
        ) {
            ++lixesUnderCursor;
            PotentialAssignee potAss = game.generatePotentialAssignee(
                lixxie, id, mol, mmldD - mmldU, currentSkill);
            if (potAss.isBetterThan(described)) {
                described = potAss;
            }
            comparePotentialWithBestWorst(potAss, best, worst,
                leftFound, rightFound);
        }
        // end if under cursor
    }
    // end loop through all lixes

    if (best.lixxie !is null && leftFound && rightFound)
        pan.suggestTooltip(best.lixxie.facingLeft ? Tooltip.ID.forceRight
                                                  : Tooltip.ID.forceLeft);
    else if (best.priority != worst.priority && ! keyPriorityInvert.keyHeld)
        pan.suggestTooltip(Tooltip.ID.priorityInvert);

    mouseCursor.xf = (forcingLeft ? 1 : forcingRight ? 2 : mouseCursor.xf);
    mouseCursor.yf = best.lixxie !is null;
    pan.describeTarget(described.lixxie, lixesUnderCursor);

    if (best.lixxie !is null && currentSkill !is null) {
        if (best.lixxie.ac == Ac.builder)
            pan.suggestTooltip(Tooltip.ID.queueBuilder);
        else if (best.lixxie.ac == Ac.platformer)
            pan.suggestTooltip(Tooltip.ID.queuePlatformer);
    }
    return best;
}}

PotentialAssignee generatePotentialAssignee(
    Game game,
    in Lixxie lixxie,
    in int id,
    in Point mouseOnLand,
    in float dMinusU,
    in SkillButton currentSkill
) {
    import basics.help;
    PotentialAssignee potAss;
    potAss.lixxie = lixxie;
    potAss.id = id;
    potAss.distanceToCursor = game.map.hypotSquared(
        mouseOnLand.x, mouseOnLand.y, lixxie.ex,
                                      lixxie.ey + roundInt(dMinusU/2));
    potAss.priority = currentSkill !is null
        ? lixxie.priorityForNewAc(currentSkill.skill) : 1;

    return potAss;
}

void comparePotentialWithBestWorst(
    in PotentialAssignee potAss,
    ref PotentialAssignee best,
    ref PotentialAssignee worst,
    ref bool anyFoundLeft,
    ref bool anyFoundRight,
) {
    assert (potAss.lixxie !is null);
    immutable bool eligibleAccordingToDirSelect =
           ! (potAss.lixxie.facingLeft  && forcingRight)
        && ! (potAss.lixxie.facingRight && forcingLeft);

    if (eligibleAccordingToDirSelect) {
        anyFoundLeft = anyFoundLeft || potAss.lixxie.facingLeft;
        anyFoundRight = anyFoundRight || potAss.lixxie.facingRight;
        if (potAss.isBetterThan(best))
            best = potAss;
        if (worst.lixxie is null || worst.isBetterThan(potAss))
            worst = potAss;
    }
}
