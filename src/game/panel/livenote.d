module game.panel.livenote;

import basics.help;
import basics.alleg5;
import glo = basics.globals;
import opt = file.option.allopts;
import graphic.color;
import gui;

import std.algorithm;
import std.conv;
import std.range;
import std.string;

class LivestreamNote : Element {
private:
    int firstSmallLine = -1;
    Label[] _labels;

public:
    this(Geom g, in SourceLine[] source)
    {
        super(g);
        foreach (line; source) {
            addLine(line);
        }
        foreach (size_t i, Label l; _labels) {
            l.move(0, ygFor(i & 0xFFFF));
        }
    }

    static struct SourceLine {
        string line;
        bool isBold;
    }

    static SourceLine[] readUserFile()
    {
        if (! glo.fileLivestreamNote.fileExists) {
            return [];
        }
        SourceLine[] ret = [];
        bool seenEmpty = false;
        foreach (rawBuffer; glo.fileLivestreamNote.openForReading.byLine) {
            const(char[]) strippedBuffer = rawBuffer.strip;
            if (strippedBuffer.empty) {
                seenEmpty = true;
                continue;
            }
            ret ~= SourceLine(strippedBuffer.to!string, ! seenEmpty);
        }
        return ret;
    }

protected:
    override void drawSelf()
    {
        al_draw_filled_rectangle(xs, ys,
            xs + xls, ys + yls, color.screenBorder);
    }

private:
    void addLine(in SourceLine msg)
    {
        auto next = new Label(new Geom(0, 0, xlg, 20f, From.TOP), msg.line);
        next.color = color.guiTextDark;

        if (firstSmallLine == -1 && ! msg.isBold) {
            firstSmallLine = _labels.len;
        }
        if (firstSmallLine >= 0) {
            next.font = djvuS;
        }
        addChild(next);
        _labels ~= next;
    }

    float ygFor(in int i) const pure nothrow @safe
    {
        return ylg / 2f
            + ygFromTopOfTextFor(i)
            - ygFromTopOfTextFor(_labels.len) / 2f;
    }

    float ygFromTopOfTextFor(in int i) const pure nothrow @safe
    {
        immutable int lastBigLine = firstSmallLine == -1
            ? int.max : firstSmallLine - 1;
        return iota(0, i)
            .map!(earlierLine
                => earlierLine < lastBigLine ? 16f // Space between 2 big lines
                : earlierLine == lastBigLine ? 22f // Separate smalls from bigs
                : 10f) // Space between 2 small lines
            .sum;
    }
}
