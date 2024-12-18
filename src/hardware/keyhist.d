module hardware.keyhist;

import std.algorithm;

import glo = basics.globals;

package:

struct KeyHistory {
    bool wasTapped;
    bool wasReleased;
    int isHeldForAlticks; // 0 while it's not held down.

    // For moving around terrain in the editor, and similar things that are
    // meaningful if executed both exactly once and many times in a row.
    bool wasTappedOrRepeated() const pure nothrow @safe @nogc
    {
        enum repeatSpeed = glo.ticksForDoubleClick * 3 / 5;
        return wasTapped || isHeldForAlticks > repeatSpeed;
    }

    void resetTappedAndReleased() pure nothrow @safe @nogc
    {
        wasTapped = false;
        wasReleased = false;
    }

    void updateHeldAccordingToTapped() pure nothrow @safe @nogc
    {
        if (wasReleased) {
            isHeldForAlticks = 0;
        }
        else if (wasTapped) {
            isHeldForAlticks = 1;
        }
        else if (isHeldForAlticks > 0) {
            ++isHeldForAlticks;
        }
    }

    // For lumping Enter and Keypad-Enter together.
    void mergeWith(ref typeof(this) other) pure nothrow @safe @nogc
    {
        wasTapped |= other.wasTapped;
        wasReleased |= other.wasReleased;
        isHeldForAlticks = wasReleased ? 0
            : max(isHeldForAlticks, other.isHeldForAlticks);
        other = this;
    }
}
