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
    TextButton _earlier;
    TextButton _later;
    PlyLineDesc _desc; // private class, defined below in this module

public:
    this(Geom g)
    {
        super(g);
        _del = new DarkTextButton(new Geom(0, 0, butXlg, g.ylg), "\u2715");
        _earlier = new DarkTextButton(new Geom(20, 0, butXlg, g.ylg,
            From.TOP_RIGHT), "\u2212");
        _later = new DarkTextButton(new Geom(0, 0, butXlg, g.ylg,
            From.TOP_RIGHT), "+");
        _desc = new PlyLineDesc(new Geom(20, 0, g.xlg - 3 * butXlg, g.ylg));
        addChildren(_del, _earlier, _later, _desc);
    }

    void ply(in Ply aPly)
    {
        phyu = aPly.when;
        _desc.ply = aPly;
    }

    Ply ply() const pure nothrow @safe @nogc
    {
        return _desc.ply;
    }

    bool suggestsChange() const pure nothrow @nogc
    {
        return _del.execute || earlierExecuted || laterExecuted;
    }

    ChangeRequest suggestedChange() const pure nothrow @nogc
    in {
        assert (suggestsChange,
            "check suggestsChange before calling suggestedChange");
    }
    do {
        if (_del.execute) {
            // Weird design. See assert in Game.cutSingleLixFutureFromReplay().
            Ply cutAfter = _desc.ply;
            cutAfter.when = Phyu(cutAfter.when - 1);
            return ChangeRequest(cutAfter, ChangeVerb.cutFutureOfOneLix);
        }
        return ChangeRequest(_desc.ply, earlierExecuted
            ? ChangeVerb.moveThisEarlier : ChangeVerb.moveThisLater);
    }

protected:
    override void onWhite(in bool b) { _desc.white = b; }

private:
    const pure nothrow @nogc {
        bool earlierExecuted() { return _earlier.execute; }
        bool laterExecuted() { return _later.execute; }
    }
}

class TweakerHeader : Element {
public:
    this(Geom g)
    {
        super(g);
        addChildren(
            // About the first label: Compare with PlyLineDesc.
            new Label(new Geom(xlg - 50, 0, 50, ylg, From.RIGHT),
                Lang.tweakerHeaderLixID.transl),
            new Label(new Geom(40, 0, xlg/2f, 20, From.RIGHT),
                Lang.tweakerHeaderTick.transl),
        );
    }
}

/*
 * +-------------+-------+--------------+
 * |    Lix ID   | Skill |     Phyu     |
 * |    = 30     |  20   |     40       |
 * +-------------+-------+--------------+
 * |                     |              |
 * |<---- Nuke text ---->|<--- Phyu --->|
 * |                     |              |
 * +---------------------+--------------+
 */

/*
 * All the info of a PlyLine, i.e., everything of PlyLine that is not a button.
 */
private class PlyLineDesc : Element {
private:
    Label _lixID;
    CutbitElement _skillIcon;
    Label _nukeName;
    Ply _ply;

public:
    this(Geom g)
    {
        super(g);
        _lixID = new Label(new Geom(xlg - 30, 0, 30, ylg, From.RIGHT));
        _skillIcon = new CutbitElement(new Geom(30, 0, 20, ylg),
            InternalImage.skillsInTweaker.toCutbit);
        _nukeName = new Label(new Geom(0, 0,
            NowLine.textXlg(g) + 3 * 20f /* 3*20 == 3 * butXlg */, ylg));
        addChildren(_lixID, _skillIcon, _nukeName);
    }

    void white(in bool b)
    {
        _lixID.color = b ? color.white : color.guiText;
    }

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
        if (_ply.isAssignment) {
            _lixID.text = _ply.toWhichLix.to!string;
            _skillIcon.show();
            _skillIcon.xf = 2 * _ply.skill.acToSkillIconXf
                + 1 * (_ply.lixShouldFace == Ply.LixShouldFace.left);
            _nukeName.text = "";
        }
        else { // Nuke
            _lixID.text = "";
            _skillIcon.hide();
            _nukeName.text = Lang.optionKeyNuke.transl;
        }
    }
}
