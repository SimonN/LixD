module gui.radio;

/*
 * Series of radio buttons of which exactly one is selected at any time.
 */

import std.algorithm;

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
    in {
        assert (this.ylg >= _choices.len * 20f, "Too small to add another.");
    }
    do {
        _choices ~= new Choice(new Geom(0, _choices.len * 20f, xlg, 20f), s);
        addChild(_choices[$-1]);
    }

    /*
     * Add a callback that gets fired whenever we choose a different option.
     * The callback is void delegate(int) and gets passed the number of the
     * new choice. We don't pass the old choice, change RadioButtons if needed.
     */
    void onExecute(typeof(_onExecute) f) { _onExecute = f; }

    // Returns -1 when the mouse is over neither choice.
    int theHovered() const
    {
        return _choices.countUntil!(ch => ch.isMouseHere) & 0xFFFF;
    }

    // Returns -1 when nothing has been chosen yet
    int theChosen() const
    {
        return _choices.countUntil!(ch => ch.isChosen) & 0xFFFF;
    }

    void choose(int nr)
    in { assert (_choices.len, "add choices before choosing one of them"); }
    do {
        nr = nr.clamp(0, _choices.len - 1);
        if (nr == theChosen)
            return;
        foreach (ch; _choices) {
            ch.unchoose();
        }
        _choices[nr].choose();
        if (_onExecute)
            _onExecute(nr);
    }

protected:
    override void calcSelf()
    {
        foreach (i; 0 .. _choices.len) {
            if (_choices[i].execute()) {
                choose(i);
                break;
            }
        }
    }
}

private alias ChoiceButton = Checkbox;

private class Choice : Element {
    ChoiceButton _button;
    Label _label;
    bool _labelWasExecuted;

    this(Geom g, string s) {
        super(g);
        // 6 is the x-frame for the active radio button.
        _button = new ChoiceButton(new Geom(0, 0, 20, 20), 6);
        _label = new Label(new Geom(30, 0, xlg - 30, 20), s);
        addChildren(_button, _label);
    }

    pure nothrow @safe @nogc {
        bool execute() const { return _button.execute || _labelWasExecuted; }
        bool isChosen() const { return _button.isChecked;}
        void choose() { _button.checked = true; }
        void unchoose() { _button.checked = false; }
    }

protected:
    override void calcSelf()
    {
        _labelWasExecuted = false;
        if (isChosen) {
            _button.down = false;
            return;
        }
        // Allow clicks on the label, or into space between button and label.
        // This functionality is duplicated in boolean options in the options
        // menu. Maybe design a label-button-class that does this for us.
        if (isMouseHere) {
            _button.down = mouseHeldLeft > 0;
            _labelWasExecuted = mouseReleaseLeft > 0;
        }
    }
}
