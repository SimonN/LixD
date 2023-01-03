module gui.radio;

/*
 * Series of radio buttons of which exactly one is selected at any time.
 */

import std.algorithm;
import std.conv;

import basics.help : len;
import gui;
import hardware.mouse;

class RadioButtons : Element {
private:
    Choice[] _choices;
    void delegate(int) _onExecute;

public:
    this(Geom g)
    in { assert (g.xl >= 20); }
    do { super(g); }

    void addChoice(string s)
    {
        auto b = new ChoiceButton(new Geom(0, _choices.len * 20f, 20, 20),
            6); // 6 is the x-frame for the active radio button.
        auto l = new Label(new Geom(30, _choices.len * 20f, xlg - 30, 20), s);
        b.onExecute = ()
        {
            choose(_choices.countUntil!(ch => ch.button is b).to!int);
        };
        _choices ~= Choice(b, l);
        addChildren(b, l);
        resize(this.xlg, _choices.len * 20f);
    }

    /*
     * Add a callback that gets fired whenever we choose a different option.
     * The callback is void delegate(int) and gets passed the number of the
     * new choice. We don't pass the old choice, change RadioButtons if needed.
     */
    @property void onExecute(typeof(_onExecute) f) { _onExecute = f; }

    // Returns -1 when nothing has been chosen yet
    @property int chosen() const
    {
        return _choices.countUntil!(ch => ch.button.checked).to!int;
    }

    void choose(int nr)
    in { assert (_choices.len, "add choices before choosing one of them"); }
    do {
        nr = nr.clamp(0, _choices.len - 1);
        if (nr == chosen)
            return;
        _choices.each!(ch => ch.button.checked = false);
        _choices[nr].button.checked = true;
        if (_onExecute)
            _onExecute(nr);
    }

protected:
    override void calcSelf()
    {
        // Allow clicks on the label to select the button. This functionality
        // is duplicated in boolean options in the options menu.
        // Maybe design a label-button-class that does this for us.
        foreach (const size_t nr, ref Choice ch; _choices)
            if (ch.label.isMouseHere && nr != chosen) {
                ch.button.down = mouseHeldLeft > 0;
                if (mouseReleaseLeft)
                    choose(nr.to!int);
            }
    }
}

// DTODOGUI: make our own button, don't have checkmarks
// And make a label that
private alias ChoiceButton = Checkbox;

private struct Choice {
    ChoiceButton button;
    Label label;
}
