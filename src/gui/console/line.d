module gui.console.line;

// Line is a helper struct for the console, it's a word-wrapped text line.
// LineFactory takes a string and is a forward range returning word-wrapped
// lines, until the entire input string has been used.

import std.range;

import basics.alleg5;
import gui.label;
import gui.geometry;

package struct Line {
    long birth; // Allegro 5 timer tick when we added this
    Label label;

    this(in string textToPrint, Alfont font, in Alcol col,
                                in float xlg, in float ylg
    ) {
        birth = timerTicks;
        label = new Label(new Geom(0, 0, xlg, ylg));
        label.font = font;
        label.text = textToPrint;
        label.color = col;
    }
}

static assert (isForwardRange!LineFactory);

package struct LineFactory {
private:
    string _input;
    Alfont _font;
    Alcol _col;
    float _xlg, _ylg;

    Line _next;
    enum indentationXlg = 40f;

public:
    this(in string textToPrint, Alfont font, in Alcol col,
                                in float xlg, in float ylg)
    {
        _input = textToPrint;
        _font = font;
        _col = col;
        _xlg = xlg;
        _ylg = ylg;
        if (! empty)
            generateNext();
        else
            // Generate at least one empty line. Without this, our algo would // generate zero lines from an empty input, not the empty line.
            _next = Line("", _font, _col, _xlg, _ylg);
    }

    @property bool empty() const { return _input.empty && _next == _next.init;}
    @property auto front() inout { return _next; }
    @property void popFront()    { generateNext(); }
    @property auto save()        { return this; }

private:
    void generateNext()
    {
        assert (! empty);
        if (_input.empty) {
            _next = _next.init;
            return;
        }
        _next = Line(_input, _font, _col, _xlg, _ylg);
        if (! _next.label.tooLong(_input)) {
            // _next must be final line. Offer _next unchanged.
            _input = "";
            return;
        }
        // Not the final line. Take some words out of _input for the line.
        // Leave the other words in _input for later lines.
        _next.label.text = "";
        int pos = 0;
        while (pos < _input.length) {
            pos = spaceAfterNextWord(pos);
            if (_next.label.text.empty // put at least 1 word
                || ! _next.label.tooLong(_input[0 .. pos])) // put more than 1
                _next.label.text = _input[0 .. pos];
            else
                break;
        }
        // We have feeble indentation by leaving all spaces in the
        // input stream and wrapping them to the beginning of the
        // next line. If you want nice indentation, invest more work.
        _input = _input[_next.label.text.length .. $];
        assert (_input.empty || _input.front == ' ');
    }

    int spaceAfterNextWord(int pos) const
    {
        assert (pos >= 0);
        while (pos < _input.length && _input[pos] == ' ') ++pos;
        while (pos < _input.length && _input[pos] != ' ') ++pos;
        return pos;
    }
}
