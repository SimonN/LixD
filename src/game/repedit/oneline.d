module game.repedit.oneline;

/*
 * A button in the replay editor that represents a single replay action.
 */

import std.format;
import std.range;

import gui;
import graphic.internal;
import net.ac;
import net.repdata;

class OneLine : Element {
private:
    TextButton _del;
    TextButton _bar; // long, unpressable bar with information
    BitmapButton _earlier;
    BitmapButton _later;

    Ply _replayData;
    enum butXlg = 20;

public:
    this(Geom g, in Ply aRepData)
    in { assert(g.xlg >= 4 * butXlg, "no space for row of text"); }
    body {
        super(g);
        _replayData = aRepData;

        _del = new TextButton(new Geom(0, 0, butXlg, g.ylg), "\u2715");
        _bar = new TextButton(new Geom(20, 0, g.xlg - 3 * butXlg, g.ylg));
        _bar.text = formatRepDataText(_replayData);

        _earlier = new BitmapButton(new Geom(20, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _earlier.xf = 8;
        _later = new BitmapButton(new Geom(0, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _later.xf = 11;
        addChildren(_del, _bar, _earlier, _later);
    }

    override void calcSelf()
    {
        _bar.down = false;
    }
}

/*
 * In the long run, let's replace this ugly string with nice icons.
 */
string formatRepDataText(in Ply aRepData) pure @safe
{
    return format!"%d %s #%d %s"(
        aRepData.update,
        aRepData.skill.acToString.take(3),
        aRepData.toWhichLix,
        // unicode: LEFTWARDS ARROW, RIGHTWARDS ARROW
        aRepData.action == RepAc.ASSIGN_LEFT ? "\u2190"
        : aRepData.action == RepAc.ASSIGN_RIGHT ? "\u2192" : "");
}
