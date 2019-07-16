module game.repedit.oneline;

/*
 * A button in the replay editor that represents a single Ply (replay action).
 *
 * Poll with suggestsChange(). If true, ask for the change
 * with suggestedChange().
 */

import std.conv;
import std.format;
import std.range;

import file.language;
import file.replay.tweakrq;
import gui;
import graphic.color;
import graphic.internal;
import net.repdata;

class OneLine : Element {
private:
    TextButton _del;
    OneLineDesc _desc; // private class, defined below in this module
    BitmapButton _earlier;
    BitmapButton _later;

    enum butXlg = 20;

public:
    this(Geom g)
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
        _desc = new OneLineDesc(new Geom(20, 0, g.xlg - 3 * butXlg, g.ylg));

        _earlier = new BitmapButton(new Geom(20, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _earlier.xf = 2;
        _later = new BitmapButton(new Geom(0, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _later.xf = 3;
        addChildren(_del, _desc, _earlier, _later);
    }

    @property Ply ply(in Ply aPly) { return _desc.ply = aPly; }

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
        return ChangeRequest(_desc.ply,
            _del.execute ? ChangeVerb.eraseThis
            : _earlier.execute ? ChangeVerb.moveThisEarlier
            : ChangeVerb.moveThisLater);
    }
}

class TweakerHeader : Element {
public:
    this(Geom g) { with (DescRelativePositions)
    {
        super(g);
        addChildren(
            new Label(new Geom(20 + thickg, 0, xlg/2f, 20),
                Lang.tweakerHeaderLixID.transl),
            new Label(new Geom(40 + thickg, 0, xlg/2f, 20, From.RIGHT),
                Lang.tweakerHeaderPhyu.transl),
        );
    }}
}

/*
 * +-----------+--------+-----------+--------------+
 * |    Lix    |  Dir   |   Skill   |     Phyu     |
 * |     ID    | arrow  |    name   |              |
 * |           |        |           |              |
 * |<---3/12-->|<-2/12->|<---3/12-->|<----4/12---->|
 * +-----------+--------+-----------+--------------+
 */
private enum DescRelativePositions : float {
    xlL = 3f/12f,
    xlD = 2f/12f,
    xlS = 3f/12f,
    xlP = 4f/12f,
}

/*
 * All the info of a OneLine, i.e., everything of OneLine that is not a button.
 */
private class OneLineDesc : Element {
private:
    Label _lixID;
    Label _directionalForceArrow;
    Label _skillName;
    Label _phyu;
    Ply _ply;

public:
    this(Geom g) { with (DescRelativePositions)
    {
        super(g);
        _lixID = new Label(new Geom(
            xlg * (1-xlL), 0, xlg * (1-xlL) - thickg, ylg, From.RIGHT));
        _directionalForceArrow = new Label(new Geom(
            xlg * xlL - xlg/2f + (xlg * xlD)/2f,
            0, xlg * xlD, ylg, From.CENTER));
        _skillName = new Label(new Geom(
            xlg * (xlL + xlD), 0, xlg * xlS, ylg, From.LEFT));
        _phyu = new Label(new Geom(
            thickg, 0, xlg * xlP, ylg, From.RIGHT));
        addChildren(_lixID, _directionalForceArrow, _skillName, _phyu);
    }}

    @property Ply ply() const pure nothrow @nogc
    {
        return _ply;
    }

    @property Ply ply(in Ply aPly)
    {
        if (aPly == _ply) {
            return _ply;
        }
        reqDraw();
        _ply = aPly;
        _lixID.text = _ply.toWhichLix.to!string;
        _directionalForceArrow.text
            = _ply.action == RepAc.ASSIGN_LEFT
            ? "\u25C4" // unicode: Black left-pointing pointer
            : _ply.action == RepAc.ASSIGN_RIGHT
            ? "\u25BA" // unicode: Black right-pointing pointer
            : "";
        _skillName.text = _ply.skill.acToNiceCase.take(3).to!string;
        _phyu.text = _ply.update.to!string;
        return _ply;
    }

protected:
    override void drawSelf()
    {
        undrawColor = color.guiM; // Erase the labels, they can't undraw
        undraw();
    }
}
