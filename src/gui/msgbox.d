module gui.msgbox;

/* These boxes pose a question and give a few buttons to click.
 * How to use: Create a box, add some msgs and buttons, and register it
 * as a focus element. The box deactivates itself on any button click.
 *
 * To decide what to do after a button press, I had a choice about what
 * implementation to offer:
 *
 * a) Checking the return value of the box in the caller's calc()
 * b) Allowing callbacks to be registered on button creation
 * c) Both
 *
 * I chose b) only. Reason: a), and therefore c), lead to a flickering problem.
 * After the msgbox unfocuses itself, it is not drawn, but the calling
 * browser is not calced immediately. Therefore, a level to be deleted is
 * yet again drawn for a single frame.
 *
 * I could have edited the gui.root source to always calc the next focus/elders
 * when a focus (the msgbox in our case) unfocuses itself. The problem here
 * would be: The browser reads the hotkey input again. OK and "start replay"
 * are on the same hotkey by default. This would delete a level, select a
 * new one, and play that immediately.
 */

import std.algorithm;
import std.range;

import basics.help; // .len
import file.language;
import hardware.keyset;
import gui;

class MsgBox : Window {

    enum buttonXl = 100;
    enum thisXl   = 580;

    this(in string title = "")
    {
        super(new Geom(0, 0, thisXl, appropriateYl, From.CENTER), title);
    }

    auto addMsg(in string msg)
    {
        _msgs ~= new Label(new Geom(20, 40+_msgs.len*20, thisXl-40, 20), msg);
        addChild(_msgs[$-1]);
        resize(thisXl, appropriateYl);
        return this;
    }

    auto addButton(in string caption,
        in KeySet hotkey = 0,
        in void delegate() callback = null
    ) {
        _buttons ~= new TextButton(new Geom(0, 0, buttonXl, 20, From.BOTTOM));
        _buttons[$-1].text   = caption;
        _buttons[$-1].hotkey = hotkey;
        if (callback)
            _buttons[$-1].onExecute = callback;
        addChild(_buttons[$-1]);
        resize(thisXl, appropriateYl);
        foreach (int i, button; _buttons)
            button.move((-_buttons.len + 2*i + 1) * (buttonXl+20)/2 - 10, 20);
        return this;
    }

protected:

    override void calcSelf()
    {
        if (_buttons.any!(b => b.execute))
            rmFocus(this);
    }

private:

    Label[] _msgs;
    TextButton[] _buttons;

    @property float appropriateYl() { return (5 + _msgs.length) * 20; }
}
