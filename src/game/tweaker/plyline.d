module game.tweaker.plyline;

/*
 * A button in the replay tweaker that represents a single Ply (replay action).
 *
 * Poll with suggestsChange(). If true, ask for the change
 * with suggestedChange().
 */

import std.conv;
import std.format;
import std.range;

import file.language;
import file.replay.tweakrq;
import game.tweaker.oneline;
import game.tweaker.nowline; // Nuke button's text is like NowLine's text.
import gui;
import graphic.color;
import graphic.internal;
import net.repdata;

class PlyLine : OneLine {
private:
    TextButton _del;
    BitmapButton _earlier;
    BitmapButton _later;
    PlyLineDesc _desc; // private class, defined below in this module

public:
    this(Geom g)
    {
        super(g);
        _del = new TextButton(new Geom(0, 0, butXlg, g.ylg), "\u2715");
        _earlier = new BitmapButton(new Geom(20, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _earlier.xf = 2;
        _later = new BitmapButton(new Geom(0, 0, butXlg, g.ylg,
            From.TOP_RIGHT), InternalImage.guiNumber.toCutbit);
        _later.xf = 3;
        _desc = new PlyLineDesc(new Geom(20, 0, g.xlg - 3 * butXlg, g.ylg));
        addChildren(_del, _earlier, _later, _desc);
    }

    void ply(in Ply aPly)
    {
        phyu = aPly.update;
        _desc.ply = aPly;
    }

    Ply ply() const pure nothrow @safe @nogc
    {
        return _desc.ply;
    }

    @property bool suggestsChange() const pure nothrow @nogc
    {
        return _del.execute || earlierExecuted || laterExecuted;
    }

    @property ChangeRequest suggestedChange() const pure nothrow @nogc
    in {
        assert (suggestsChange,
            "check suggestsChange before calling suggestedChange");
    }
    do {
        return ChangeRequest(_desc.ply,
            _del.execute ? ChangeVerb.eraseThis
            : earlierExecuted ? ChangeVerb.moveThisEarlier
            : ChangeVerb.moveThisLater);
    }

private:
    @property const pure nothrow @nogc {
        bool earlierExecuted() { return _earlier.execute; }
        bool laterExecuted() { return _later.execute; }
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
 * |                                |              |
 * |<---------- Nuke text --------->|<--- Phyu --->|
 * |                                |              |
 * +--------------------------------+--------------+
 */
private enum DescRelativePositions : float {
    xlL = 3f/12f,
    xlD = 2f/12f,
    xlS = 3f/12f,
}

/*
 * All the info of a PlyLine, i.e., everything of PlyLine that is not a button.
 */
private class PlyLineDesc : Element {
private:
    Label _lixID;
    Label _directionalForceArrow;
    Label _skillName;
    Label _nukeName;
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
        _nukeName = new Label(new Geom(
            NowLine.textButtonDistXg(g), 0,
            NowLine.textXlg(g) + 3 * 20f /* 3*20 == 3 * butXlg */, ylg));
        addChildren(_lixID, _directionalForceArrow, _skillName, _nukeName);
    }}

    Ply ply() const pure nothrow @safe @nogc
    {
        return _ply;
    }

    void ply(in Ply aPly)
    {
        if (aPly == _ply) {
            return;
        }
        reqDraw();
        _ply = aPly;
        if (_ply.isSomeAssignment) {
            _lixID.text = _ply.toWhichLix.to!string;
            _directionalForceArrow.text
                = _ply.action == RepAc.ASSIGN_LEFT
                ? "\u25C4" // unicode: Black left-pointing pointer
                : _ply.action == RepAc.ASSIGN_RIGHT
                ? "\u25BA" // unicode: Black right-pointing pointer
                : ""; // no extra symbol for unforced assignment or nuke
            _skillName.text = _ply.skill.acToNiceCase.take(3).to!string;
            _nukeName.text = "";
        }
        else { // Nuke
            _lixID.text = "";
            _directionalForceArrow.text = "";
            _skillName.text = "";
            _nukeName.text = Lang.optionKeyNuke.transl;
        }
    }
}
