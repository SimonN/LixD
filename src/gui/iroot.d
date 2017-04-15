module gui.iroot;

/* Implement this one of these to be registrable with gui.root.
 * GUI Elements have this, but the editor has it too. The root makes it handle
 * its diagog boxes' focus correctly.
 */

interface IDrawable {
    void reqDraw(); // notify that it can't cut shortcuts in draw()
    bool draw(); // draws, returns true if this/any children required drawing.
}

interface IRoot : IDrawable {
    void calc(); // logic update when it has focus
    void work(); // logic update always, when it has focus or no focus
}
