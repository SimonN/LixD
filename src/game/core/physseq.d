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
import hardware.tharsis;
import lix;

static import basics.user; // draw arrows or not

package void updateTo(Game game, in Update targetUpdate)
{
    if (game.cs.update >= targetUpdate)
        return;
    game.syncNetworkAndDispatch();
    while (game.cs.update < targetUpdate) {
        game.updateOnce();
        game.considerAutoSavestateIfCloseTo(targetUpdate);
    }
    game.setLastUpdateToNow();
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

void syncNetworkAndDispatch(Game game)
{
    game.putSpawnintChangesIntoReplay();
    game.putUndispatchedAssignmentsIntoReplay();
    game.putNetworkDataIntoReplay();
}



// This is the main function that gets executed once per physics update.
void updateOnce(Game game)
{
    assert (game);
    assert (game.cs);

    Zone zone = Zone(profiler, "PhysSeq updateOnceNoSync");

    ++game.cs.update;

    game.evaluateReplayData();
    game.updateClock();
    game.spawnLixxiesFromHatches();
    game.updateNuke();
    game.updateLixxies();
    game.finalizeUpdateAnimateGadgets();
}

void putSpawnintChangesIntoReplay(Game game) { }

void putUndispatchedAssignmentsIntoReplay(Game game) { with (game)
{
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
        OutsideWorld ow = game.makeGypsyWagon(trID, i.toWhichLix);
        lixxie.assignManually(&ow, i.skill);

        // Non-physical effects
        immutable onlyOtherMastersArrows = (multiplayer && ! replaying);
        if (basics.user.arrowsReplay  && ! onlyOtherMastersArrows
         || basics.user.arrowsNetwork && onlyOtherMastersArrows
                                      && *master !is masterLocal)
            effect.addArrow(upd, trID, i.toWhichLix,
                lixxie.ex, lixxie.ey, tribe.style, i.skill);
        if (tribe is tribeLocal)
            effect.addSound(upd, trID, i.toWhichLix, Sound.ASSIGN,
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
    +/
    else if (i.action == RepAc.NUKE) {
        if (tribe.nuke)
            return;
        tribe.lixHatch = 0;
        tribe.nuke = true;
        effect.addSound(upd, trID, 0, Sound.NUKE);
        if (tribe is tribeLocal) {
            pan.nukeSingle.on = true;
            pan.nukeMulti .on = true;
        }
    }
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
        if (tribe.lixHatch == 0
            || update < 60
            || update < tribe.updatePreviousSpawn + tribe.spawnint)
            continue;
        assert (game.replay);
        assert (game.replay.permu);
        immutable int position = game.replay.permu[teamNumber];
        const(Hatch) hatch     = hatches[tribe.hatchNextSpawn];

        bool walkLeftInsteadOfRight = hatch.spawnFacingLeft
            // This extra turning solution here is necessary to make
            // some L1 and ONML two-player levels playable better.
            || (hatches.len < tribes.len && (position/hatches.len)%2 == 1);

        // the only interesting part of OutsideWorld right now is the
        // lookupmap inside the current state. Everything else will be
        // passed anew when the lix are updated.
        auto ow = game.makeGypsyWagon(teamNumber, tribe.lixvec.len);
        Lixxie newLix = new Lixxie(game.map, &ow,
            hatch.x + hatch.tile.triggerX - 2 * walkLeftInsteadOfRight,
            hatch.y + hatch.tile.triggerY);
        if (walkLeftInsteadOfRight)
            newLix.turn();
        tribe.lixvec ~= newLix;
        --tribe.lixHatch;
        ++tribe.lixOut;
        tribe.updatePreviousSpawn = update;
        tribe.hatchNextSpawn     += tribes.len;
        tribe.hatchNextSpawn     %= hatches.len;
    }
}}
// end spawnLixxiesFromHatches()



void
updateNuke(Game game)
{
    foreach (tribe; game.cs.tribes) {
        if (! tribe.nuke)
            continue;
        foreach (lix; tribe.lixvec) {
            if (! lix.healthy || lix.ploderTimer > 0)
                continue;
            // Assign flingploders in MP, depends-on-level in 1P.
            // Idea: Level may set nuke skill.
            lix.ploderTimer = 1;
            lix.ploderIsExploder = game.cs.tribes.len > 1
                                || game.level.skills[Ac.exploder2] > 0;
            break; // only one lix is hit by the nuke per update
        }
    }
}



void
updateLixxies(Game game) { with (game)
{
    Zone zone = Zone(profiler, "PhysSeq updateLixxies()");

    immutable bool wonBeforeUpdate = singlePlayerHasWon;

    bool anyFlingers = false;

    void foreachLix(void delegate(in int, in int, Lixxie) func)
    {
        foreach (int tribeID, tribe; cs.tribes)
            foreach (int lixID, lixxie; tribe.lixvec)
                func(tribeID, lixID, lixxie);
    }

    void performFlingersUnmarkOthers()
    {
        foreachLix((in int tribeID, in int lixID, Lixxie lixxie) {
            lixxie.setNoEncountersNoBlockerFlags();
            if (lixxie.ploderTimer != 0) {
                auto ow = game.makeGypsyWagon(tribeID, lixID);
                Ploder.handlePloderTimer(lixxie, &ow);
            }
            if (lixxie.updateOrder == UpdateOrder.flinger) {
                lixxie.marked = true;
                anyFlingers = true;
                auto ow = game.makeGypsyWagon(tribeID, lixID);
                lixxie.perform(&ow);
            }
            else
                lixxie.marked = false;
        });
    }

    void applyFlinging()
    {
        if (! anyFlingers)
            return;
        foreachLix((in int tribeID, in int lixID, Lixxie lixxie) {
            auto ow = game.makeGypsyWagon(tribeID, lixID);
            lixxie.applyFlingXY(&ow);
        });
    }

    void performUnmarked(UpdateOrder uo)
    {
        foreachLix((in int tribeID, in int lixID, Lixxie lixxie) {
            if (! lixxie.marked && lixxie.updateOrder == uo) {
                lixxie.marked = true;
                auto ow = game.makeGypsyWagon(tribeID, lixID);
                lixxie.perform(&ow);
            }
        });
    }

    performFlingersUnmarkOthers();
    applyFlinging();
    physicsDrawer.applyChangesToPhymap();

    performUnmarked(UpdateOrder.blocker);
    performUnmarked(UpdateOrder.remover);
    physicsDrawer.applyChangesToPhymap();

    performUnmarked(UpdateOrder.adder);
    physicsDrawer.applyChangesToPhymap();

    performUnmarked(UpdateOrder.peaceful);

    if (! wonBeforeUpdate && singlePlayerHasWon)
        effect.addSoundGeneral(cs.update, Sound.YIPPIE);
}}



void considerAutoSavestateIfCloseTo(Game game, Update targetUpdate)
{
    if (game.runmode != Runmode.INTERACTIVE)
        return;

    assert (game.stateManager);
    if (game.stateManager.wouldAutoSave(game.cs, targetUpdate)) {
        Zone zone = Zone(profiler, "PhysSeq make auto savestate");
        // It seems dubious to do drawing to bitmaps during calc/update.
        // However, savestates save the land too, and they should
        // hold the correctly updated land. We could save an instance
        // of a PhysicsDrawer along inside the savestate, but then we would
        // redraw over and over when loading from this state during
        // framestepping backwards. Instead, let's calculate the land now.
        game.physicsDrawer.applyChangesToLand(game.cs.update);
        game.stateManager.autoSave(game.cs, targetUpdate);
    }
}
