module gui.msgbox;

/* These boxes pose a question and give a few buttons to click.
 * How to use: Create a box, add some msgs and buttons, and register it
 * as a focus element. The box deactivates itself on any button click.
 */

import std.algorithm;
import std.range;

import basics.help; // .len
import file.language;
import gui.buttext;
import gui.geometry;
import gui.label;
import gui.root;
import gui.window;

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

    auto addButton(in string caption, in int hotkey = 0)
    {
        _buttons ~= new TextButton(new Geom(0, 0, buttonXl, 20, From.BOTTOM));
        _buttons[$-1].text   = caption;
        _buttons[$-1].hotkey = hotkey;
        addChild(_buttons[$-1]);
        resize(thisXl, appropriateYl);
        foreach (int i, button; _buttons)
            button.move((-_buttons.len + 2*i + 1) * (buttonXl+20)/2 - 10, 20);
        return this;
    }

    @property execute() const
    {
        foreach (int i, button; _buttons)
            if (button.execute)
                return i+1;
        return 0;
    }

protected:

    override void calcSelf()
    {
        if (execute)
            rmFocus(this);
    }

private:

    Label[] _msgs;
    TextButton[] _buttons;

    @property float appropriateYl() { return (5 + _msgs.length) * 20; }
}
