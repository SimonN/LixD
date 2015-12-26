module game.gui.wduring;

/* The menu available on hitting ESC (or remapped key) during play. Different
 * from the menu at end of play.
 *
 *  class WindowDuringOffline -- playing singleplayer or
 *  class WindowDuringNetwork
 */

import game.gui.gamewin;
import gui;

private enum butXl  = 150;
private enum butYsp =  10;
private enum butYl  =  20;

private auto addButton(ref int y)
{
    auto b = new TextButton(new Geom(0, y, butXl, butYl, From.TOP));
    y += butYl + butYsp;
    return b;
}

class WindowDuringOffline : GameWindow {

    this()
    {
        enum numButtons = 4;
        super(new Geom(0, 0, butXl + 40, 60 + (numButtons - 1) * butYsp
                        +  numButtons * butYl, From.CENTER));
        int y = 40;
        _resume     = addButton(y);
        _restart    = addButton(y);
        _saveReplay = addButton(y);
        _exitGame   = addButton(y);
        super.captionGameWindowButtons();
    }
}



class WindowDuringNetwork : GameWindow {

    this()
    {
        enum numButtons = 4;
        super(new Geom(0, 0, butXl + 40, 60 + (numButtons - 1) * butYsp
                        +  numButtons * butYl, From.CENTER));
        int y = 40;
        _resume     = addButton(y);
        _saveReplay = addButton(y);
        _exitGame   = addButton(y);
        super.captionGameWindowButtons();
    }
}
