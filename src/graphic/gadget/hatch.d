module graphic.gadget.hatch;

import std.algorithm; // min

import basics.help;
import basics.globals; // hatch arrow graphic
import game.effect;
import graphic.cutbit;
import graphic.gadget;
import graphic.gralib;
import graphic.torbit;
import hardware.sound;
import level.level;
import level.tile;
import lix.enums;

class Hatch : Gadget {

private:

    int  _x_frames_open;
    bool _blink_now;

public:

    enum update_lets_go    = 35;
    enum update_open       = 50;
    enum update_blink_stop = 48;
    enum updates_blink_on  =  4;
    enum updates_blink_off =  2;

    bool  spawn_facing_left;
    Style blink_style = Style.GARDEN; // if left at GARDEN, then don't blink

    this(Torbit tb, in ref Pos levelpos)
    {
        super(tb, levelpos);
        spawn_facing_left = levelpos.rot != 0;
        while (this.frame_exists(_x_frames_open, 0))
            ++_x_frames_open;
    }

    this(Hatch rhs)
    {
        assert (rhs);
        super(rhs);
        spawn_facing_left = rhs.spawn_facing_left;
        blink_style       = rhs.blink_style;
        _x_frames_open    = rhs._x_frames_open;
        _blink_now        = rhs._blink_now;
    }

    mixin CloneableOverride;

    override Pos to_pos() const
    {
        Pos levelpos = super.to_pos();
        levelpos.rot = spawn_facing_left;
        return levelpos;
    }

    override void animate() { }

    void animate(EffectManager effect, in int u) // update of the Game
    {
        immutable int of = update_open - tile.special_x;
        // of == first absolute frame of opening. This is earlier if the sound
        // shall match a later frame of the hatch, as defined in special_x.

        if (u < of)
            xf = yf = 0;
        else {
            // open or just opening
            yf = 0;
            xf = min(u - of,  _x_frames_open - 1);
        }

        if (u >= update_blink_stop)
            _blink_now = false;
        else {
            _blink_now
            = (u % (updates_blink_on + updates_blink_off) < updates_blink_on);
        }

        if (u == update_lets_go)
            effect.add_sound_general(u, Sound.LETS_GO);
        if (u == update_open)
            effect.add_sound_general(u, Sound.HATCH_OPEN);
    }

protected:

    override void draw_game_extras()
    {
        if (_blink_now && blink_style != Style.GARDEN) {
            const(Cutbit) c = get_skill_button_icon(blink_style);
            c.draw(ground, x + tile.trigger_x - c.xl / 2,
                           y + tile.trigger_y - c.yl / 2,
                           Ac.WALKER, 0);
        }
    }

    override void draw_editor_info()
    {
        // draw arrow pointing into the hatch's direction
        const(Cutbit) cb = get_internal(file_bitmap_edit_hatch);
        cb.draw(ground, x + yl/2 - cb.xl/2,
                        y + 20, // DTODO: +20 was ::text_height in A4/C++.
                        spawn_facing_left ? 1 : 0, 0);
    }

}
// end class Hatch
