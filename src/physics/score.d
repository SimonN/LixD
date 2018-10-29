module physics.score;

/*
 * struct Score, function sortPreferringTeam
 *
 * Plain old data, to be passed between the UI and the Tribe team status.
 * Part of physics because Tribe must know about this. It's also sensible
 * to keep winner determination close to the physics.
 */

import std.algorithm;

import net.style;

struct Score {
    Style style;
    int current; // should be > 0
    int potential; // should be larger than current to be visible
    bool prefersGameToEnd; // should be filled by Tribe
}

void sortPreferringTeam(T)(T[] arr, in Style pref)
{
    static if (is (T : Score))
        arr.sort!((a, b) => betterThanPreferringTeam(a, b, pref));
    else
        arr.sort!((a, b) => betterThanPreferringTeam(a.score, b.score, pref));
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

// Test the else branch of sortPreferringTeam
unittest {
    struct Complicated { Score score; int unrelated; }
    Complicated[] arr = [
        Complicated(Score(Style.yellow, 0, 0), 333),
        Complicated(Score(Style.orange, 0, 0), 999),
        Complicated(Score(Style.red, 0, 0), 888),
    ];
    arr.sortPreferringTeam(Style.orange);
    assert (arr[0].unrelated == 999);
    assert (arr[1].unrelated == 888);
    assert (arr[2].unrelated == 333);
}
