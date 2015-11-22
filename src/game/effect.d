module game.effect;

import std.container.rbtree;

import game;
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

    void addSoundGeneral(in int upd, in Sound sound)
    {
        addSound(upd, -1, 0, sound, Loudness.loud);
    }

    void addSound(
        in int upd, in int tribe, in int lix,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        _tree.insert(Effect(upd, tribe, lix, sound, loudness));
    }

    void addSoundIfTribeLocal(
        in int upd, in int tribe, in int lix,
        in Sound sound, in Loudness loudness = Loudness.loud
    ) {
        if (tribe == tribeLocal)
            _tree.insert(Effect(upd, tribe, lix, sound, loudness));
    }

    void deleteAfter(in int upd)
    {
        Effect e = Effect(upd, -1 , 0, Sound.NOTHING);
        _tree.remove(_tree.upperBound(e));
        _tree.remove(_tree.equalRange(e));
    }

    auto effectsForUpdate(in int upd) const
    {
        Effect allWantedAreLargerThanMe = Effect(upd, -1 , 0, Sound.NOTHING);
        return _tree.upperBound(allWantedAreLargerThanMe);
    }

}
