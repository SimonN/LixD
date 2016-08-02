module editor.gui.panel;

import std.algorithm;
import std.conv;
import std.range;
import std.string;

import basics.globals;
import basics.user; // FPS
import file.filename; // currentFilename
import file.language;
import graphic.internal;
import gui;
import hardware.display; // FPS
import hardware.keyset;

class EditorPanel : Element {
private:
    TextButton     _info;
    BitmapButton[] _buttons;
    TextButton[]   _textButtons;
    Label          _fps;
    MutFilename    _currentFilename;

public:
    this()
    {
        super(new Geom(0, 0, Geom.screenXlg, Geom.panelYlg, From.BOTTOM));
        makeInfo();
        makeButtons();
    }

    // this is only to display the correct file in the tooltip
    Filename currentFilename(Filename fn)
    {
        _currentFilename = fn;
        return fn;
    }

    void onExecute(Lang buttonID, KeySet hotkey, void delegate() deg,
        Button.WhenToExecute wte = Button.WhenToExecute.whenMouseRelease
    ) {
        assert (buttonID >= Lang.editorButtonFileNew
            &&  buttonID <= Lang.editorButtonAddHazard,
            "add delegates only for for bitmap buttons, Lang.editorButtonXYZ");
        immutable id = buttonID - Lang.editorButtonFileNew;
        _buttons[id].xf = id;
        _buttons[id].hotkey = hotkey;
        _buttons[id].onExecute = deg;
        _buttons[id].whenToExecute = wte;
    }

    void onExecuteText(Lang langID, Lang cap, KeySet hk, void delegate() deg)
    {
        assert (langID >= Lang.editorButtonMenuConstants
            &&  langID <= Lang.editorButtonMenuSkills);
        immutable id = langID - Lang.editorButtonMenuConstants;
        _textButtons[id].hotkey    = hk;
        _textButtons[id].text      = cap.transl;
        _textButtons[id].onExecute = deg;
    }

    void allButtonsOff()
    {
        chain(_buttons, _textButtons).each!(but => but.on = false);
    }

    // Some buttons have special handling that doesn't match the button's
    // hotkey handling. These buttons are managed by hand in the editor class.
    @property inout(Button) button(in Lang id) inout
    {
        assert (id >= Lang.editorButtonFileNew);
        assert (id <= Lang.editorButtonMenuSkills);
        return  id <  Lang.editorButtonMenuConstants
            ? _buttons[id - Lang.editorButtonFileNew]
            : _textButtons[id - Lang.editorButtonMenuConstants];
    }

    @property buttonFraming() inout {
        return button(Lang.editorButtonSelectFrame);
    }
    @property buttonSelectAdd() inout {
        return button(Lang.editorButtonSelectAdd);
    }

    string info(string text)
    {
        // Don't overwrite button explanations with the editor's description
        // about its hover or selection. _info.text != "" iff mouse on panel.
        if (_info.text.empty)
            _info.text = text;
        return text;
    }

    // This was in calcSelf(), but we take special care for the editor panel.
    // We want to run this function every frame, because editor.draw runs
    // this.info(string text). We don't want to run calc() and all children's
    // calcSelf() during dragging, that's why the editor registers the panel
    // as a drawingOnlyElder.
    void calcButDisableMouse()
    {
        calcInfoBar();
        foreach (bb; _buttons) {
            if (bb.hotkey.keyHeld)
                bb.calc();
            bb.down = false;
        }
    }

protected:
    override void calcSelf()
    {
        calcInfoBar();
        writeButtonTooltips();
    }

private:
    float infoXl()
    {
        return Geom.screenXlg * 6f/7f;
    }

    void makeInfo()
    {
        _info = new TextButton(new Geom(0, 0, infoXl(), 20));
        _info.alignLeft = true;
        _fps  = new Label(new Geom(4 + xlg - _info.xlg,
                                   0, 100, 20, From.TOP_RIGHT));
        addChildren(_info, _fps);
    }

    void makeButtons()
    {
        immutable int bitmaps = Lang.editorButtonAddHazard
                              - Lang.editorButtonFileNew + 1;
        immutable int texts = 4;
        immutable bitmapXl = infoXl * 2f / bitmaps;
        immutable bitmapYl = (Geom.panelYlg - _info.ylg) / 2;
        immutable textXl = Geom.screenXlg - infoXl();
        immutable textYl = Geom.panelYlg / texts;
        foreach (int i; 0 .. bitmaps) {
            _buttons ~= new BitmapButton(new Geom(
                i/2*bitmapXl, _info.ylg + i%2*bitmapYl, bitmapXl, bitmapYl),
                fileImageEditPanel.getInternal);
            addChild(_buttons[$-1]);
            _buttons[$-1].xf = -1;
        }
        foreach (int i; 0 .. texts) {
            _textButtons ~= new TextButton(new Geom(
                            0, i * textYl, textXl, textYl, From.TOP_RIGHT));
            addChild(_textButtons[$-1]);
        }
    }

    void calcInfoBar()
    {
        assert (_info);
        _info.down = false;
        _info.text = "";
        if (basics.user.showFPS.value)
            _fps.text = "FPS: %d".format(displayFps);
    }

    void writeButtonTooltips()
    {
        foreach (id, bb; _buttons)
            if (bb.isMouseHere) {
                try _info.text = (id+Lang.editorButtonFileNew).to!Lang.transl;
                catch (ConvException) { }
                if (id + Lang.editorButtonFileNew == Lang.editorButtonFileSave
                    && _currentFilename !is null
                ) {
                    _info.text = "%s %s".format(_info.text,
                                        _currentFilename.rootful);
                }
            }
        foreach (id, tb; _textButtons)
            if (tb.isMouseHere) {
                try _info.text = (id + Lang.editorButtonMenuConstants)
                                   .to!Lang.transl;
                catch (ConvException) { }
            }
    }
}
