module game.score.score;

/*
 * struct Score, function sortPreferringTeam
 *
 * Plain old data, to be passed between the UI and the Tribe team status.
 */

import std.algorithm;

import net.style;

struct Score {
    Style style;
    int current; // should be > 0
    int potential; // should be larger than current to be visible
    bool prefersGameToEnd; // should be filled by Tribe
}

void sortPreferringTeam(Score[] arr, in Style preferred)
{
    arr.sort!((a, b) => betterThanPreferringTeam(a, b, preferred));
}

// Sort better scores to earlier positions.
bool betterThanPreferringTeam(in Score a, in Score b, in Style preferred)
{
    return a.current > b.current ? true
        : a.current < b.current ? false
        : a.potential > b.potential ? true
        : a.potential < b.potential ? false
        : a.style == preferred && b.style != preferred ? true
        : a.style != preferred && b.style == preferred ? false
        : a.style < b.style;
}

unittest {
    Score[] arr = [
        Score(Style.yellow, 0, 0),
        Score(Style.blue, 0, 0),
        Score(Style.green, 0, 0),
        Score(Style.garden, 0, 0),
    ];
    arr.sortPreferringTeam(Style.green);
    assert (arr[0].style == Style.green);
    assert (arr[1].style == Style.garden);
}
