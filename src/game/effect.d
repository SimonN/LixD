module game.effect;

/* Convention: Effects are passed from the working lix by specifying the
 * lix's own ex/ey. The effect manager is responsible for drawing the effects
 * at the correct position/offset.
 */

import std.container.rbtree;

import hardware.sound;

struct Effect {

    int update;
    int tribe; // array slot in game.cs.tribes
    int lix; // if not necessary, set to 0
    Sound sound; // if not necessary, set to 0 == Sound::NOTHING
    Loudness loudness;

    int opCmp(ref in Effect rhs) const
    {
        return update   != rhs.update   ? update   - rhs.update
            :  tribe    != rhs.tribe    ? tribe    - rhs.tribe
            :  lix      != rhs.lix      ? lix      - rhs.lix
            :  sound    != rhs.sound    ? sound    - rhs.sound
            :  loudness != rhs.loudness ? loudness - rhs.loudness
            :  0;
    }
}



class EffectManager {

    private RedBlackTree!Effect _tree;
    public  int tribeLocal;

    this()
    {
        _tree = new RedBlackTree!Effect;
    }

    void deleteAfter(in int upd)
    out {
        foreach (e; _tree)
            assert (e.update <= upd);
    }
    body {
        _tree.remove(_tree.upperBound(Effect(upd + 1, -1 , 0, Sound.NOTHING)));
    }

    override string toString() const
    {
        int[] arr;
        foreach (e; _tree)
            arr ~= e.update;
        import std.conv;
        return arr.to!string();
    }



    void addSoundGeneral(in int upd,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        addSound(upd, tribeLocal, 0, sound, loudness);
    }

    void addSound(
        in int upd, in int tribe, in int lix,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        Effect e = Effect(upd, tribe, lix, sound, loudness);
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(sound, loudness);
        }
    }

    void addSoundIfTribeLocal(
        in int upd, in int tribe, in int lix,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        if (tribe == tribeLocal)
            addSound(upd, tribe, lix, sound, loudness);
    }

    void addDigHammer(in int upd, in int tribe, in int lix,
        in int ex, in int ey
    ) {
        Effect e = Effect(upd, tribe, lix,
            (tribe == tribeLocal ? Sound.STEEL : Sound.NOTHING));
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(e.sound, e.loudness);
            // DTODOEFFECT: animate the dig hammer at(x, y - 10)
        }
    }

    void addImplosion(in int upd, in int tribe, in int lix,
        in int ex, in int ey
    ) {
        Effect e = Effect(upd, tribe, lix, Sound.POP);
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(e.sound, e.loudness);
        }
    }

    void addExplosion(in int upd, in int tribe, in int lix,
        in int ex, in int ey
    ) {
        Effect e = Effect(upd, tribe, lix, Sound.POP);
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(e.sound, e.loudness);
        }
    }

}
