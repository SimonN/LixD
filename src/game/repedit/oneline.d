module game.repedit.oneline;

/*
 * A button in the replay editor that represents a single replay action.
 *
 * Poll with suggestsChange(). If true, ask for the change
 * with suggestedChange().
 */

import std.format;
import std.range;

import file.replay.changerq;
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
        /*
         * We don't set an undraw color. Even though we want to be undrawn
         * when deleted, we will be deleted before we get a chance to undraw.
         * Therefore, our owner will redraw itself entirely after deleting us.
         * It's a hack.
         */
        _del = new TextButton(new Geom(0, 0, butXlg, g.ylg), "\u2715");
        _bar = new TextButton(new Geom(20, 0, g.xlg - 3 * butXlg, g.ylg));

        _earlier = new BitmapButton(new Geom(20, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _earlier.xf = 2;
        _later = new BitmapButton(new Geom(0, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _later.xf = 3;
        addChildren(_del, _bar, _earlier, _later);

        replayData = aRepData; // reformats the bar
    }

    @property Ply replayData() const pure nothrow @nogc
    {
        return _replayData;
    }

    @property Ply replayData(in Ply a)
    {
        if (a != _replayData) {
            _replayData = a;
            _bar.text = formatRepDataText(a);
        }
        return _replayData;
    }

    @property bool suggestsChange() const pure nothrow @nogc
    {
        return _del.execute || _earlier.execute || _later.execute;
    }

    @property ChangeRequest suggestedChange() const pure nothrow @nogc
    in {
        assert (suggestsChange,
            "check suggestsChange before calling suggestedChange");
    }
    body {
        return ChangeRequest(_replayData,
            _del.execute ? ChangeVerb.eraseThis
            : _earlier.execute ? ChangeVerb.moveThisEarlier
            : ChangeVerb.moveThisLater);
    }

protected:
    override void calcSelf()
    {
        _bar.down = false;
    }

private:
    void reformat()
    {

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
