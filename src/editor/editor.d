module editor.editor;

/* I would like some MVC separation here. The model is class Level.
 * The Editor is Controller and View.
 */

import editor.calc;
import editor.draw;
import editor.io;
import file.filename;
import graphic.map;
import level.level;

class Editor {

    this(Filename fn) { this.implConstructor(fn); }

    bool gotoMainMenu() const { return _gotoMainMenu; }

    void calc() { this.implEditorCalc(); }
    void draw() { this.implEditorDraw(); }

package:

    bool _gotoMainMenu;

    Filename _loadedFrom;
    Level    _level;
    Map      _map;

}
