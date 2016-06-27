module game.model.model;

/* Everything from the physics collected in one class, according to MVC.
 *
 * Does not manage the replay. Whenever you want to advance physics, cut off
 * from the replay the correct hunk, and feed it one-by-one to the model.
 *
 * To do automated replay checking, don't use a model directly! Make a nurse,
 * and have her check the replay!
 */

import basics.help; // len
import basics.nettypes;
import hardware.tharsis;
import game.effect;
import game.physdraw;
import tile.phymap;
import game.replay;
import game.tribe;
import game.model.state;
import game.model.init;
import graphic.gadget;
import graphic.torbit;
import hardware.sound;
import level.level;
import lix;

class GameModel {

    this(in Level level, EffectManager ef)
    {
        _effect = ef;
        _cs     = game.model.init.newZeroState(level);
        _physicsDrawer = new PhysicsDrawer(_cs.land, _cs.lookup);
        finalizeUpdateAnimateGadgets();
    }

    void takeOwnershipOf(GameState s)
    {
        _cs = s;
        _physicsDrawer.rebind(_cs.land, _cs.lookup);
        finalizeUpdateAnimateGadgets();
    }

    void applyChangesToLand() {
        _physicsDrawer.applyChangesToLand(_cs.update);
    }

    /* Design burden: These methods must all be called in the correct order:
     *  1. incrementUpdate()
     *  2. applyReplayData(...) for each piece of data from that update
     *  3. advance()
     * Refactor this eventually!
     */

    void incrementUpdate()
    {
        ++_cs.update;
    }

    void applyReplayData(
        in int trID,
        in Tribe.Master* master,
        ref const(ReplayData) i
    ) {
        assert (i.update == _cs.update,
            "increase update manually before applying replay data");
        implApplyReplayData(trID, master, i);
    }

    void advance(in Permu permu)
    {
        spawnLixxiesFromHatches(permu);
        updateNuke();
        updateLixxies();
        finalizeUpdateAnimateGadgets();
    }

    void dispose()
    {
        if (_physicsDrawer)
            _physicsDrawer.dispose();
        _physicsDrawer = null;
    }

private:

    GameState     _cs;            // owned (current state)
    PhysicsDrawer _physicsDrawer; // owned
    EffectManager _effect;        // not owned

package: // eventually delete

    // eventually deprecate these
    @property inout(GameState) cs() inout { return _cs; }
    alias cs this;

private:

    lix.OutsideWorld
    makeGypsyWagon(in int tribeID, in int lixID)
    {
        OutsideWorld ow;
        ow.state         = _cs;
        ow.physicsDrawer = _physicsDrawer;
        ow.effect        = _effect;
        ow.tribe         = _cs.tribes[tribeID];
        ow.tribeID       = tribeID;
        ow.lixID         = lixID;
        return ow;
    }

    void
    implApplyReplayData(
        in int trID,
        in Tribe.Master* master,
        ref const(ReplayData) i
    ) {
        immutable upd = _cs.update;
        Tribe tribe   = _cs.tribes[trID];

        if (i.isSomeAssignment) {
            // never assert based on the content in ReplayData, which may have
            // been a maleficious attack from a third party, carrying a lix ID
            // that is not valid. If bogus data comes, return from this function.
            if (! master || i.toWhichLix < 0 ||
                            i.toWhichLix >= tribe.lixvec.len)
                return;
            Lixxie lixxie = tribe.lixvec[i.toWhichLix];
            assert (lixxie);
            if (lixxie.priorityForNewAc(i.skill) <= 1
                || tribe.skills[i.skill] == 0
                || (lixxie.facingLeft  && i.action == RepAc.ASSIGN_RIGHT)
                || (lixxie.facingRight && i.action == RepAc.ASSIGN_LEFT))
                return;
            // Physics
            ++(tribe.skillsUsed);
            if (tribe.skills[i.skill] != lix.skillInfinity)
                --(tribe.skills[i.skill]);
            OutsideWorld ow = makeGypsyWagon(trID, i.toWhichLix);
            lixxie.assignManually(&ow, i.skill);

            // DTODONETWORK: We don't check for tribeLocal or masterLocal here.
            // Instead, the effect manager should decide whether to generate
            // the effect, and what loudness the sound have. Maybe pass more
            // data to the effect manager than this here.
            _effect.addArrow(upd, trID, i.toWhichLix,
                lixxie.ex, lixxie.ey, tribe.style, i.skill);
            _effect.addSound(upd, trID, i.toWhichLix, Sound.ASSIGN);
        }
        else if (i.action == RepAc.NUKE) {
            if (tribe.nuke)
                return;
            tribe.lixHatch = 0;
            tribe.nuke = true;
            _effect.addSound(upd, trID, 0, Sound.NUKE);
        }
    }

    void spawnLixxiesFromHatches(in Permu permu)
    {
        foreach (int teamNumber, Tribe tribe; _cs.tribes) {
            if (tribe.lixHatch == 0
                || update < 60
                || update < tribe.updatePreviousSpawn + tribe.spawnint)
                continue;
            assert (permu);
            immutable int position = permu[teamNumber];
            const(Hatch) hatch     = hatches[tribe.hatchNextSpawn];

            bool walkLeftInsteadOfRight = hatch.spawnFacingLeft
                // This extra turning solution here is necessary to make
                // some L1 and ONML two-player levels playable better.
                || (hatches.len < tribes.len && (position/hatches.len)%2 == 1);

            // the only interesting part of OutsideWorld right now is the
            // lookupmap inside the current state. Everything else will be
            // passed anew when the lix are updated.
            auto ow = makeGypsyWagon(teamNumber, tribe.lixvec.len);
            Lixxie newLix = new Lixxie(_cs.lookup, &ow,
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
    }

    void updateNuke()
    {
        foreach (int tribeID, tribe; _cs.tribes) {
            if (! tribe.nuke || tribe.nukeSkill == Ac.nothing)
                continue;
            foreach (int lixID, lix; tribe.lixvec) {
                if (! lix.healthy || lix.ploderTimer > 0)
                    continue;
                auto ow = makeGypsyWagon(tribeID, lixID);
                lix.assignManually(&ow, tribe.nukeSkill);
                break; // only one lix is hit by the nuke per update
            }
        }
    }

    void updateLixxies()
    {
        version (tharsisprofiling)
            Zone zone = Zone(profiler, "PhysSeq updateLixxies()");
        immutable bool wonBeforeUpdate = singlePlayerHasWon;
                  bool anyFlingers     = false;

        void foreachLix(void delegate(in int, in int, Lixxie) func)
        {
            foreach (int tribeID, tribe; _cs.tribes)
                foreach (int lixID, lixxie; tribe.lixvec)
                    func(tribeID, lixID, lixxie);
        }

        void performFlingersUnmarkOthers()
        {
            foreachLix((in int tribeID, in int lixID, Lixxie lixxie) {
                lixxie.setNoEncountersNoBlockerFlags();
                if (lixxie.ploderTimer != 0) {
                    auto ow = makeGypsyWagon(tribeID, lixID);
                    Ploder.handlePloderTimer(lixxie, &ow);
                }
                if (lixxie.updateOrder == UpdateOrder.flinger) {
                    lixxie.marked = true;
                    anyFlingers = true;
                    auto ow = makeGypsyWagon(tribeID, lixID);
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
                auto ow = makeGypsyWagon(tribeID, lixID);
                lixxie.applyFlingXY(&ow);
            });
        }

        void performUnmarked(UpdateOrder uo)
        {
            foreachLix((in int tribeID, in int lixID, Lixxie lixxie) {
                if (! lixxie.marked && lixxie.updateOrder == uo) {
                    lixxie.marked = true;
                    auto ow = makeGypsyWagon(tribeID, lixID);
                    lixxie.perform(&ow);
                }
            });
        }

        performFlingersUnmarkOthers();
        applyFlinging();
        _physicsDrawer.applyChangesToPhymap();

        performUnmarked(UpdateOrder.blocker);
        performUnmarked(UpdateOrder.remover);
        _physicsDrawer.applyChangesToPhymap();

        performUnmarked(UpdateOrder.adder);
        _physicsDrawer.applyChangesToPhymap();

        performUnmarked(UpdateOrder.peaceful);

        if (! wonBeforeUpdate && singlePlayerHasWon)
            _effect.addSoundGeneral(_cs.update, Sound.YIPPIE);
    }

    void finalizeUpdateAnimateGadgets()
    {
        // Animate after we had the traps eat lixes. Eating a lix sets a flag
        // in the trap to run through the animation, showing the first killing
        // frame after this next animate() call. Physics depend on this anim!
        foreach (hatch; hatches)
            hatch.animate(_effect, _cs.update);
        foreachGadget((Gadget g) {
            g.animateForUpdate(_cs.update);
        });
    }
}
