module game.core.active;

/* calcActive evals the input and queues things to be sent through the net.
 * Game.calc() should afterwards calc the network, that flushes the network.
 */

import net.repdata;
static import file.option; // unpause on assign
import game.core.game;
import game.core.highli : PotentialAssignee;
import hardware.sound;
import hardware.mouse;
import hardware.semantic;
import lix;

package:

void calcNukeButton(Game game)
in {
    assert (!game.modalWindow);
    assert (game.view.canAssignSkills);
}
do { with (game)
{
    if (! pan.nukeDoubleclicked)
        return;
    pan.pause = false;
    game.cutGlobalFutureFromReplay();
    auto data = game.newPlyForNextPhyu();
    data.action = RepAc.NUKE;
    game.includeOurNew(data);
    assert (_effect);
    _effect.addSound(
        Phyu(nurse.upd + 1), Passport(localStyle, 0), Sound.NUKE);
}}

void calcClicksIntoMap(Game game, PotentialAssignee potAss)
in {
    assert (!game.modalWindow);
    assert (game.view.canAssignSkills);
}
do {
    if (! hardware.mouse.mouseClickLeft || ! game.isMouseOnLand) {
        return;
    }
    else if (game.canAssignTo(potAss)) {
        game.cutReplayAccordingToOptions(potAss.passport);
        game.assignTo(potAss);
        if (file.option.unpauseOnAssign.value == true) {
            game.pan.pause = false;
        }
    }
    else if (potAss.lixxie is null) {
        game.cutGlobalFutureFromReplay(); // We've clicked air, not a lix.
    }
    else if (game.view.canAssignSkills && game.pan.currentSkill is null) {
        hardware.sound.playLoud(Sound.PANEL_EMPTY);
    }
}

void cutReplayAccordingToOptions(Game game, in Passport ofWhom)
{
    if (! game.view.canInterruptReplays) {
        return;
    }
    if (file.option.replayAlwaysInsert.value == true) {
        game.nurse.cutSingleLixFutureFromReplay(ofWhom);
    }
    else {
        game.nurse.cutGlobalFutureFromReplay();
    }
}

void cutGlobalFutureFromReplay(Game game)
{
    if (game.view.canInterruptReplays) {
        game.nurse.cutGlobalFutureFromReplay();
    }
}

// ############################################################################

private:

bool canAssignTo(Game game, in PotentialAssignee potAss)
{
    return game.view.canAssignSkills
        && game.pan.currentSkill !is null
        && potAss.lixxie !is null
        && potAss.priority >= 2;
}

Ply newPlyForNextPhyu(Game game)
{
    Ply data;
    data.player = game._netClient ? game._netClient.ourPlNr : PlNr(0);
    data.update = game.nurse.upd + 1;
    return data;
}

void assignTo(Game game, in PotentialAssignee potAss)
in { assert (game.canAssignTo(potAss)); }
do { with (game)
{
    Ply theAssignment = game.newPlyForNextPhyu();
    theAssignment.action = forcingLeft ? RepAc.ASSIGN_LEFT
        : forcingRight ? RepAc.ASSIGN_RIGHT
        : RepAc.ASSIGN;
    theAssignment.skill = game.pan.currentSkill.skill;
    theAssignment.toWhichLix = potAss.id;

    if (game.pan.currentSkill.number != skillInfinity) {
        // Decrease the visible number on the panel. This is mostly eye candy.
        // It doesn't affect physics, including judging what's coming in over
        // the network, but it affects the assignment user interface.
        game.pan.currentSkill.number = game.pan.currentSkill.number - 1;
    }
    game.includeOurNew(theAssignment);

    // React faster to the new assignment than during its evaluation next
    // update. The evaluation could be several ticks ticks later.
    assert (game._effect);
    game._effect.addArrowDontShow(theAssignment.update, potAss.passport);
    game._effect.addSound(theAssignment.update, potAss.passport, Sound.ASSIGN);
}}

void includeOurNew(Game game, in Ply data) { with (game)
{
    undispatchedAssignments ~= data;
    if (_netClient)
        _netClient.sendPly(data);
}}
