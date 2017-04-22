module gui.console.console;

/* A console is a box with text lines.
 * There's a LobbyConsole that draws a frame and has lines in medium text.
 * There's an ingame console with transparent bg and has lines in small text.
 */

import std.array;
import std.conv;
import std.math;

import basics.alleg5;
import basics.help;
import graphic.color;
import graphic.textout;
import gui;
import gui.console.line;

abstract class Console : Element {
private:
    Line[] _lines; // defined below in this module

public:
    this(Geom g) { super(g); }

    void add     (in string textToPrint) { add(textToPrint, color.guiText); }
    void addWhite(in string textToPrint) { add(textToPrint, color.guiTextOn); }

    @property const(Line[]) lines() const { return _lines; }
    @property void lines(const(Line[]) aLines)
    {
        if (_lines.len) {
            foreach (ref line; _lines)
                rmChild(line.label);
            _lines = [];
            onLineChange();
        }
        foreach (old; aLines) {
            Line cloned = Line(old.label.text, lineFont,
                               old.label.color, this.xlg, lineYlg);
            cloned.birth = old.birth;
            addChild(cloned.label);
            _lines ~= cloned;
        }
        purgeAndMove();
    }

protected:
    abstract @property AlFont lineFont() const;
    abstract @property float lineYlg() const;
    abstract @property long ticksToLive() const;

    @property int maxLines() const { return ylg.to!int / lineYlg.floor.to!int;}
    @property int numLines() const { return _lines.len; }

    void onLineChange() { }
    void moveLine(ref Line line, int whichFromTop)
    {
        line.label.move(Geom.thickg, whichFromTop * lineYlg);
    }

    override void calcSelf() { purgeAndMove(); }

private:
    void add(in string textToPrint, in Alcol col)
    {
        foreach(ref l; LineFactory(textToPrint, lineFont, col, xlg, lineYlg)) {
            _lines ~= l;
            addChild(l.label);
        }
        purgeAndMove();
        onLineChange();
        reqDraw();
    }

    final void purgeAndMove()
    {
        while (_lines.length > 0 && (_lines.length > maxLines
                                || timerTicks > _lines[0].birth + ticksToLive)
        ) {
            rmChild(_lines[0].label);
            _lines = _lines[1 .. $];
            onLineChange();
            reqDraw();
        }
        foreach (int i, ref line; _lines)
            moveLine(line, i);
    }
}

class LobbyConsole : Console {
private:
    Frame _frame;

public:
    this(Geom g)
    {
        super(g);
        _frame = new Frame(new Geom(0, 0, xlg, ylg));
        addChild(_frame);
    }

protected:
    override @property AlFont lineFont() const { return djvuM; }
    override @property float lineYlg() const { return 20; }
    override @property long ticksToLive() const { return 999_999_999; } // inf

    override void moveLine(ref Line line, int whichFromTop)
    {
        // This y-positioning looks better: Slightly more space at the top
        // and bottom, slightly less space between lines.
        line.label.move(Geom.thickg, maxLines / 4f
                                    + (lineYlg - 0.5f) * whichFromTop);
    }

    override void drawSelf()
    {
        _frame.undraw(); // to clear the entire area before drawing text
    }
}

/* A transparent console. If stuff happens, maybe others should redraw.
 * Pass any ylg to this's geometry, doesn't matter.
 */
class TransparentConsole : Console {
private:
    // This is called whenever we've moved or erased lines, and the parent
    // or GUI elder shall redraw whatever we're on top on. That parent or
    // GUI elder shall register their own redraw-everything for this.
    // We might call this several times in a loop! The callback should merely
    // set a flag in the parent/GUI elder, not do expensive drawing!
    void delegate() _callbackOnLineChange;

public:
    this(Geom g, void delegate() f)
    {
        g.yl = 0f;
        super(g);
        assert (f, "Won't handle cleanup? See comment _callbackOnLineChange.");
        _callbackOnLineChange = f;
    }

protected:
    override @property AlFont lineFont() const { return djvuS; }
    override @property int maxLines() const { return 8; }
    override @property float lineYlg() const { return 13; }
    override @property long ticksToLive() const { return 10 * 60; }

    override void onLineChange()
    {
        resize(xlg, numLines * lineYlg);
        _callbackOnLineChange();
    }
}
