module gui.option.base;

/* Wrapping a GUI element with a label. These are used in the options dialogue
 * and in the editor windows.
 *
 * Subclasses of Option: Wraps the GUI elements through which an option is set,
 * and points to the value T that is used by the game and written to file.
 *
 * Important! Geom must be the first argument of any constructor of a subclass
 * of Option. Otherwise, OptionFactory will choke on that type.
 *
 * OptionFactory: computes the geom, incrementing the y position after each
 * factory(), and otherwise passes arguments to the Option subclass
 * constructors.
 */

import gui.element;
import gui.geometry;
import gui.label;

enum spaceGuiTextX =  10f;
enum mostButtonsXl = 120f;
enum keyButtonXl   =  85f;

abstract class Option : Element {
private:
    Label _desc; // may be null
    string _longDesc;

public:
    // Idea for refactoring: Let this take a UserOption instead of
    // the raw parameters
    this(Geom g, Label d = null)
    {
        super(g);
        _desc = d;
        if (_desc)
            addChild(_desc);
    }

    abstract void loadValue();
    abstract void saveValue(); // can't be const
    string explain() const { return ""; } // DTODO: make fully abstract
}

struct OptionFactory {
    float x, y, xl, yl = 20f;
    float incrementY   = 30f;
    Geom.From from     = From.TOP_LEFT;

    Option factory(T, Args...)(Args argsToForward)
    {
        auto ret = new T(new Geom(x, y, xl, yl, from), argsToForward);
        y += incrementY;
        return ret;
    }
}
