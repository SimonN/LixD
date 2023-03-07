module gui.option.derived;

import std.algorithm;
import std.conv;
import std.string; // strip

import file.language;
import file.option;
import graphic.internal;
import gui;
import gui.option;
import hardware.keyset;
import hardware.mouse; // allow clicks on label

class BoolOption : Option {
private:
    Checkbox _checkbox;
    UserOption!bool _userOption;
    bool     _execute;

public:
    this(Geom g, UserOption!bool opt)
    {
        assert (opt !is null);
        _userOption = opt;
        this(g, opt.lang);
    }

    this(Geom g, Lang cap)
    {
        g.yl = 20f;
        // Hack use of this class: I use it in Editor's skill window.
        // opt will be null there, you may not call load/saveValue then.
        _checkbox = new Checkbox(new Geom(0, 0, 20, 20));
        super(g, new Label(new Geom(30, 0, g.xlg - 30, g.yl), cap.transl));
        addChild(_checkbox);
    }

    pure nothrow @safe @nogc {
        bool isChecked() const { return _checkbox.isChecked; }
        void checked(bool b) { _checkbox.checked = b; }
        bool execute() const { return _execute; }
    }

    override void loadValue()
    {
        assert (_userOption);
        _checkbox.checked = _userOption.value;
    }

    override void saveValue()
    {
        assert (_userOption);
        _userOption = _checkbox.isChecked;
    }

    override Lang lang() const { return _userOption.lang; }

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
    UserOption!string _userOption;
    Lang _cap;

public:
    this(Geom g, UserOption!string opt)
    {
        assert (opt);
        _texttype = new Texttype(new Geom(0, 0, mostButtonsXl, 20));
        super(g, new Label(new Geom(mostButtonsXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + spaceGuiTextX, g.yl),
                            opt.lang.transl));
        addChild(_texttype);
        _userOption = opt;
    }

    override void loadValue() { _texttype.text = _userOption.value; }
    override void saveValue() { _userOption = _texttype.text.strip; }
    override Lang lang() const { return _userOption.lang; }

    // hack, to enable immediate check of nonempty
    inout(Texttype) texttype() inout { return _texttype; }
}



private void registerAtWatcher(KeyDuplicationWatcher watcher, KeyButton button)
{
    if (watcher is null || button is null)
        return;
    watcher.watch(button);
    button.onChange = () { watcher.checkForDuplicateBindings(); };
}

class HotkeyOption : Option {
private:
    MultiKeyButton _keyb;
    UserOption!KeySet _userOption;

public:
    // watcher may be null, then we won't register ourselves with any watcher
    this(Geom g, UserOption!KeySet opt, KeyDuplicationWatcher watcher = null)
    {
        assert (opt);
        _keyb = new MultiKeyButton(new Geom(0, 0, keyButtonXl, 20));
        super(g, new Label(new Geom(keyButtonXl + spaceGuiTextX, 0,
                            g.xlg - keyButtonXl + spaceGuiTextX, g.yl),
                            opt.lang.transl));
        addChild(_keyb);
        _userOption = opt;
        registerAtWatcher(watcher, _keyb);
    }

    override void loadValue() { _keyb.keySet = _userOption.value; }
    override void saveValue() { _userOption = _keyb.keySet; }
    override Lang lang() const { return _userOption.lang; }
}

class SkillHotkeyOption : Option
{
    private SkillIcon _cb;
    private MultiKeyButton _keyb;
    private UserOption!KeySet _userOption;

    // watcher may be null, then we won't register ourselves with any watcher
    this(Geom g, Ac ac, UserOption!KeySet opt, KeyDuplicationWatcher watcher)
    {
        super(g);
        assert (opt);
        enum kbYl = 35;
        _keyb = new MultiKeyButton(new Geom(0, 0, xlg, kbYl, From.BOTTOM));
        _cb   = new SkillIcon(new Geom(0, 0, xlg, ylg - kbYl, From.TOP));
        _cb.ac = ac;
        addChildren(_cb, _keyb);
        _userOption = opt;
        registerAtWatcher(watcher, _keyb);
    }

    override Lang lang() const { return Lang.commonOk; } // hack
    override void loadValue() { _keyb.keySet = _userOption.value; }
    override void saveValue() { _userOption = _keyb.keySet; }
}



class NumPickOption : Option
{
    private NumPick _num;
    private UserOption!int _userOption;

    // hack, to enable immediate updates of the GUI menu colors
    public inout(NumPick) num() inout { return _num; }

    this(Geom g, NumPickConfig cfg, UserOption!int opt)
    {
        assert (opt);
        // Hack: sixButtons is used in the editor's view options window.
        // That NumPick selects colors. We hardcode that use case's xlg
        // here, and hope that nobody else needs to supply custom xlg.
        immutable plusXl = cfg.sixButtons ? 40 : 0;
        _num = new NumPick(new Geom(0, 0, mostButtonsXl + plusXl, 20), cfg);
        super(g, new Label(new Geom(mostButtonsXl + plusXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + plusXl + spaceGuiTextX,
                            g.yl), opt.lang.transl));
        addChild(_num);
        _userOption = opt;
    }

    int value() const { return _num.number; }
    bool execute() const { return _num.execute; }
    override void loadValue() { _num.number = _userOption.value; }
    override void saveValue() { _userOption = _num.number; }
    override Lang lang() const { return _userOption.lang; }
}



class RadioIntOption : Option {
private:
    RadioButtons _radio;
    Lang[] _choiceLangs;
    UserOption!int _userOption;

public:
    this(Geom g, UserOption!int target, Lang[] choices...)
    in {
        assert (choices.length >= 1);
    }
    do {
        g.yl = 20f * choices.length;
        _radio = new RadioButtons(new Geom(0, 0, g.xl, g.yl));
        foreach (ch; choices) {
            _radio.addChoice(ch.transl);
            _choiceLangs ~= ch;
        }
        // super(..., null) means no label. The RadioButtons have labels.
        super(g, null);
        _userOption = target;
        addChild(_radio);
    }

    override void loadValue() { _radio.choose(_userOption.value); }
    override void saveValue() { _userOption = _radio.theChosen; }
    override Lang lang() const
    {
        immutable int hov = _radio.theHovered;
        if (hov >= 0 && hov < _choiceLangs.length) {
            return _choiceLangs[hov];
        }
        return _userOption.lang; // Ideally, we won't get here.
    }
}

class RadioBoolOption : Option {
private:
    RadioButtons _radio;
    Lang _choiceA;
    Lang _choiceB;
    bool _choiceAinFile; // If false, then "false" in file means: choice A.
    UserOption!bool _userOption; // Always choice A first, then choice B.

public:
    this(Geom g, UserOption!bool target,
        in Lang choiceA, in bool choiceAinFile,
        in Lang choiceB, in bool choiceBinFile)
    in {
        assert (choiceAinFile != choiceBinFile);
    }
    do {
        g.yl = 40f;
        _radio = new RadioButtons(new Geom(0, 0, g.xl, g.yl));
        _choiceA = choiceA;
        _choiceB = choiceB;
        _choiceAinFile = choiceAinFile;
        _radio.addChoice(_choiceA.transl);
        _radio.addChoice(_choiceB.transl);

        // super(..., null) means no label. The RadioButtons have labels.
        super(g, null);
        _userOption = target;
        addChild(_radio);
    }

    override void loadValue()
    {
        _radio.choose(_userOption.value == _choiceAinFile ? 0 : 1);
    }

    override void saveValue()
    {
        _userOption = (_radio.theChosen == 0
            ? _choiceAinFile : ! _choiceAinFile);
    }

    override Lang lang() const
    {
        immutable int hov = _radio.theHovered;
        return hov == 0 ? _choiceA : hov == 1 ? _choiceB : _userOption.lang;
    }
}



alias ResolutionOption = ManyNumbersOption!2;

class ManyNumbersOption (int fields) : Option
    if (fields >= 1) {

private:
    Texttype[fields] _texttype;
    UserOption!int[fields] _userOptions;

public:
    this(Geom g, UserOption!int[fields] targets...)
    {
        assert (targets[0]);
        super(g, new Label(new Geom(mostButtonsXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + spaceGuiTextX, g.yl),
                            targets[0].lang.transl));
        foreach (i; 0 .. fields) {
            _texttype[i] = new Texttype(new Geom(
                i * mostButtonsXl/fields, 0, mostButtonsXl/fields, 20));
            _texttype[i].allowedChars = Texttype.AllowedChars.digits;
            addChild(_texttype[i]);
            assert (targets[i] !is null);
            _userOptions[i] = targets[i];
        }
    }

    override void loadValue()
    {
        foreach (i; 0 .. fields)
            _texttype[i].text = to!string(_userOptions[i].value);
    }

    override void saveValue()
    {
        foreach (i; 0 .. fields)
            _userOptions[i] = _texttype[i].number;
    }

    override Lang lang() const { return _userOptions[0].lang; }
}
