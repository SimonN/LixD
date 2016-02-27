module editor.editor;

/* I would like some MVC separation here. The model is class Level.
 * The Editor is Controller and View.
 */

import enumap;

import editor.calc;
import editor.draw;
import editor.hoveri;
import editor.io;
import editor.panel;
import file.filename;
import graphic.map;
import level.level;
import tile.pos;
import tile.gadtile;

class Editor {
package:
    Map      _map; // level background color, and gadgets
    Map      _mapTerrain; // transp, for rendering terrain, later blit to _map
    Level    _level;
    Filename _loadedFrom;

    bool _gotoMainMenu;
    EditorPanel _panel;

    Hover[] _hover;
    Hover[] _selection;

public:
    this(Filename fn)
    {
        _loadedFrom = fn;
        this.implConstructor();
    }

    ~this() { this.implDestructor(); }

    bool gotoMainMenu() const { return _gotoMainMenu; }

    void calc() { this.implEditorCalc(); }
    void draw() { this.implEditorDraw(); }
}
