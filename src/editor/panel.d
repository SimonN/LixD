module editor.panel;

import std.conv;

import basics.globals;
import file.language;
import graphic.internal;
import gui;

class EditorPanel : Element {
private:
    TextButton     _info;
    BitmapButton[] _buttons;

public:
    this()
    {
        super(new Geom(0, 0, Geom.screenXlg, Geom.panelYlg, From.BOTTOM));
        makeInfo();
        makeButtons();
    }

    void onExecute(Lang buttonID, int hotkey, void delegate() deg)
    {
        assert (buttonID >= Lang.editorButtonFileNew
            &&  buttonID <= Lang.editorButtonAddHazard,
            "add delegates only for for Lang.editorButtonXYZ");
        immutable id = buttonID - Lang.editorButtonFileNew;
        _buttons[id].xf = id;
        _buttons[id].hotkey = hotkey;
        _buttons[id].onExecute = deg;
    }

protected:
    override void calcSelf()
    {
        assert (_info);
        _info.down = false;
        _info.text = "";
        foreach (id, button; _buttons)
            if (button.isMouseHere) {
                try _info.text = (id+Lang.editorButtonFileNew).to!Lang.transl;
                catch (ConvException) { }
            }
    }

private:
    void makeInfo()
    {
        _info = new TextButton(new Geom(0, 0, xlg, 20));
        import basics.alleg5;
        _info.alignLeft = true;
        _info.text = basics.user.keyEditorExit.hotkeyNiceBrackets
            ~ "exits the editor.";
        addChild(_info);
    }

    void makeButtons()
    {
        immutable int numButtons = Lang.editorButtonAddHazard
                                 - Lang.editorButtonFileNew + 1;
        immutable buttonYl = (Geom.panelYlg - _info.ylg) / 2;
        immutable buttonXl = Geom.screenXlg * 2 / numButtons;
        foreach (int i; 0 .. numButtons) {
            _buttons ~= new BitmapButton(new Geom(
                i/2*buttonXl, _info.ylg + i%2*buttonYl, buttonXl, buttonYl),
                fileImageEditPanel.getInternal);
            addChild(_buttons[$-1]);
            _buttons[$-1].xf = -1;
        }
    }
}
