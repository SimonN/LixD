module physics.model;

/*
 * Everything from the physics collected in one class, according to MVC.
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
import std.range;

import basics.help; // len
import net.repdata;
import hardware.tharsis;
import file.replay;
import graphic.gadget;
import graphic.torbit;
import hardware.sound;
import level.level;
import lix;
import net.permu;
import physics.effect;
import physics.physdraw;
import physics.state;
import physics.statinit;
import physics.tribe;
import tile.phymap;

class GameModel {
private:
    GameState     _cs;            // owned (current state)
    PhysicsDrawer _physicsDrawer; // owned
    EffectSink _effect; // not owned, never null. May be the NullEffectSink.

public:
    // The replay data comes with player information (PlNr).
    // Physics only work with tribe information (Style).
    // To preserve database normal form, we shouldn't put the Style in the
    // replay's Ply, but still must ask the caller of advance(),
    // which is the Nurse, to associate Ply to Style via this struct.
    struct ColoredData {
        Ply replayData;
        Style style;
        alias replayData this;
    }

    // Add players to the replay before you pass the replay to Nurse.ctor!
    // This remembers the effect manager, but not anything else.
    // We don't own the effect manager.
    this(in Level level, in Style[] tribesToMake,
         in Permu permu, EffectSink ef)
    in { assert (tribesToMake.len >= 1); }
    do {
        _effect = ef;
        _cs = newZeroState(level, tribesToMake, permu);
        _physicsDrawer = new PhysicsDrawer(_cs.land, _cs.lookup);
        finalizePhyuAnimateGadgets();
    }

    // Should be accsessible by the Nurse. Shouldn't be accessed straight from
    // the game, but it's the Nurse's task to hide that information.
    @property inout(GameState) cs() inout { return _cs; }

    void takeOwnershipOf(GameState s)
    {
        _cs = s;
        _physicsDrawer.rebind(_cs.land, _cs.lookup);
        finalizePhyuAnimateGadgets();
    }

    void applyChangesToLand() {
        _physicsDrawer.applyChangesToLand(_cs.update);
    }

    void advance(R)(R range)
        if (isInputRange!R && is (ElementType!R : const(ColoredData)))
    {
        ++_cs.update;
        range.each!(cd => applyPly(cd));

        updateNuke(); // sets lixHatch = 0, thus affects spawnLixxiesFromHatch
        spawnLixxiesFromHatches();
        updateLixxies();
        finalizePhyuAnimateGadgets();
        if (_cs.overtimeRunning && _cs.multiplayer) {
            _effect.announceOvertime(_cs.update,
                _cs.overtimeAtStartInPhyus);
        }
    }

    void dispose()
    {
        if (_physicsDrawer)
            _physicsDrawer.dispose();
        _physicsDrawer = null;
    }

private:

    lix.OutsideWorld makeGypsyWagon(in Passport pa) pure nothrow @nogc
    {
        return OutsideWorld(_cs, _physicsDrawer, _effect, pa);
    }

    void applyPly(in ColoredData i)
    {
        immutable upd = _cs.update;
        assert (i.update == upd,
            "increase update manually before applying replay data");

        auto tribe = i.style in _cs.tribes;
        if (! tribe)
            // Ignore bogus data that can come from anywhere
            return;
        if (tribe.nukePressed || _cs.nuking)
            // Game rule: After you call for the nuke, you may not assign
            // other things, nuke again, or do whatever we allow in the future.
            // During the nuke, nobody can assign or save lixes.
            return;

        immutable Passport pa = Passport(i.style, i.toWhichLix);
        if (i.isSomeAssignment) {
            // never assert based on the content in Ply, which may have
            // been a maleficious attack from a third party, carrying a lix ID
            // that is not valid. If bogus data comes, do nothing.
            if (i.toWhichLix < 0 || i.toWhichLix >= tribe.lixlen)
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
            OutsideWorld ow = makeGypsyWagon(pa);
            lixxie.assignManually(&ow, i.skill);

            _effect.addSound(upd, pa, Sound.ASSIGN);
            _effect.addArrow(upd, pa, lixxie.foot, i.skill);
        }
        else if (i.action == RepAc.NUKE) {
            tribe.nukePressedSince = upd;
            _effect.addSound(upd, pa, Sound.NUKE);
        }
    }

    void spawnLixxiesFromHatches()
    {
        foreach (int teamNumber, Tribe tribe; _cs.tribes) {
            if (tribe.lixHatch == 0
                || _cs.update < _cs.updateFirstSpawn
                || _cs.update < tribe.updatePreviousSpawn + tribe.spawnint)
                continue;
            // the only interesting part of OutsideWorld right now is the
            // lookupmap inside the current state. Everything else will be
            // passed anew when the lix are updated.
            auto ow = makeGypsyWagon(Passport(tribe.style, tribe.lixlen));
            tribe.spawnLixxie(&ow);
        }
    }

    void updateNuke()
    {
        if (! _cs.nuking)
            return;
        foreach (tribe; _cs.tribes) {
            tribe.lixHatch = 0;
            foreach (int lixID, lix; tribe.lixvec.enumerate!int) {
                if (! lix.healthy || lix.ploderTimer > 0)
                    continue;
                OutsideWorld ow = makeGypsyWagon(Passport(tribe.style, lixID));
                lix.assignManually(&ow, Ac.exploder);
                break; // only one lix per tribe is hit by the nuke per update
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
                foreach (int lixID, lixxie; tribe.lixvec.enumerate!int)
                    func(tribe, lixID, lixxie);
        }

        void performFlingersUnmarkOthers()
        {
            foreachLix((Tribe tribe, in int lixID, Lixxie lixxie) {
                lixxie.setNoEncountersNoBlockerFlags();
                if (lixxie.ploderTimer != 0) {
                    auto ow = makeGypsyWagon(Passport(tribe.style, lixID));
                    handlePloderTimer(lixxie, &ow);
                }
                if (lixxie.updateOrder == PhyuOrder.flinger) {
                    lixxie.marked = true;
                    anyFlingers = true;
                    auto ow = makeGypsyWagon(Passport(tribe.style, lixID));
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
                auto ow = makeGypsyWagon(Passport(tribe.style, lixID));
                lixxie.applyFlingXY(&ow);
            });
        }

        void performUnmarked(PhyuOrder uo)
        {
            foreachLix((Tribe tribe, in int lixID, Lixxie lixxie) {
                if (! lixxie.marked && lixxie.updateOrder == uo) {
                    lixxie.marked = true;
                    auto ow = makeGypsyWagon(Passport(tribe.style, lixID));
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
        // frame after this next perform() call. Physics depend on this anim!
        _cs.foreachGadget((Gadget g) { g.perform(_cs.update, _effect); });
    }
}
