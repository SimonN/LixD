module editor.gui.custgrid;

import file.option;
import file.language;
import graphic.internal;
import gui;

class CustGridButton : BitmapButton {
private:
    Label _gridSize;

public:
    this(Geom g)
    {
        super(g, InternalImage.editPanel.toCutbit);
        xf = Lang.editorButtonGridCustom - Lang.editorButtonFileNew;

        _gridSize = new Label(new Geom(0, 0, xlg, 20, From.CENTER));
        addChild(_gridSize);
        _gridSize.number = editorGridCustom.value;
    }

protected:
    override void drawOntoButton()
    {
        super.drawOntoButton();
        _gridSize.number = editorGridCustom.value;
        _gridSize.color = this.colorText();
    }
}
