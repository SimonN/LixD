module game.game;

// 2015-06-03. After 9 years, it's time to write another one of these classes.

import basics.alleg5;
import file.filename;
import game.gamecalc;
import game.gamedraw;
import game.gameinit;
import game.replay;
import game.state;
import graphic.color;
import graphic.map;
import level.level;

class Game {

    @property bool goto_menu() { return _goto_menu; }

    static immutable int ticks_normal_speed =  4;
    static immutable int ticks_slow_motion  = 45;
    static immutable int updates_when_turbo =  8;

    this(Level lv, Filename fn = null, Replay rp = null)
    {
        game.gameinit.impl_game_constructor(this, lv, fn, rp);
    }

    void calc() { impl_game_calc  (this); }
    void draw() { impl_game_draw  (this); }

package:

    bool  _goto_menu;

    Level     level;
    Filename  level_filename;
    Replay    replay;
    GameState cs; // current state

    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.

    int my_debugging_counter = 0;

    long altick_last_update;

    void calc_update() { impl_calc_update(this); }
    void calc_active() { impl_calc_update(this); }

}
