module game.core.active;

/* calcActive evals the input and queues things to be sent through the net.
 * Game.calc() should afterwards calc the network, that flushes the network.
 */

import optional;

import opt = file.option.allopts;
import file.replay;
import game.core.assignee;
import game.core.game;
import hardware.sound;
import hardware.mouse;
import net.repdata;
import physics.lixxie.fields;

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
    if (game.view.canInterruptReplays) {
        game.nurse.cutGlobalFutureFromReplay();
    }
    auto data = game.newPlyForNextPhyu(localStyle);
    data.isNuke = true;
    game.includeOurNew(data);
    assert (_effect);
    _effect.addSound(Phyu(nurse.now + 1), Passport(localStyle, 0), Sound.NUKE);
}}

void calcClicksIntoMap(Game game, UnderCursor found)
in {
    assert (!game.modalWindow);
}
do {
    if (! hardware.mouse.mouseClickLeft
        || ! game.isMouseOnLand
        || ! game.view.canAssignSkills
    ) {
        return;
    }
    if (found.best.empty) {
        if (game.canWeClickAirNowToCutGlobalFuture) {
            game.nurse.cutGlobalFutureFromReplay();
        }
        return;
    }
    if (game.canAssignTo(found.best.front)) {
        game.resolveClickThatWillAssign(found.best.front);
        return;
    }
    if (game.view.canAssignSkills && game.pan.chosenSkill == Ac.nothing) {
        hardware.sound.playLoud(Sound.PANEL_EMPTY);
    }
}

void resolveClickThatWillAssign(Game game, Assignee assignee)
{
    if (game.view.canInterruptReplays) {
        if (game.isInsertMode) {
            game.cutSingleLixFutureFromReplay(assignee.passport);
        }
        else {
            game.nurse.cutGlobalFutureFromReplay();
        }
    }
    game.assignTo(assignee);
    if (opt.unpauseOnAssign.value) {
        game.pan.pause = false;
    }
}

void cutSingleLixFutureFromReplay(Game game, in Passport ofWhom)
{
    assert (game.view == View.solveAlone,
        "We're adding PlNr(0) to the ply. This will fail View.solveTogether."
        ~ " If we ever implement solveTogether, add more logic here and"
        ~ " also support that in the replay's ChangeRequest.");
    game.nurse.tweakReplayRecomputePhysics(ChangeRequest(
        Ply(PlNr(0), game.nurse.now, false, Ac.nothing, ofWhom.id),
        ChangeVerb.cutFutureOfOneLix));
}

// ############################################################################

private:

bool canAssignTo(Game game, in Assignee foundLix)
{
    return game.view.canAssignSkills
        && game.pan.chosenSkill != Ac.nothing
        && foundLix.facingOkay
        && foundLix.prio.isAssignable
        && ! game.localTribe.hasNuked;
}

Ply newPlyForNextPhyu(Game game, in Style styleOfAssignee)
{
    Ply ret;
    ret.by = game.bestPlNrForAssignmentTo(styleOfAssignee);
    ret.when = game.nurse.now + 1;
    return ret;
}

PlNr bestPlNrForAssignmentTo(Game game, in Style styleOfAssignee)
{
    if (game._netClient !is null) {
        return game._netClient.ourPlNr;
    }
    if (styleOfAssignee == Style.garden) {
        return PlNr(0); // Conventional player number for singleplayer.
    }
    assert (game.view.canSeeEverybodysSkillsets, "By now, if we can't see/use"
        ~ " other skillsets, we should have returned a good PlNr.");
    foreach (plNr, prof; game.replay.players) {
        if (prof.style == styleOfAssignee && prof.name == opt.userName) {
            return plNr;
        }
    }
    foreach (plNr, prof; game.replay.players) {
        if (prof.style == styleOfAssignee) {
            return plNr; // We're editing a replay for an opponent.
        }
    }
    assert (false, "No suitable PlNr in the replays.");
}

bool alwaysForceWhenAssigning(in Ac ac) pure nothrow @safe @nogc
{
    return ac == Ac.walker
        || ac == Ac.jumper
        || ac == Ac.batter
        || ac == Ac.builder
        || ac == Ac.platformer
        || ac == Ac.basher
        || ac == Ac.miner;
}

void assignTo(Game game, in Assignee assignee)
in {
    assert (game.pan.chosenSkillButtonOrNull !is null,
    "Don't call assignTo() then.");
}
do { with (game)
{
    Ply i = game.newPlyForNextPhyu(assignee.lixxie.style);
    i.skill = game.pan.chosenSkill;
    i.toWhichLix = assignee.id;
    i.isDirectionallyForced
        = alwaysForceWhenAssigning(i.skill) || forcingLeft || forcingRight;
    i.lixShouldFace = assignee.lixxie.facingLeft
        ? Ply.LixShouldFace.left : Ply.LixShouldFace.right;

    if (game.pan.chosenSkillButtonOrNull.number != skillInfinity) {
        // Decrease the visible number on the panel. This is mostly eye candy.
        // It doesn't affect physics, including judging what's coming in over
        // the network, but it affects the assignment user interface.
        game.pan.chosenSkillButtonOrNull.number
            = game.pan.chosenSkillButtonOrNull.number - 1;
    }
    game.includeOurNew(i);

    // React faster to the new assignment than during its evaluation next
    // update. The evaluation could be several ticks ticks later.
    assert (game._effect);
    _effect.addAssignment(i.when, assignee.passport,
        assignee.lixxie.foot, i.skill, Sound.assignByClick);
}}

void includeOurNew(Game game, in Ply data) { with (game)
{
    undispatchedAssignments ~= data;
    if (_netClient)
        _netClient.sendPly(data);
}}
