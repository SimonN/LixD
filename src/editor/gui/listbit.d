module editor.gui.listbit;

/* ListBitmap : ListFile is what's used in the editor's terrain browser.
 * CombinedButton : ?? is used in ListBitmap.
 */

import file.filename;
import graphic.cutbit;
import gui;

// C++ lix has overriden void onDirLoad for L1/L2 graphic sets.
// We don't have any support for that yet. Implement if necessary.
class ListBitmap : ListFile {
public:
    this(Geom g) { super(g); }

protected:
    override Button newFileButton(int fromTop, int totalID, Filename f)
    {
        return new CombinedButton(new Geom(0, 0, 40, 40));
    }

    override Button newFlipButton()
    {
        return new CombinedButton(new Geom(50, 50, 40, 40));
    }
}

class CombinedButton : Button {
private:
    Label label;
    CutbitElement cb;

public:
    this(Geom g, const(Cutbit) c = null, string labelText = "") { super(g); }
}
