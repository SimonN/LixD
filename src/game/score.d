module game.score;

/* Plain old data, to be passed between the UI and the Tribe team status.
 */

import net.style;

struct Score {
    Style style;
    int current; // should be > 0
    int potential; // should be larger than current to be visible
}
