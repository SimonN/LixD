module gui.console;

import std.conv;
import std.math;

/* A console is a box with text lines.
 * There's a LobbyConsole that draws a frame and has lines in medium text.
 * There's an ingame console with transparent bg and has lines in small text.
 */

import basics.alleg5;
import basics.globals;
import graphic.color;
import graphic.textout;
import gui;

abstract class Console : Element {
private:
    Line[] _lines; // defined below in this module

public:
    this(Geom g) { super(g); }

    void add     (in string textToPrint) { add(textToPrint, color.guiText); }
    void addWhite(in string textToPrint) { add(textToPrint, color.guiTextOn); }

protected:
    abstract @property AlFont lineFont() const;
    abstract @property float lineYlg() const;
    abstract @property long ticksToLive() const;

    @property int maxLines() const { return ylg.to!int / lineYlg.floor.to!int;}

    void moveLine(ref Line line, int whichFromTop)
    {
        line.label.move(Geom.thickg, whichFromTop * lineYlg);
    }

    override void calcSelf()
    {
        purgeAndMove();
    }

private:
    void add(in string textToPrint, in Alcol col)
    {
        _lines ~= Line(this, textToPrint, col);
        purgeAndMove();
        reqDraw();
    }

    final void purgeAndMove() {
        while (_lines.length > 0 && (_lines.length > maxLines
                                || timerTicks > _lines[0].birth + ticksToLive)
        ) {
            rmChild(_lines[0].label);
            _lines = _lines[1 .. $];
            reqDraw();
        }
        foreach (int i, ref line; _lines)
            moveLine(line, i);
    }
}

private struct Line {
    long birth; // Allegro 5 timer tick when we added this
    Label label;

    this(Console parent, in string textToPrint, in Alcol col)
    {
        birth = timerTicks;
        label = new Label(new Geom(0, 0, parent.xlg, parent.lineYlg));
        label.font = parent.lineFont;
        label.text = textToPrint;
        label.color = col;
        parent.addChild(label);
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
