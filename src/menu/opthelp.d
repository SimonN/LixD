module menu.opthelp;

/* Helper classes for the options dialogue.
 *
 * Subclasses of Option: Wraps the GUI elements through which an option is set,
 * and points to the value T that is used by the game and written to file.
 *
 * OptionFactory: computes the geom, incrementing the y position after each
 * factory(), and otherwise passes arguments to the Option subclass
 * constructors.
 */

import std.algorithm;

import gui;

abstract class Option : Element
{
    Label desc;

    abstract void loadValue();
    abstract void saveValue(); // can't be const

    this(Geom g, Label d)
    {
        assert (d);
        super(g);
        desc = d;
        addChild(desc);
    }
}

class CheckboxOption : Option
{
    Checkbox checkbox;
    bool*    target;

    this(Geom g, string cap, bool* t)
    {
        assert (t);
        if (g.yl < 1f)
            g.yl = 20f;
        checkbox = new Checkbox(new Geom(0, 0, 20, 20));
        super(g, new Label(new Geom(30, 0, g.xlg - 30, g.yl), cap));
        addChild(checkbox);
        target = t;
    }

    override void loadValue() { checkbox.checked = *target; }
    override void saveValue() { *target = checkbox.checked; }
}



// ############################################################################
// ############################################################################
// ############################################################################



struct OptionFactory {
    float x, y, xl, yl;
    float incrementY;

    Option factory(T, Args...)(Args argsToForward)
    {
        auto ret = new T(new Geom(x, y, xl, yl), argsToForward);
        y += incrementY;
        return ret;
    }
}
