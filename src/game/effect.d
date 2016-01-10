module game.effect;

/* Convention: Effects are passed from the working lix by specifying the
 * lix's own ex/ey. The effect manager is responsible for drawing the effects
 * at the correct position/offset.
 */

import std.algorithm;
import std.container.rbtree;

import basics.help;
import basics.nettypes;
import game.debris;
import graphic.torbit;
import hardware.sound;
import lix.enums;

private struct Effect {

    Update   update;
    int      tribe; // array slot in game.cs.tribes
    int      lix;   // if not necessary, set to 0
    Sound    sound; // if not necessary, set to 0 == Sound::NOTHING
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
    private Debris[] _debris;
    public  int tribeLocal;

    this()
    {
        _tree = new RedBlackTree!Effect;
    }

    bool nothingGoingOn() const
    {
        // _tree is irrelevant for checking whether anything is still flying,
        // because _tree remembers whether the same effect was added before.
        return _debris.length == 0;
    }

    void deleteAfter(in int upd)
    out {
        foreach (e; _tree)
            assert (e.update <= upd);
    }
    body {
        _tree.remove(_tree.upperBound(Effect(Update(upd + 1),
                                      -1 , 0, Sound.NOTHING)));
    }

    override string toString() const
    {
        int[] arr;
        foreach (e; _tree)
            arr ~= e.update;
        import std.conv;
        return arr.to!string();
    }



    void addSoundGeneral(in Update upd,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        addSound(upd, tribeLocal, 0, sound, loudness);
    }

    void addSound(
        in Update upd, in int tribe, in int lix,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        Effect e = Effect(upd, tribe, lix, sound, loudness);
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(sound, loudness);
        }
    }

    void addSoundIfTribeLocal(
        in Update upd, in int tribe, in int lix,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        if (tribe == tribeLocal)
            addSound(upd, tribe, lix, sound, loudness);
    }

    void addArrow(in Update upd, in int tribe, in int lix,
        in int ex, in int ey, in Style style, in int xf
    ) {
        Effect e = Effect(upd, tribe, lix);
        if (e !in _tree) {
            _tree.insert(e);
            _debris ~= Debris.newArrow(ex, ey, style, xf);
        }
    }

    void addArrowButDontShow(in Update upd, in int tribe, in int lix)
    {
        // Only remember the effect, don't draw any debris now.
        // This is used for assignments by the local tribe master.
        Effect e = Effect(upd, tribe, lix);
        if (e !in _tree)
            _tree.insert(e);
    }

    void addDigHammer(in Update upd, in int tribe, in int lix, int ex, int ey)
    {
        Effect e = Effect(upd, tribe, lix,
            tribe == tribeLocal ? Sound.STEEL : Sound.NOTHING, Loudness.loud);
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(e.sound, e.loudness);
            // DTODOEFFECT: animate the dig hammer at(x, y - 10)
        }
    }

    void addImplosion(in Update upd, in int tribe, in int lix, int ex, int ey)
    {
        Effect e = Effect(upd, tribe, lix, Sound.POP,
            tribe == tribeLocal ? Loudness.loud : Loudness.quiet);
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(e.sound, e.loudness);
            _debris ~= Debris.newImplosion(ex, ey);
        }
    }

    void addExplosion(in Update upd, in int tribe, in int lix, int ex, int ey)
    {
        Effect e = Effect(upd, tribe, lix, Sound.POP,
            tribe == tribeLocal ? Loudness.loud : Loudness.quiet);
        if (e !in _tree) {
            _tree.insert(e);
            hardware.sound.play(e.sound, e.loudness);
            _debris ~= Debris.newExplosion(ex, ey);
        }
    }

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

    void draw(Torbit target)
    {
        _debris.each!(a => a.draw(target));
    }
}
