module game.window.multi;

import std.array;
import std.algorithm;
import std.range;
import std.typecons;

import basics.user;
import game.window.base;
import game.tribe;
import game.replay;
import graphic.color;
import gui;
import net.style;
import level.level;

class WindowEndMulti : GameWindow {
private:
    Style _ourStyle;

public:
    this(in Tribe[Style] rawTribes,
        in Replay replay, in Level level)
    {
        super(myGeom(2, butXl + 40,
            20 // space between list and first button
            + 20 * rawTribes.length & 0xFFFF));
        // Stuff that should be refactored because it appears in every
        // child class, almost copy-pasted:
        {
            import std.conv;
            int y = this.ylg.to!int - 70;
            _saveReplay = addButton(y);
            _exitGame   = addButton(y);
            _exitGame.hotkey = keyMenuOkay; // super will add more keys to that
            super.captionSuperElements();
            super.setReplayAndLevel(replay, level);
        }
        _ourStyle = replay.playerLocalOrSmallest.style;
        foreach (int i, tribe; sortedTribes(rawTribes))
            addChild(new Line(new Geom(0, 40 + 20*i, xlg-40, 20, From.TOP),
                tribe, replay.styleToNames(tribe.style)));
    }

private:
    Rebindable!(const Tribe)[] sortedTribes(in Tribe[Style] unsorted)
    {
        bool higher(in Tribe a, in Tribe b)
        {
            return a.score.current > b.score.current
                || a.score.current == b.score.current && a.style == _ourStyle;
        }
        auto arr = unsorted.byValue.map!(a => rebindable(a)).array;
        arr.sort!higher;
        return arr;
    }

    class Line : Element {
        this(Geom g, in Tribe tribe, in string tribeName)
        {
            super(g);
            auto a = new Label(new Geom(0, 0, xlg*4f/5f, ylg), tribeName);
            auto b = new Label(new Geom(0, 0, xlg/5f, ylg, From.TOP_RIG));
            b.number = tribe.score.current;
            if (tribe.style == _ourStyle)
                a.color = b.color = color.white;
            addChildren(a, b);
        }
    }
}
