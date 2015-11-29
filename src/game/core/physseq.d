module game.core.physseq;

/* Updating the game physics. This usually happens 15 times per second.
 * With fast forward, it's called more often; during pause, never.
 */

import basics.help : len;
import basics.cmdargs : Runmode;
import basics.nettypes;
import game.core;
import graphic.gadget;
import hardware.sound;
import lix;

static import basics.user; // draw arrows or not

// This should be called on a regular basis to advance physics, while
// syncing things that must be done immediately before the advancement.
package void
syncNetworkThenUpdateOnce(Game game)
{
    game.putSpawnintChangesIntoReplay();
    game.putUndispatchedAssignmentsIntoReplay();
    game.putNetworkDataIntoReplay();

    game.updateOnceWithoutSyncingNetwork();
}



// This is the main function that gets executed once per physics update.
package void
updateOnceWithoutSyncingNetwork(Game game)
{
    assert (game);
    assert (game.cs);

    ++game.cs.update;

    game.evaluateReplayData();
    game.updateClock();
    game.spawnLixxiesFromHatches();
    game.updateNuke();
    game.updateLixxies();
    game.finalizeUpdateAnimateGadgets();

    if (game.runmode == Runmode.INTERACTIVE)
        game.considerMakingAutoSavestate();
}



package void
finalizeUpdateAnimateGadgets(Game game) {
    with (game)
    with (game.cs)
{
    // Animate after we had the traps eat lixes. Eating a lix sets a flag
    // in the trap to run through the animation, showing the first killing
    // frame after this next call to animate(). Physics depend on this anim.
    foreach (hatch; hatches)
        hatch.animate(effect, update);

    foreachGadget((Gadget g) {
        g.animateForUpdate(update);
    });
    game.pan.setLikeTribe(game.tribeLocal);
}}
// end with (game.cs), end update_once()



private:

void putSpawnintChangesIntoReplay(Game game) { }

void
putUndispatchedAssignmentsIntoReplay(Game game) { with (game)
{
    if (undispatchedAssignments == null)
        // don't cut the replay or anything
        return;

    // DTODO: Instead of setting pause to false here, don't dispatch all
    // assignments in each logic cycle. Instead, introduce a variable of
    // type ReplayData[] in the game to hold all assignments until the next
    // update, and only dispatch them (including cutting off the replay)
    // at that time. We want to prevent dispatching twice for the same update,
    // thus cutting already-dispatched replay data.
    pan.pause.on = false;

    if (! multiplayer && cs.update <= replay.latestUpdate) {
        replay.deleteOnAndAfterUpdate(cs.update);

        // not an effect to be saved by the effect manager
        // DTODO: Maybe delete/play sound already on generating the data, and
        // still put the data into the replay only now. The benefit is that
        // the sound plays faster. Also, there may be other events that
        // snip the replay, not only this.
        hardware.sound.playLoud(Sound.SCISSORS);
    }

    foreach (data; undispatchedAssignments) {
        replay.add(data);
        // DTODONETWORK
        // Network::send_replay_data(data);
        // or even better: network-send this data as soon as it is
        // generated in game.gameacti, not only when the update happens,
        // to combat lag wherever possible
    }
    undispatchedAssignments = null;
}}
// end void putUndispatchedAssignmentsIntoReplay()



void putNetworkDataIntoReplay(Game game) { }



void
evaluateReplayData(Game game)
{
    assert (game.replay);
    auto dataSlice = game.replay.getDataForUpdate(game.cs.update);

    // Evaluating replay data, which carries out mere assignments, should be
    // independent of player order. Nonetheless, out of paranoia, we do it
    // in the order of players first, only then in the order of 'data'.
    foreach (int trID, tribe; game.cs.tribes)
        foreach (ref const(ReplayData) data; dataSlice)
            if (auto master = tribe.getMasterWithNumber(data.player))
                game.updateOneData(trID, tribe, master, data);
}




void
updateOneData(
    Game game,
    in int trID,
    Tribe  tribe,
    in Tribe.Master* master,
    ref const(ReplayData) i) { with (game)
{
    immutable upd = game.cs.update;

    if (i.isSomeAssignment) {
        // never assert based on the content in ReplayData, which may have
        // been a maleficious attack from a third party, carrying a lix ID
        // that is not valid. If bogus data comes, return from this function.
        if (! master || i.toWhichLix < 0 || i.toWhichLix >= tribe.lixvec.len)
            return;

        Lixxie lixxie = tribe.lixvec[i.toWhichLix];
        assert (lixxie);

        if (lixxie.priorityForNewAc(i.skill, false) <= 1
            || tribe.skills[i.skill] == 0
            || (lixxie.facingLeft  && i.action == RepAc.ASSIGN_RIGHT)
            || (lixxie.facingRight && i.action == RepAc.ASSIGN_LEFT)
        )
            return;

        // Physics
        ++(tribe.skillsUsed);
        if (tribe.skills[i.skill] != lix.skillInfinity)
            --(tribe.skills[i.skill]);
        auto ow = game.makeGypsyWagon(trID, i.toWhichLix);
        lixxie.outsideWorld = &ow;
        lixxie.assignManually(i.skill);

        // Effects
        if ((basics.user.arrowsReplay && replaying)
            || (basics.user.arrowsNetwork
                && multiplayer && ! replaying && *master !is masterLocal)
        ) {
            // DTODOEFFECTS
            /+
            Arrow arr(map, t.style, lix.get_ex(), lix.get_ey(),
                psk->first, upd, i->what);
            effect.add_arrow(upd, t, i->what, arr);
            +/
        }
        if (tribe is tribeLocal)
            effect.addSound(upd, tribeID(tribe), i.toWhichLix, Sound.ASSIGN,
                (*master is masterLocal) ? Loudness.loud : Loudness.quiet);
    }
    // end of i.isSomeAssignment
    /+
    else if (i.action == ReplayData.SPAWNINT) {
        const int spint = i->what;
        if (spint >= t.spawnint_fast && spint <= t.spawnint_slow) {
            t.spawnint = spint;
            if (&t == tribeLocal) pan.spawnint_cur.set_spawnint(t.spawnint);
        }
    }
    else if (i->action == Replay::NUKE) {
        if (!t.nuke) {
            t.lix_hatch = 0;
            t.nuke      = true;
            if (&t == tribeLocal) {
                pan.nuke_single.set_on();
                pan.nuke_multi .set_on();
            }
            effect.add_sound(upd, t, 0, Sound::NUKE);
        }
    }
    +/
}}
// end with (game), end updateOneData()



void updateClock(Game game) { with (game)
{
    if (level.seconds <= 0)
        return;

    if (cs.clockIsRunning && cs.clock > 0)
        --cs.clock;

    /+
    // Im Multiplayer:
    // Nuke durch die letzten Sekunden der Uhr. Dies loest
    // kein Netzwerk-Paket aus! Alle Spieler werden jeweils lokal genukt.
    // Dies fuehrt dennoch bei allen zum gleichen Spielverlauf, da jeder
    // Spieler das Zeitsetzungs-Paket zum gleichen Update erhalten.
    // Wir muessen dies nach dem Replayauswerten machen, um festzustellen,
    // dass noch kein Nuke-Ereignis im Replay ist.
    if (multiplayer && cs.clock_running &&
     cs.clock <= (unsigned long) Lixxie::updatesForBomb)
     for (Tribe::It tr = cs.tribes.begin(); tr != cs.tribes.end(); ++tr) {
        if (!tr->nuke) {
            // Paket anfertigen
            Replay::Data  data;
            data.update = upd;
            data.player = tr->masters.begin()->number;
            data.action = Replay::NUKE;
            replay.add(data);
            // Und sofort ausfuehren: Replay wurde ja schon ausgewertet
            tr->lix_hatch = 0;
            tr->nuke           = true;
            if (&*tr == tribeLocal) {
                pan.nuke_single.set_on();
                pan.nuke_multi .set_on();
            }
            effect.add_sound(upd, *tr, 0, Sound::NUKE);
        }
    }
    // Singleplayer:
    // Upon running out of time entirely, shut all exits
    if (! multiplayer && cs.clock_running && cs.clock == 0
     && ! cs.goals_locked) {
        cs.goals_locked = true;
        effect.add_sound(upd, *tribeLocal, 0, Sound::OVERTIME);
    }
    // Ebenfalls etwas Uhriges: Gibt es Spieler mit geretteten Lixen,
    // die aber keine Lixen mehr im Spiel haben oder haben werden? Dann
    // wird die Nachspielzeit angesetzt. Falls aber alle Spieler schon
    // genukt sind, dann setzen wir die Zeit nicht an, weil sie vermutlich
    // gerade schon ausgelaufen ist.
    if (!cs.clock_running)
     for (Tribe::CIt i = cs.tribes.begin(); i != cs.tribes.end(); ++i)
     if (i->lix_saved > 0 && ! i->get_still_playing()) {
        // Suche nach Ungenuktem
        for (Tribe::CIt j = cs.tribes.begin(); j != cs.tribes.end(); ++j)
         if (! j->nuke && j->get_still_playing()) {
            cs.clock_running = true;
            // Damit die Meldung nicht mehrmals kommt bei hoher Netzlast
            effect.add_overtime(upd, *i, cs.clock);
            break;
        }
        break;
    }
    // Warnsounds
    if (cs.clock_running
     && cs.clock >  0
     && cs.clock != (unsigned long) level.seconds
                                  * gloB->updates_per_second
     && cs.clock <= (unsigned long) gloB->updates_per_second * 15
     && cs.clock % gloB->updates_per_second == 0)
     for (Tribe::CIt i = cs.tribes.begin(); i != cs.tribes.end(); ++i)
     if (!i->lixvec.empty()) {
        // The 0 goes where usually a lixvec ID would go, because this
        // is one of the very few sounds that isn't attached to a lixvec.
        effect.add_sound(upd, *tribeLocal, 0, Sound::CLOCK);
        break;
    }
    +/
}}
// end with (game); end updateClock()



lix.OutsideWorld
makeGypsyWagon(Game game, in int tribeID, in int lixID)
{
    OutsideWorld ow;
    ow.state         = game.cs;
    ow.physicsDrawer = game.physicsDrawer;
    ow.effect        = game.effect;
    ow.tribe         = game.cs.tribes[tribeID];
    ow.tribeID       = tribeID;
    ow.lixID         = lixID;
    return ow;
}



void
spawnLixxiesFromHatches(Game game) { with (game.cs)
{
    foreach (int teamNumber, Tribe tribe; tribes) {
        if (tribe.lixHatch != 0
            && update >= 60
            && update >= tribe.updatePreviousSpawn + tribe.spawnint
        ) {
            assert (game.replay);
            assert (game.replay.permu);
            immutable int position = game.replay.permu[teamNumber];
            const(Gadget) hatch    = hatches[tribe.hatchNextSpawn];

            // the only interesting part of OutsideWorld right now is the
            // lookupmap inside the current state. Everything else will be
            // passed anew when the lix are updated.
            auto ow = game.makeGypsyWagon(teamNumber, tribe.lixvec.len);

            Lixxie newLix = new Lixxie(game.map, &ow,
                hatch.x + hatch.tile.triggerX,
                hatch.y + hatch.tile.triggerY);
            tribe.lixvec ~= newLix;
            --tribe.lixHatch;
            ++tribe.lixOut;
            tribe.updatePreviousSpawn = update;

            bool walkLeftInsteadOfRight = hatch.rotation
                // This extra turning solution here is necessary to make
                // some L1 and ONML two-player levels playable better.
                || (hatches.len < tribes.len && (position/hatches.len)%2 == 1);
            if (walkLeftInsteadOfRight) {
                newLix.turn();
                newLix.moveAhead();
            }
            tribe.hatchNextSpawn += tribes.len;
            tribe.hatchNextSpawn %= hatches.len;
        }
    }
}}
// end spawnLixxiesFromHatches()



void
updateNuke(Game game)
{
    /+
    // Instant nuke should not display a countdown fuse in any frame.
    for (Tribe::It t = cs.tribes.begin(); t != cs.tribes.end(); ++t) {
        // Assign exploders in case of nuke
        if (t->nuke == true)
         for (LixIt i = t->lixvec.begin(); i != t->lixvec.end(); ++i) {
            if (i->get_updatesSinceBomb() == 0 && ! i->get_leaving()) {
                i->inc_updatesSinceBomb();
                // Which exploder shall be assigned?
                if (cs.tribes.size() > 1) {
                    i->set_exploderKnockback();
                }
                else for (Level::CSkIt itr =  t->skills.begin();
                                       itr != t->skills.end(); ++itr
                ) {
                    if (itr->first == LixEn::EXPLODER2) {
                        i->set_exploderKnockback();
                        break;
                    }
                }
                break;
            }
        }
    }
    +/
}



void
updateLixxies(Game game) { with (game)
{
    // DTODOPHYSICS: Implement geoo's nice split into many loops
    // First pass: Update only workers and mark them
    foreach (int tribeID, tribe; cs.tribes) {
        assert (tribeID == game.tribeID(tribe));
        foreach (int lixID, lixxie; tribe.lixvec) {
            if (lixxie.ac > Ac.WALKER) {
                auto ow = game.makeGypsyWagon(tribeID, lixID);
                lixxie.outsideWorld = &ow;
                lixxie.marked = true;
                game.updateSingleLix(lixxie);
            }
            else {
                lixxie.marked = false;
            }
        }
    }
    physicsDrawer.applyChangesToLookup();

    // Second pass: Update unmarked
    foreach (int tribeID, tribe; cs.tribes)
        foreach (int lixID, lixxie; tribe.lixvec)
            if (lixxie.marked == false) {
                auto ow = game.makeGypsyWagon(tribeID, lixID);
                lixxie.outsideWorld = &ow;
                game.updateSingleLix(lixxie);
            }
    physicsDrawer.applyChangesToLookup();

    /+
    // Third pass (if necessary): finally becoming flingers
    if (Lixxie.anyNewFlingers)
        foreach (tribe; game.cs.tribes)
            foreach (int id, lixxie; tribe.lixvec)
                if (lixxie.flingNew)
                    // DTODO: What is this, where is it defined?
                    finally_fling(lixxie);
    +/
}}



void updateSingleLix(Game game, Lixxie l)
{
    l.performActivity();
}



void considerMakingAutoSavestate(Game game)
{
    assert (game.runmode == Runmode.INTERACTIVE);
    assert (game.stateManager);
    if (game.stateManager.wouldAutoSave(game.cs)) {
        // It seems dubious to do drawing to bitmaps during calc/update.
        // However, savestates save the land too, and they should
        // hold the correctly updated land. We could save an instance
        // of a PhysicsDrawer along inside the savestate, but then we would
        // redraw over and over when loading from this state during
        // framestepping backwards. Instead, let's calculate the land now.
        game.physicsDrawer.applyChangesToLand(game.cs.update);
        game.stateManager.autoSave(game.cs);
    }
}
