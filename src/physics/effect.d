module physics.effect;

/*
 * The interface for the concrete effect manager of the game.
 * Lixxies and other physics don't need the full EffectManager or its drawing
 * functions or resetting functions. Lixxies merely need to queue their
 * effects to be drawn: They need a sink and don't care what happens then.
 */

import std.typecons;

public import basics.rect;
public import hardware.sound;
public import physics.lixxie.fields : Passport;
public import net.ac;
public import net.phyu;

interface EffectSink {
public:
    void addSoundGeneral(in Phyu upd, in Sound sound);
    void addSound(in Phyu upd, in Passport pa, in Sound sound);

    void addArrow(in Phyu upd, in Passport pa, in Point foot, in Ac ac);

    void addShovel(in Phyu upd, in Passport pa, in Point foot, in int dir);
    void addPickaxe(in Phyu upd, in Passport pa, in Point foot, in int dir);
    void addDigHammer(in Phyu upd, in Passport pa, in Point foot, in int dir);

    void addImplosion(in Phyu upd, in Passport pa, in Point foot);
    void addExplosion(in Phyu upd, in Passport pa, in Point foot);

    void announceOvertime(in Phyu upd, in int overtimeInPhyus);
}

alias NullEffectSink = BlackHole!EffectSink;
