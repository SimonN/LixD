module game.core.active;

/* calcActive evals the input and queues things to be sent through the net.
 * Game.calc() should afterwards calc the network, that flushes the network.
 */

import std.typecons : Rebindable;

import net.repdata;
import basics.rect;
import basics.user; // hotkeys
import game.core.game;
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
        if (potAss.lixxie !is null && hardware.mouse.mouseClickLeft
                                   && game.view.canAssignSkills)
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
    data.player = game.plNrLocal;
    data.update = game.nurse.upd + 1;
    return data;
}

package void cancelReplay(Game game) { with (game)
{
    if (replaying && game.view.canInterruptReplays) {
        _replayNeverCancelledThereforeDontSaveAutoReplay = false;
        nurse.cutReplay();
        playLoud(Sound.SCISSORS);
    }
}}

// ############################################################################

private:

struct PotentialAssignee {
    Rebindable!(const(Lixxie)) lixxie;
    int id;
    int priority;
    double distanceToCursor;

    // Compare lixes for, priority:
    // 1. priority number from lixxie.priorityForNewAc
    // 2. what is closer to the mouse cursor (if priority is equal)
    // 3. what has spawned earlier (if still equal)
    // Holding the priority inversion key, or right mouse button (configurable
    // in the options) inverts the sorting of (1.), but not of the others.
    bool isBetterThan(in ref PotentialAssignee rhs) const {
        return lixxie    is null ? false
            : rhs.lixxie is null ? true
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
    pan.nuke = true;
    pan.pause = false;
    game.cancelReplay();
    auto data = game.newReplayDataForNextPhyu();
    data.action = RepAc.NUKE;
    game.includeOurNew(data);
    assert (_effect);
    _effect.addSound(Phyu(nurse.upd + 1), localTribe.style, 0, Sound.NUKE);
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

    // DTODO: Find out why we were traversing the lixvec backwards in C++
    // for (LixIt i =  --trlo->lixvec.end(); i != --trlo->lixvec.begin(); --i)
    foreach (int id, const(Lixxie) lixxie; localTribe.lixvec) {
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

    if (best.lixxie !is null && best.lixxie !is worst.lixxie)
        {} // DTODOTOOLTIPS: pan.stats.suggestTooltipPriorityInvert();
    if (leftFound && rightFound)
        {} // DTODOTOOLTIPS: pan.stats.suggestTooltipForceDirection();

    mouseCursor.xf = (forcingLeft ? 1 : forcingRight ? 2 : mouseCursor.xf);
    mouseCursor.yf = (lixesUnderCursor > 0);
    pan.describeTarget(described.lixxie, lixesUnderCursor);

    if (best.lixxie !is null
        && currentSkill !is null
        && currentSkill.number != 0
        && currentSkill.skill == best.lixxie.ac
    ) {
        if (best.lixxie.ac == Ac.builder)
            {} // DTODOTOOLTIPS: pan.stats.suggestTooltipBuilders();
        else if (best.lixxie.ac == Ac.platformer)
            {} // DTODOTOOLTIPS: pan.stats.suggestTooltipPlatformers();
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
    if (currentSkill !is null)
        // true = consider personal settings like multiple builders
        potAss.priority = lixxie.priorityForNewAc(currentSkill.skill);
    else
        // we shouldn't need it, leftover from C++
        potAss.priority = 1;

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

    if (potAss.priority <= 1)
        // This function is only concerned with possible assignments,
        // not with who should be counted on the panel even if unassignable.
        return;

    immutable bool eligibleAccordingToDirSelect =
           ! (potAss.lixxie.facingLeft  && forcingRight)
        && ! (potAss.lixxie.facingRight && forcingLeft);

    if (eligibleAccordingToDirSelect) {
        if (potAss.isBetterThan(best))
            best = potAss;
        if (worst.isBetterThan(potAss))
            worst = potAss;
    }
}

void assignToPotentialAssignee(
    Game game,
    in ref PotentialAssignee potAss) { with (game)
{
    SkillButton currentSkill = pan.currentSkill;
    if (potAss.lixxie is null
        || currentSkill is null
        || currentSkill.number == 0
    ) {
        hardware.sound.playLoud(Sound.PANEL_EMPTY);
        return;
    }
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
    _effect.addArrowDontShow(data.update, localStyle, potAss.id);
    _effect.addSound(        data.update, localStyle, potAss.id, Sound.ASSIGN);

    if (basics.user.pausedAssign.value == 2)
        pan.pause = false;
}}
// end PotentialAssignee assignToPotentialAssignee()

void includeOurNew(Game game, in ReplayData data) { with (game)
{
    undispatchedAssignments ~= data;
    if (_netClient)
        _netClient.sendReplayData(data);
}}
