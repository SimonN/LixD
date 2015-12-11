module game.core.physlix;

import game.core;
import lix;

void performSingleLix(Game game, Lixxie l, OutsideWorld* ow)
{
    l.performActivity(ow);

    // clear flags for next frame
    l.inBlockerFieldLeft  = false;
    l.inBlockerFieldRight = false;
    l.turnedByBlocker     = false;
}
