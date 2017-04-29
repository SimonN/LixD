module game.model.model;

/* Everything from the physics collected in one class, according to MVC.
 *
 * Does not manage the replay. Whenever you want to advance physics, cut off
 * from the replay the correct hunk, and feed it one-by-one to the model.
 *
 * To do automated replay checking, don't use a model directly! Make a nurse,
 * and have her check the replay!
 */

import std.algorithm;
import std.array;
import std.conv;

import basics.help; // len
import net.repdata;
import hardware.tharsis;
import game.effect;
import game.physdraw;
import game.replay;
import game.tribe;
import game.model.state;
import game.model.init;
import graphic.gadget;
import graphic.torbit;
import hardware.sound;
import level.level;
import lix;
import net.permu;
import tile.phymap;

class GameModel {
private:
    GameState     _cs;            // owned (current state)
    PhysicsDrawer _physicsDrawer; // owned
    EffectManager _effect;        // not owned. May be null.

package: // eventually delete cs() and alias cs this;
    @property inout(GameState) cs() inout { return _cs; }

public:
    // This remembers the effect manager, but not anything else.
    // We don't own the effect manager.
    this(in Level level, in Style[] tribesToMake,
         in Permu permu, EffectManager ef)
    {
        _effect = ef;
        _cs = newZeroState(level, tribesToMake, permu,
            ef ? ef.localTribe : Style.garden // only to make hatches blink
        );
        _physicsDrawer = new PhysicsDrawer(_cs.land, _cs.lookup);
        finalizePhyuAnimateGadgets();
    }

    void takeOwnershipOf(GameState s)
    {
        _cs = s;
        _physicsDrawer.rebind(_cs.land, _cs.lookup);
        finalizePhyuAnimateGadgets();
    }

    void applyChangesToLand() {
        _physicsDrawer.applyChangesToLand(_cs.update);
    }

    /* Design burden: These methods must all be called in the correct order:
     *  1. incrementPhyu()
     *  2. applyReplayData(...) for each piece of data from that update
     *  3. advance()
     * Refactor this eventually!
     */

    void incrementPhyu()
    {
        ++_cs.update;
    }

    void applyReplayData(
        ref const(ReplayData) i,
        in Style tribeStyle
    ) {
        assert (i.update == _cs.update,
            "increase update manually before applying replay data");
        implApplyReplayData(i, tribeStyle);
    }

    void advance()
    {
        spawnLixxiesFromHatches();
        updateNuke();
        updateLixxies();
        finalizePhyuAnimateGadgets();
    }

    void dispose()
    {
        if (_physicsDrawer)
            _physicsDrawer.dispose();
        _physicsDrawer = null;
    }

private:

    lix.OutsideWorld
    makeGypsyWagon(Tribe tribe, in int lixID)
    {
        OutsideWorld ow;
        ow.state         = _cs;
        ow.physicsDrawer = _physicsDrawer;
        ow.effect        = _effect;
        ow.tribe         = tribe;
        ow.lixID         = lixID;
        return ow;
    }

    void
    implApplyReplayData(
        ref const(ReplayData) i,
        in Style tribeStyle,
    ) {
        immutable upd = _cs.update;
        auto tribe = tribeStyle in _cs.tribes;
        // Ignore bogus data that can come from anywhere
        if (! tribe)
            return;
        if (i.isSomeAssignment) {
            // never assert based on the content in ReplayData, which may have
            // been a maleficious attack from a third party, carrying a lix ID
            // that is not valid. If bogus data comes, do nothing.
            if (i.toWhichLix < 0 || i.toWhichLix >= tribe.lixvec.len)
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
            OutsideWorld ow = makeGypsyWagon(*tribe, i.toWhichLix);
            lixxie.assignManually(&ow, i.skill);

            if (_effect) {
                _effect.addSound(upd, tribe.style, i.toWhichLix, Sound.ASSIGN);
                _effect.addArrow(upd, tribe.style, i.toWhichLix,
                                 lixxie.ex, lixxie.ey, i.skill);
            }
        }
        else if (i.action == RepAc.NUKE) {
            if (tribe.nuke)
                return;
            tribe.lixHatch = 0;
            tribe.nuke = true;
            if (_effect)
                _effect.addSound(upd, tribe.style, 0, Sound.NUKE);
        }
    }

    void spawnLixxiesFromHatches()
    {
        foreach (int teamNumber, Tribe tribe; _cs.tribes) {
            if (tribe.lixHatch == 0
                || _cs.update < 60
                || _cs.update < tribe.updatePreviousSpawn + tribe.spawnint)
                continue;
            assert (tribe.nextHatch < _cs.hatches.len);
            const(Hatch) hatch = _cs.hatches[tribe.nextHatch];
            immutable bool walkLeftInsteadOfRight = hatch.spawnFacingLeft;

            // the only interesting part of OutsideWorld right now is the
            // lookupmap inside the current state. Everything else will be
            // passed anew when the lix are updated.
            auto ow = makeGypsyWagon(tribe, tribe.lixvec.len);
            Lixxie newLix = new Lixxie(_cs.lookup, &ow, Point(
                hatch.x + hatch.tile.triggerX - 2 * walkLeftInsteadOfRight,
                hatch.y + hatch.tile.triggerY));
            if (walkLeftInsteadOfRight)
                newLix.turn();
            tribe.lixvec ~= newLix;
            --tribe.lixHatch;
            ++tribe.lixOut;
            tribe.updatePreviousSpawn = _cs.update;
            tribe.nextHatch     += _cs.numTribes;
            tribe.nextHatch     %= _cs.hatches.len;
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
                auto ow = makeGypsyWagon(tribe, lixID);
                lix.assignManually(&ow, tribe.nukeSkill);
                break; // only one lix is hit by the nuke per update
            }
        }
    }

    void updateLixxies()
    {
        version (tharsisprofiling)
            Zone zone = Zone(profiler, "PhysSeq updateLixxies()");
        bool anyFlingers     = false;

        /* Refactoring idea:
         * Put this sorting into State, and do it only once at the beginning
         * of a game. Encapsulate (Tribe[Style] tribes) and offer methods that
         * provide the mutable tribe, but don't allow to rewrite the array.
         */
        auto sortedTribes = _cs.tribes.byValue.array.sort!"a.style < b.style";

        void foreachLix(void delegate(Tribe, in int, Lixxie) func)
        {
            foreach (tribe; sortedTribes)
                foreach (int lixID, lixxie; tribe.lixvec)
                    func(tribe, lixID, lixxie);
        }

        void performFlingersUnmarkOthers()
        {
            foreachLix((Tribe tribe, in int lixID, Lixxie lixxie) {
                lixxie.setNoEncountersNoBlockerFlags();
                if (lixxie.ploderTimer != 0) {
                    auto ow = makeGypsyWagon(tribe, lixID);
                    handlePloderTimer(lixxie, &ow);
                }
                if (lixxie.updateOrder == PhyuOrder.flinger) {
                    lixxie.marked = true;
                    anyFlingers = true;
                    auto ow = makeGypsyWagon(tribe, lixID);
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
            foreachLix((Tribe tribe, in int lixID, Lixxie lixxie) {
                auto ow = makeGypsyWagon(tribe, lixID);
                lixxie.applyFlingXY(&ow);
            });
        }

        void performUnmarked(PhyuOrder uo)
        {
            foreachLix((Tribe tribe, in int lixID, Lixxie lixxie) {
                if (! lixxie.marked && lixxie.updateOrder == uo) {
                    lixxie.marked = true;
                    auto ow = makeGypsyWagon(tribe, lixID);
                    lixxie.perform(&ow);
                }
            });
        }

        performFlingersUnmarkOthers();
        applyFlinging();
        _physicsDrawer.applyChangesToPhymap();

        performUnmarked(PhyuOrder.blocker);
        performUnmarked(PhyuOrder.remover);
        _physicsDrawer.applyChangesToPhymap();

        performUnmarked(PhyuOrder.adder);
        _physicsDrawer.applyChangesToPhymap();

        performUnmarked(PhyuOrder.peaceful);
    }

    void finalizePhyuAnimateGadgets()
    {
        // Animate after we had the traps eat lixes. Eating a lix sets a flag
        // in the trap to run through the animation, showing the first killing
        // frame after this next animate() call. Physics depend on this anim!
        foreach (hatch; _cs.hatches)
            hatch.animate(_effect, _cs.update);
        _cs.foreachGadget((Gadget g) {
            g.animateForPhyu(_cs.update);
        });
    }
}
