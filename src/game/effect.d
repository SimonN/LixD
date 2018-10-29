module game.effect;

/*
 * Effects are eye candy and sounds that the physics generate, but that have
 * no physical meaning themselves.
 *
 * Convention: Effects are passed from the working lix by specifying the
 * lix's own ex/ey. The effect manager is responsible for drawing the effects
 * at the correct position/offset. The effect managager does this by passing
 * the lix's own ex/ey straight on to the debris, which therefore becomes
 * reponsible for being drawn at the correct position.
 *
 * Because the effect manager accepts the lix's ex/ey directly, and doesn't
 * ask the lix to pass it already modified, the effect manager's calling
 * convention differs from game.physdraw.PhysicsDrawer: PhysicsDrawer expects
 * the lix to pass the top-left coordinate of the shape to be drawn.
 */

import std.algorithm;
import std.container;
import std.format;

public import physics.effect;

import basics.help;
import file.language;
import net.repdata;
import game.debris;
import game.core.game; // Game.phyusPerSecond
import gui.console;
import graphic.torbit;

private struct Effect {
    Phyu phyu;
    Passport pa; // if no Lixxie required (e.g., nuke), set pa.id = 0.
    Sound sound; // if not necessary, set to 0 == Sound::NOTHING
    Loudness loudness;

    int opCmp(ref in Effect rhs) const
    {
        return phyu != rhs.phyu ? phyu - rhs.phyu
            : pa != rhs.pa ? pa.opCmp(rhs.pa)
            : sound != rhs.sound ? sound - rhs.sound
            : loudness != rhs.loudness ? loudness - rhs.loudness
            : 0;
    }
}

class EffectManager : EffectSink {
private:
    /*
     * When you go back in time and recompute, the recomputation happens
     * quickly. Effects should not be replayed, only new effects should be
     * played. Remember played effects in this list. Example:
     *
     * 1. We're in frame 200.
     * 2. Game framesteps back to frame 190.
     * 3. This requires recomputation from frame 180 to 190.
     * 4. _alreadyPlayed contains effects between 180 and 200, good.
     * 5. Game tells us to delete from _alreadyPlayed after frame 190.
     * 6. Game progresses from 190 to 191.
     * 7. We replay the effects from 191 because they're not in _alreadyPlayed.
     */
    RedBlackTree!Effect _alreadyPlayed;

    /*
     * When we quicksave, we must deep-copy the played effects.
     * When we quickload, we must deep-copy this onto _alreadyPlayed.
     * This fixes: https://github.com/SimonN/LixD/issues/23
     * Load user state, framestep back -> unnecessary replay arrows
     * How to repro: Load a user savestate from the very future, with lots of
     * assignments in that savestate/replay, while having no effects in the
     * EffectManager recorded. Then framestep back continuously.
     * Observed: Replay arrows are shown during the on-the-fly forward
     * recalculation. Expected: These arrows should not be shown during
     * framestepping back. They should only be visible while going forward.
     */
    RedBlackTree!Effect _playedWhenLastQuicksaved;

    /*
     * Effects like flying pickaxes on the screen. Even if they won't be
     * replayed back, they should still finish to animate.
     */
    Debris[] _debris;

    int _overtimeInPhyusToAnnounce;
    bool _weScheduledOvertimeAnnouncementBefore;

public:
    Style localTribe;

    this(Style st)
    {
        localTribe = st;
        _alreadyPlayed = new RedBlackTree!Effect;
        _playedWhenLastQuicksaved = _alreadyPlayed.dup;
    }

    bool nothingGoingOn() const
    {
        // _alreadyPlayed is irrelevant for checking whether anything is
        // still flying, because _alreadyPlayed remembers whether the same
        // effect was added before.
        return _debris.length == 0;
    }

    void deleteAfter(in Phyu upd)
    out {
        foreach (e; _alreadyPlayed)
            assert (e.phyu <= upd);
    }
    body {
        // Throw away what has update (upd + 1) or more.
        // Since I can't specify (upd+1, Style.min - 1), I'll cut here:
        const Effect e = Effect(upd, Passport(Style.max, 0));
        _alreadyPlayed.remove(_alreadyPlayed.upperBound(e));
    }

    void quicksave()
    {
        if (_playedWhenLastQuicksaved != _alreadyPlayed)
            _playedWhenLastQuicksaved = _alreadyPlayed.dup;
    }

    void quickload()
    {
        if (_alreadyPlayed != _playedWhenLastQuicksaved)
            _alreadyPlayed = _playedWhenLastQuicksaved.dup;
    }

    void addSoundGeneral(in Phyu upd, in Sound sound)
    {
        addSound(upd, Passport(localTribe, 0), sound);
    }

    void addSound(in Phyu upd, in Passport pa, in Sound sound)
    {
        if (! isLocal(pa) && ! [Sound.NUKE, Sound.SPLAT, Sound.POP,
            Sound.OBLIVION, Sound.FIRE, Sound.WATER].canFind(sound)
        ) {
            // Most sounds aren't played for other teams. Only death-related
            // sounds go through here. See lix.skill.batter for how both the
            // batter and its target play sounds for their tribe.
            return;
        }
        immutable e = Effect(upd, pa, sound, loudness(pa));
        if (e !in _alreadyPlayed) {
            _alreadyPlayed.insert(e);
            hardware.sound.play(e.sound, e.loudness);
        }
    }

    void addArrow(in Phyu upd, in Passport pa, in Point foot, in Ac ac)
    {
        Effect e = Effect(upd, pa);
        if (e !in _alreadyPlayed) {
            _alreadyPlayed.insert(e);
            _debris ~= Debris.newArrow(foot, pa.style, ac);
        }
    }

    // Only remember the effect, don't draw any debris now.
    // This is used for assignments by the local tribe master.
    void addArrowDontShow(in Phyu upd, in Passport pa)
    {
        Effect e = Effect(upd, pa);
        if (e !in _alreadyPlayed)
            _alreadyPlayed.insert(e);
    }

    void addDigHammer(in Phyu upd, in Passport pa, in Point foot, in int dir)
    {
        addDigHammerOrPickaxe!true(upd, pa, foot, dir);
    }

    void addPickaxe(in Phyu upd, in Passport pa, in Point foot, in int dir)
    {
        addDigHammerOrPickaxe!false(upd, pa, foot, dir);
    }

    void addImplosion(in Phyu upd, in Passport pa, in Point foot)
    {
        immutable e = Effect(upd, pa, Sound.POP, loudness(pa));
        if (e !in _alreadyPlayed) {
            _alreadyPlayed.insert(e);
            hardware.sound.play(e.sound, e.loudness);
            _debris ~= Debris.newImplosion(foot);
        }
    }

    void addExplosion(in Phyu upd, in Passport pa, in Point foot)
    {
        immutable e = Effect(upd, pa, Sound.POP, loudness(pa));
        if (e !in _alreadyPlayed) {
            _alreadyPlayed.insert(e);
            hardware.sound.play(e.sound, e.loudness);
            _debris ~= Debris.newExplosion(foot);
        }
    }

    void announceOvertime(in Phyu upd, in int overtimeInPhyus)
    {
        if (_weScheduledOvertimeAnnouncementBefore)
            return;
        _weScheduledOvertimeAnnouncementBefore = true;
        _overtimeInPhyusToAnnounce = overtimeInPhyus;
        hardware.sound.play(Sound.OVERTIME, Loudness.loud);
    }

// ############################################################################

    void calc()
    {
        int i = 0;
        while (i < _debris.len) {
            if (_debris[i].timeToLive > 0)
                _debris[i++].calc();
            else
                _debris = _debris[0 .. i] ~ _debris[i+1 .. $];
        }
    }

    void draw(Console console)
    {
        _debris.each!(a => a.draw());
        if (_overtimeInPhyusToAnnounce != 0 && console !is null) {
            console.add(format!"%s %d:%02d..."(
                Lang.netGameOvertimeNukeIn.transl,
                _overtimeInPhyusToAnnounce / (60 * Game.phyusPerSecond),
                (_overtimeInPhyusToAnnounce / Game.phyusPerSecond) % 60));
            _overtimeInPhyusToAnnounce = 0; // don't print again on next draw
        }
    }

private:
    Loudness loudness(in Passport pa) const pure nothrow @nogc
    {
        return isLocal(pa) ? Loudness.loud : Loudness.quiet;
    }

    bool isLocal(in Passport pa) const pure nothrow @nogc
    {
        return pa.style == localTribe;
    }

    private void addDigHammerOrPickaxe(bool axe)(
        Phyu upd, in Passport pa, in Point foot, int dir
    ) {
        immutable e = Effect(upd, pa,
            isLocal(pa) ? Sound.STEEL : Sound.NOTHING, Loudness.loud);
        if (e !in _alreadyPlayed) {
            _alreadyPlayed.insert(e);
            hardware.sound.play(e.sound, e.loudness);
            static if (axe) {
                enum framePickaxe = 0;
                _debris ~= Debris.newFlyingTool(foot, dir, framePickaxe);
            }
            else {
                // DTODOEFFECT: animate the dig hammer at(footX, footY - 10)
            }
        }
    }
}
