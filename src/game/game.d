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

    @property bool gotoMenu() { return _gotoMenu; }

    static immutable int ticksNormalSpeed   =  4;
    static immutable int ticksSlowMotion    = 45;
    static immutable int updatesDuringTurbo =  8;

    this(Level lv, Filename fn = null, Replay rp = null)
    {
        implGameConstructor(this, lv, fn, rp);
    }

    ~this()     { implGameDestructor(this); }

    void calc() { implGameCalc(this); }
    void draw() { implGameDraw(this); }

package:

    GameState cs; // current state
    bool      _gotoMenu;

    Level     level;
    Filename  levelFilename;
    Replay    replay;

    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.

    EffectManager effect;
    Panel pan;

    Tribe trlo;
    Tribe.Master malo;

    long altickLastUpdate;

    int _profilingGadgetCount;

}
