module game.core.active;

/* calcActive evals the input and queues things to be sent through the net.
 * Game.calc() should afterwards calc the network, that flushes the network.
 */

import std.range;

import net.repdata;
import basics.rect;
import file.option; // hotkeys
import game.core.game;
import game.panel.tooltip;
import gui : SkillButton;
import hardware.mouse;
import hardware.mousecur;
import hardware.keyboard; // priority invert held
import hardware.semantic; // force left/right held
import hardware.sound;
import lix;

package:

void calcActive(Game game)
{
    game.handleNukeButton();
    if (! game.pan.isMouseHere) {
        if (mouseClickLeft)
            game.cancelReplay();
        auto potAss = game.findPotentialAssignee();
        if (hardware.mouse.mouseClickLeft && game.view.canAssignSkills)
            game.assignToPotentialAssignee(potAss);
    }
    else {
        game._drawHerHighlit = null;
        game.pan.describeTarget(null, 0);
    }
}

package void findAgainHighlitLixAfterPhyu(Game game)
{
    if (! game.pan.isMouseHere)
        game.findPotentialAssignee();
}

package ReplayData newReplayDataForNextPhyu(Game game)
{
    ReplayData data;
    data.player = game._netClient ? game._netClient.ourPlNr : PlNr(0);
    data.update = game.nurse.upd + 1;
    return data;
}

package void cancelReplay(Game game) { with (game)
{
    if (replaying && game.view.canInterruptReplays)
        nurse.cutReplay();
}}

// ############################################################################

private:

struct PotentialAssignee {
    ConstLix lixxie;
    int id;
    int priority;
    double distanceToCursor;

    // Compare lixes for, priority:
    // 1. priority number from lixxie.priorityForNewAc
    // 2. what is closer to the mouse cursor (if priority is equal)
    // 3. what has spawned earlier (if still equal)
    // Holding the priority inversion key, or right mouse button (configurable
    // in the options) inverts the sorting of (1.), but not of the others.
    // Never invert priority for unclickable lix (priority == 0 or == 1).
    bool isBetterThan(in ref PotentialAssignee rhs) const {
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

void handleNukeButton(Game game) { with (game)
{
    if (! pan.nukeDoubleclicked || ! game.view.canAssignSkills)
        return;
    pan.pause = false;
    game.cancelReplay();
    auto data = game.newReplayDataForNextPhyu();
    data.action = RepAc.NUKE;
    game.includeOurNew(data);
    assert (_effect);
    _effect.addSound(
        Phyu(nurse.upd + 1), Passport(localStyle, 0), Sound.NUKE);
}}

/* Main function to determine lix under cursor.
 * Side effect: Assigns the best lix to game._drawHerHighlit.
 */
PotentialAssignee findPotentialAssignee(Game game) { with (game)
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
    game._drawHerHighlit = best.lixxie;
    return best;
}}
// end void findPotentialAssignee()

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
    in ref PotentialAssignee potAss,
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

void assignToPotentialAssignee(
    Game game,
    in ref PotentialAssignee potAss) { with (game)
{
    SkillButton currentSkill = pan.currentSkill;
    if (potAss.lixxie is null)
        return;
    if (! currentSkill) {
        hardware.sound.playLoud(Sound.PANEL_EMPTY);
        return;
    }
    if (potAss.priority <= 1)
        return;

    assert (currentSkill.number != 0);
    if (currentSkill.number != skillInfinity)
        // Decrease the visible number on the panel. This is mostly eye candy.
        // It doesn't affect physics, including judging what's coming in over
        // the network, but it affects the assignment user interface.
        currentSkill.number = currentSkill.number - 1;

    ReplayData data = game.newReplayDataForNextPhyu();
    data.action     = forcingLeft  ? RepAc.ASSIGN_LEFT
                    : forcingRight ? RepAc.ASSIGN_RIGHT
                    :                RepAc.ASSIGN;
    data.skill      = currentSkill.skill;
    data.toWhichLix = potAss.id;
    game.includeOurNew(data);

    // React faster to the new assignment than during its evaluation next
    // update. The evaluation could be several ticks ticks later.
    assert (_effect);
    immutable pa = Passport(localStyle, potAss.id);
    _effect.addArrowDontShow(data.update, pa);
    _effect.addSound(data.update, pa, Sound.ASSIGN);

    if (file.option.unpauseOnAssign.value == true)
        pan.pause = false;
}}
// end PotentialAssignee assignToPotentialAssignee()

void includeOurNew(Game game, in ReplayData data) { with (game)
{
    undispatchedAssignments ~= data;
    if (_netClient)
        _netClient.sendReplayData(data);
}}
