module editor.editor;

/* I would like some MVC separation here. The model is class Level.
 * The Editor is Controller and View.
 */

import editor.calc;
import editor.draw;
import editor.io;
import editor.panel;
import file.filename;
import graphic.map;
import level.level;
import tile.pos;

class Editor {
package:
    Map      _map;
    Level    _level;
    Filename _loadedFrom;

    bool _gotoMainMenu;
    EditorPanel _panel;

    TerPos*[] _hoverTerrain;
    GadPos*[] _hoverGadgets;

public:
    this(Filename fn) { this.implConstructor(fn); }
    ~this()           { this.implDestructor();    }

    bool gotoMainMenu() const { return _gotoMainMenu; }

    void calc() { this.implEditorCalc(); }
    void draw() { this.implEditorDraw(); }
}
