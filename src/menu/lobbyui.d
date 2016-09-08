module menu.lobbyui;

/* Extra UI elements that appear only in menu.lobby:
 * The list of players in the room, and the netplay color selector.
 */

import std.conv;
import std.math;
import std.range;

import gui;
import net.structs;

// Opportunity for refactoring: Make the buttons tileable with the scrollbar
// from the picker. Need an interface for a tileable list of elements.
class PeerList : Element {
private:
    Frame _frame;
    TextButton[] _buttons;

public:
    this(Geom g)
    {
        super(g);
        _frame = new Frame(new Geom(0, 0, xlg, ylg));
        addChild(_frame);
    }

    @property float buttonYlg() const { return 20f; }
    @property int maxButtons() const { return (ylg / buttonYlg).floor.to!int; }

    void recreateButtonsFor(const(Profile[]) players)
    {
        reqDraw();
        foreach (b; _buttons)
            rmChild(b);
        _buttons = [];
        foreach (i, profile; players.take(maxButtons)) {
            auto b = new TextButton(new Geom(0, i*buttonYlg, xlg, buttonYlg));
            b.alignLeft = true;
            b.text = profile.name;
            b.checkFrame = profile.feeling;
            _buttons ~= b;
            addChild(b);
        }
    }

protected:
    override void drawSelf() { _frame.undraw(); }
    override void undrawSelf() { _frame.undraw(); } // frame bigger than this.
}
