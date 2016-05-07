module gui.options;

/* Wrapping a GUI element with a label. These are used in the options dialogue
 * and in the editor windows.
 *
 * Subclasses of Option: Wraps the GUI elements through which an option is set,
 * and points to the value T that is used by the game and written to file.
 *
 * Important! Geom must be the first argument of any constructor of a subclass
 * of Option. Otherwise, OptionFactory will choke on that type.
 *
 * OptionFactory: computes the geom, incrementing the y position after each
 * factory(), and otherwise passes arguments to the Option subclass
 * constructors.
 */

import std.algorithm;
import std.conv;
import std.range; // takeOne
import std.string; // strip

static import basics.user;    // for LanguageOption
static import basics.globals; // for LanguageOption
import file.filename;  // for LanguageOption
import file.io;        // for LanguageOption
import file.language;  // for LanguageOption
import file.search;    // for LanguageOption
import graphic.internal;
import gui;
import gui.picker;
import hardware.keyset;
import hardware.mouse; // allow clicks on label
import lix.enums;

enum spaceGuiTextX =  10f;
enum mostButtonsXl = 120f;
enum keyButtonXl   =  70f;

abstract class Option : Element {
private:
    Label _desc; // may be null

public:
    this(Geom g, Label d = null)
    {
        super(g);
        _desc = d;
        if (_desc)
            addChild(_desc);
    }

    abstract void loadValue();
    abstract void saveValue(); // can't be const
}

struct OptionFactory {
    float x, y, xl, yl = 20f;
    float incrementY   = 30f;
    Geom.From from     = From.TOP_LEFT;

    Option factory(T, Args...)(Args argsToForward)
    {
        auto ret = new T(new Geom(x, y, xl, yl, from), argsToForward);
        y += incrementY;
        return ret;
    }
}



class BoolOption : Option {
private:
    Checkbox _checkbox;
    bool*    _target;
    bool     _execute;

public:
    this(Geom g, string cap, bool* t)
    {
        // t may be null, you may not call load/saveValue then
        _checkbox = new Checkbox(new Geom(0, 0, 20, 20));
        super(g, new Label(new Geom(30, 0, g.xlg - 30, g.yl), cap));
        addChild(_checkbox);
        _target = t;
    }

    @property bool checked() const { return _checkbox.checked;     }
    @property bool checked(bool b) { return _checkbox.checked = b; }
    @property bool execute() const { return _execute;              }

    override void loadValue()
    {
        assert (_target);
        _checkbox.checked = *_target;
    }

    override void saveValue()
    {
        assert (_target);
        *_target = _checkbox.checked;
    }

protected:
    override void calcSelf()
    {
        _execute = _checkbox.execute;
        // Allow clicks on the label, not only on the tiny checkbox.
        if (isMouseHere) {
            _checkbox.down = mouseHeldLeft > 0;
            if (mouseReleaseLeft && ! _checkbox.execute) {
                _checkbox.toggle();
                _execute = true;
            }
        }
    }
}



class TextOption : Option {
private:
    Texttype _texttype;
    string*  _target;

public:
    this(Geom g, string cap, string* t)
    {
        assert (t);
        _texttype = new Texttype(new Geom(0, 0, mostButtonsXl, 20));
        super(g, new Label(new Geom(mostButtonsXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + spaceGuiTextX, g.yl),
                            cap));
        addChild(_texttype);
        _target = t;
    }

    override void loadValue() { _texttype.text = *_target; }
    override void saveValue() { *_target = _texttype.text.strip; }

    // hack, to enable immediate check of nonempty
    @property inout(Texttype) texttype() inout { return _texttype; }
}



class HotkeyOption : Option {
private:
    KeyButton _keyb;
    KeySet*   _target;

public:
    this(Geom g, string cap, KeySet* t)
    {
        assert (t);
        _keyb = new KeyButton(new Geom(0, 0, keyButtonXl, 20));
        super(g, new Label(new Geom(keyButtonXl + spaceGuiTextX, 0,
                            g.xlg - keyButtonXl + spaceGuiTextX, g.yl), cap));
        addChild(_keyb);
        _target = t;
    }

    override void loadValue() { _keyb.keySet = *_target; }
    override void saveValue() { *_target = _keyb.keySet; }
}

class SkillHotkeyOption : Option
{
    private CutbitElement _cb;
    private KeyButton _keyb;
    private KeySet* _target;

    this(Geom g, Ac ac, KeySet* t)
    {
        super(g);
        assert (t);
        _keyb = new KeyButton(new Geom(0, 0, xlg, 20, From.BOTTOM));
        _cb   = new CutbitElement(new Geom(0, 0, xlg, ylg-20, From.TOP),
                                  Style.garden.getSkillButtonIcon);
        _cb.xf = ac;
        addChildren(_cb, _keyb);
        _target = t;
    }

    override void loadValue() { _keyb.keySet = *_target; }
    override void saveValue() { *_target = _keyb.keySet; }
}



class NumPickOption : Option
{
    private NumPick _num;
    private int*    _target;

    // hack, to enable immediate updates of the GUI menu colors
    public @property inout(NumPick) num() inout { return _num; }

    this(Geom g, NumPickConfig cfg, string cap, int* t)
    {
        assert (t);
        // Hack: sixButtons is used in the editor's view options window.
        // That NumPick selects colors. We hardcode that use case's xlg
        // here, and hope that nobody else needs to supply custom xlg.
        immutable plusXl = cfg.sixButtons ? 40 : 0;

        _num = new NumPick(new Geom(0, 0, mostButtonsXl + plusXl, 20), cfg);
        super(g, new Label(new Geom(mostButtonsXl + plusXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + plusXl + spaceGuiTextX,
                            g.yl), cap));
        addChild(_num);
        _target = t;
    }

    @property int  value()   const { return _num.number;     }
    @property bool execute() const { return _num.execute;    }
    override  void loadValue()     { _num.number = *_target; }
    override  void saveValue()     { *_target = _num.number; }
}



// ############################################################################
// ############################################################################
// ############################################################################



alias ResolutionOption = ManyNumbersOption!2;

class ManyNumbersOption (int fields) : Option
    if (fields >= 1) {

private:

    Texttype[fields] _texttype;
    int*    [fields] _target;

public:

    this(Geom g, string cap, int*[fields] targets...)
    {
        super(g, new Label(new Geom(mostButtonsXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + spaceGuiTextX, g.yl),
                            cap));
        foreach (i; 0 .. fields) {
            _texttype[i] = new Texttype(new Geom(
                i * mostButtonsXl/fields, 0, mostButtonsXl/fields, 20));
            _texttype[i].allowedChars = Texttype.AllowedChars.digits;
            addChild(_texttype[i]);
            _target[i] = targets[i];
        }
    }

    override void loadValue()
    {
        foreach (i; 0 .. fields)
            _texttype[i].text = to!string(*_target[i]);
    }

    override void saveValue()
    {
        foreach (i; 0 .. fields)
            *_target[i] = _texttype[i].number;
    }
}



// ############################################################################
// ############################################################################
// ############################################################################



class LanguageOption : Option {
private:
    Picker _picker;
    MutFilename _lastChosen;

public:
    this(Geom g, string cap)
    {
        super(g, new Label(new Geom(mostButtonsXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + spaceGuiTextX, 20), cap));
        auto cfg  = PickerConfig!LanguageTiler();
        cfg.all   = new Geom(0, 0, mostButtonsXl, this.ylg);
        cfg.bread = new Geom(-9999, -9999, 10, 10); // hack: offscreen
        cfg.files = new Geom(cfg.all);
        cfg.ls    = new AlphabeticalLs;
        _picker   = new Picker(cfg);
        _picker.basedir = basics.globals.dirDataTransl;
        addChild(_picker);
    }

    override void loadValue()
    {
        _lastChosen = basics.user.fileLanguage;
        _picker.navigateToAndHighlightFile(_lastChosen,
                                           CenterOnHighlitFile.always);
    }

    override void saveValue()
    {
        if (_lastChosen !is null && _lastChosen != basics.user.fileLanguage) {
            basics.user.fileLanguage = _lastChosen;
            loadUserLanguageAndIfNotExistSetUserOptionToEnglish();
        }
    }

protected:
    override void calcSelf()
    {
        if (_picker.executeFile) {
            _lastChosen = _picker.executeFileFilename;
            _picker.highlightFile(_picker.executeFileID,
                                  CenterOnHighlitFile.onlyIfOffscreen);
        }
    }

    static class LanguageTiler : LevelOrReplayTiler {
    public:
        this(Geom g) { super(g); }

    protected:
        final override TextButton newFileButton(Filename fn, in int fileID)
        {
            assert (fn);
            auto ret = new TextButton(new Geom(0, 0, xlg, buttonYlg));
            ret.text = fn.file;
            immutable key = Lang.mainNameOfLanguage.to!string;
            fillVectorFromFileNothrow(fn)
                .filter!(ioLine => ioLine.text1 == key)
                .takeOne.each!(ioLine => ret.text = ioLine.text2);
            return ret;
        }
    }
}
