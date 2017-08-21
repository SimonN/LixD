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
    BitmapButton[] _buttons; // except zoom button, but still has slot for it
    TwoTasksButton _zoom;
    TextButton[]   _textButtons;
    Label          _fps;
    MutFilename    _currentFilename;

public:
    this()
    {
        super(new Geom(0, 0, gui.screenXlg, gui.panelYlg, From.BOTTOM));
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
        immutable id = langToButtonIndex(buttonID);
        _buttons[id].xf = langToButtonXf(buttonID);
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
            ? _buttons[langToButtonIndex(id)]
            : _textButtons[id - Lang.editorButtonMenuConstants];
    }

    @property buttonZoom() inout { return _zoom; }
    @property buttonFraming() inout {
        return button(Lang.editorButtonSelectFrame);
    }
    @property buttonSelectAdd() inout {
        return button(Lang.editorButtonSelectAdd);
    }

    void forceClearInfo() { _info.text = ""; }
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
        return gui.screenXlg * 6f/7f;
    }

    void makeInfo()
    {
        _info = new TextButton(new Geom(0, 0, infoXl(), 20));
        _info.alignLeft = true;
        _fps  = new Label(new Geom(4 + xlg - _info.xlg,
                                   0, 100, 20, From.TOP_RIGHT));
        addChildren(_info, _fps);
    }

    int langToButtonXf(Lang l) const { return l - Lang.editorButtonFileNew; }
    int langToButtonIndex(Lang lang) const
    {
        assert (lang >= Lang.editorButtonFileNew);
        return lang - Lang.editorButtonFileNew
                    // DTODOUNDO: undo isn't implemented yet, otherwise rm this
                    - (lang >= Lang.editorButtonUndo ? 2 : 0);
    }
    Lang indexToLang(int id) const
    {
        return to!Lang(id + Lang.editorButtonFileNew + (id
            >= Lang.editorButtonUndo - Lang.editorButtonFileNew ? 2 : 0));
    }

    void makeButtons()
    {
        immutable int bitmaps = Lang.editorButtonAddHazard
                              - Lang.editorButtonFileNew + 1
                              - 2; // because no undo or redo yet
        immutable int texts = 4;
        immutable bitmapXl = infoXl * 2f / bitmaps;
        immutable bitmapYl = (gui.panelYlg - _info.ylg) / 2;
        immutable textXl = gui.screenXlg - infoXl();
        immutable textYl = gui.panelYlg / texts;
        const cutbit = fileImageEditPanel.getInternal;

        Geom newGeomForButton(int i)
        {
            if (langToButtonIndex(Lang.editorButtonAddTerrain) == i)
                return new Geom(i/2*bitmapXl, _info.ylg + i%2*bitmapYl,
                                bitmapXl, 2 * bitmapYl);
            if (langToButtonIndex(Lang.editorButtonAddDeco) == i)
                // massive hack, put outside of screen, but make valid geom
                return new Geom(9999, 9999, 20, 20);
            if (langToButtonIndex(Lang.editorButtonAddTerrain) < i
                && langToButtonIndex(Lang.editorButtonAddDeco) > i)
                ++i;
            return new Geom(i/2*bitmapXl, _info.ylg + i%2*bitmapYl,
                            bitmapXl, bitmapYl);
        }

        foreach (int i; 0 .. bitmaps) {
            auto g = newGeomForButton(i);
            if (langToButtonIndex(Lang.editorButtonViewZoom) == i) {
                _zoom = new TwoTasksButton(g, cutbit);
                _zoom.xf = langToButtonXf(Lang.editorButtonViewZoom);
                _buttons ~= _zoom;
            }
            else {
                _buttons ~= new BitmapButton(g, cutbit);
                _buttons[$-1].xf = -1;
            }
            addChild(_buttons[$-1]);
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
        if (basics.user.showFPS.value) {
            _fps.text = "FPS: %d".format(displayFps);
            // Prevent the text to smear over old text
            _info.reqDraw();
            // Stop the text from flickering, because it's not a child of _info
            _fps.reqDraw();
        }
    }

    void writeButtonTooltips()
    {
        foreach (int id, bb; _buttons)
            if (bb.isMouseHere) {
                try _info.text = indexToLang(id).transl;
                catch (ConvException) { }
                if (indexToLang(id) == Lang.editorButtonFileSave
                    && _currentFilename !is null
                ) {
                    _info.text = "%s %s".format(_info.text,
                                        _currentFilename.rootless);
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
