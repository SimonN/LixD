module game.game;

/* 2015-06-03. After 9 years, it's time to write another one of these classes.
 *
 * There are many methods that were distributed over many files in C++.
 * Here, we don't declare any private (accessible from same file) members,
 * but everything is package (accessible from files in same directory).
 */

import basics.alleg5;
import file.filename;
import game;
import graphic.color;
import graphic.map;
import gui;
import level.level;

class Game {

    @property bool goto_menu() { return _goto_menu; }

    static immutable int ticks_normal_speed =  4;
    static immutable int ticks_slow_motion  = 45;
    static immutable int updates_when_turbo =  8;

    this(Level lv, Filename fn = null, Replay rp = null)
    {
        impl_game_constructor(this, lv, fn, rp);
    }

    ~this()     { impl_game_destructor(this); }

    void calc() { impl_game_calc(this); }
    void draw() { impl_game_draw(this); }

package:

    GameState cs; // current state
    bool      _goto_menu;

    Level     level;
    Filename  level_filename;
    Replay    replay;

    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.

    EffectManager effect;
    Panel pan;

    Tribe trlo;
    Tribe.Master malo;

    long altick_last_update;

    int _profiling_gadget_count;

}
