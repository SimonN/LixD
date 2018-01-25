module game.panel.bigscore;

/*
 * Big score table. To be shown while you hover over the score bars during
 * a multiplayer game. Should ideally be shown after a networking game
 * in the lobby: The to-be-destroyed game should offer this
 * readily-instantiated UI widget to clients who don't even know about Tribes.
 *
 * The scoreboard isn't drawn onto any large button; you must supply that
 * yourself. Nonetheless, it clears its background to the default menu color.
 */

import gui;

class Scoreboard : Element {
    this(Geom g) {
        super(g);
    }
}
