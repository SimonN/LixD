module game.game;

/* 2015-06-03. After 9 years, it's time to write another one of these classes.
 *
 * There are many methods that were distributed over many files in C++.
 * Here, we don't declare any private (accessible from same file) members,
 * but everything is package (accessible from files in same directory).
 */

public import basics.cmdargs : Runmode;

import basics.alleg5;
import basics.globals;
import basics.help : len;
import file.filename;
import game;
import graphic.color;
import graphic.map;
import gui;
import level.level;

class Game {

    @property bool gotoMenu() { return _gotoMenu; }

    enum ticksNormalSpeed   = 4;
    enum updatesDuringTurbo = 9;
    enum updatesBackMany    = ticksPerSecond / ticksNormalSpeed * 1;
    enum updatesAheadMany   = ticksPerSecond / ticksNormalSpeed * 10;

    this(Runmode rm, Level lv, Filename fn = null, Replay rp = null)
    {
        this.runmode = rm;
        implGameConstructor(this, lv, fn, rp);
    }

    ~this()     { implGameDestructor(this); }

    void calc() { implGameCalc(this); }
    void draw() { implGameDraw(this); }

package:

    bool _gotoMenu;
    immutable Runmode runmode;

    Level     level;
    Filename  levelFilename;
    Replay    replay;

    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.

    GameState cs; // current state
    StateManager stateManager;

    EffectManager effect;
    Panel pan;

    int _indexTribeLocal;
    int _indexMasterLocal;

    long altickLastUpdate;

    int _profilingGadgetCount;

    @property inout(Tribe) tribeLocal() inout
    {
        assert (cs);
        assert (cs.tribes.length > _indexTribeLocal);
        return cs.tribes[_indexTribeLocal];
    }

    @property ref inout(Tribe.Master) masterLocal() inout
    {
        assert (cs);
        assert (cs.tribes.len > _indexTribeLocal);
        assert (cs.tribes[_indexTribeLocal].masters.len > _indexMasterLocal);
        return cs.tribes[_indexTribeLocal].masters[_indexMasterLocal];
    }

}
