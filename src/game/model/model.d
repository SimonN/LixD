module game.model.model;

/* Everything from the physics collected in one class, according to MVC.
 */

import game.model.state;

class GameModel {

    // eventually deprecate these
    @property inout(GameState) cs() inout { return _cs; }
    @property void cs(GameState s)  { _cs = s; }
    alias cs this;

    this()
    {
        _cs = new GameState;
    }

private:

    GameState _cs; // current state
}
