module gui.button.key;

/* class SingleKeyButton:
 * You can assign several keys to this. If you click it, it will wait for a
 * hotkey assignment via keyboard or mouse, but then erase everything on it.
 * Multiple keys can only be assigned via this.keySet.
 *
 * class MultiKeyButton:
 * This has a SingleKeyButton as a component and manage its multiple keys.
 * If you click the SingleKeyButton component, you replace all of its keys with
 * one key, as described for KeyButton above. Click the '+' button to add
 * extras.
 */

import basics.alleg5; // timerTicks
import basics.globals; // ticksForDoubleClick
import file.language; // Hotkey names
import graphic.color;
import gui;
import hardware.keyboard;
import hardware.keyset;
import hardware.mouse;

interface KeyButton {
    void onChange(void delegate());
    bool warnAboutDuplicateBindings() const;
    bool warnAboutDuplicateBindings(in bool);
    const(KeySet) keySet() const;
    const(KeySet) keySet(in KeySet);
}

class SingleKeyButton : TextButton, KeyButton {
private:
    KeySet _keySet;
    void delegate() _onChange; // called on new assignment, not on cancel
    bool _warnAboutDuplicateBindings; // only set externally, we don't check

public:
    this(Geom g) { super(g); }

    mixin (GetSetWithReqDraw!"warnAboutDuplicateBindings");

    const(KeySet) keySet() const { return _keySet; }
    const(KeySet) keySet(in KeySet sc)
    {
        if (sc == _keySet)
            return sc;
        _keySet = KeySet(sc);
        formatScancode();
        return sc;
    }

    void onChange(void delegate() f) { _onChange = f; }

    override bool on() const pure nothrow @safe @nogc { return super.on(); }
    override bool on(in bool b) @safe nothrow
    {
        if (b == on)
            return b;
        super.on(b);
        if (b) addFocus(this);
        else    rmFocus(this);
        return b;
    }

    override Alcol colorText() const
    {
        return _warnAboutDuplicateBindings ? color.red : super.colorText();
    }

protected:
    override void calcSelf()
    {
        super.calcSelf();
        if (! on)
            on = execute;
        else {
            if (mouseClickLeft)
                // Only LMB cancels this. RMB and MMB are assignable hotkeys.
                on = false;
            else if (scancodeTapped) {
                _keySet = KeySet(scancodeTapped);
                on = false;
                if (_onChange !is null)
                    _onChange();
            }
            formatScancode();
        }
    }

private:
    void formatScancode()
    {
        reqDraw();
        text = (on && timerTicks % 30 < 15)
            ? "\ufffd" // replacement char, question mark in a box
            : _keySet.nameLong;
    }
}

// ############################################################################

class MultiKeyButton : Element, KeyButton {
private:
    SingleKeyButton _big;
    TextButton _plus;
    TextButton _minus;
    KeySet _addTheseToBig; // Saves _big's keys when we click _plus
    void delegate() _onChange;

    // Layout if _smallBelowBig == false: [-][+][big]
    //
    // Layout if _smallBelowBig == true:  [big ]
    //                                    [-][+]
    immutable bool _smallBelowBig = false;

public:
    this(Geom g)
    {
        super(g);
        _smallBelowBig = g.ylg >= 30f;

        if (_smallBelowBig) {
            _big = new SingleKeyButton(new Geom(0, 0, xlg, ylg));
            immutable pYlg = ylg - 20f;
            immutable pY = ylg - pYlg;
            _plus = new DarkTextButton(new Geom(xlg/2, pY, xlg/2, pYlg), "+");
            _minus = new DarkTextButton(new Geom(0, pY, xlg/2, pYlg) ,"\u2212");
        }
        else {
            enum pXlg = 15f;
            _big = new SingleKeyButton(new Geom(0, 0, xlg, ylg, From.RIGHT));
            _plus = new DarkTextButton(new Geom(pXlg, 0, pXlg, ylg), "+");
            _minus = new DarkTextButton(new Geom(0, 0, pXlg, ylg), "\u2212");
        }
        _big.onChange = () { this.formatButtonsAndCallCallback(); };
        assert (! this._onChange);
        addChildren(_big, _minus, _plus);

        formatButtonsAndCallCallback();
    }

    const(KeySet) keySet() const { return _big.keySet; }
    const(KeySet) keySet(in KeySet set)
    {
        if (_big.keySet == set)
            return set;
        _big.keySet = set;
        formatButtonsAndCallCallback();
        return set;
    }

    void onChange(void delegate() f) { _onChange = f; }

    bool warnAboutDuplicateBindings() const
    {
        return _big.warnAboutDuplicateBindings;
    }

    bool warnAboutDuplicateBindings(in bool b)
    {
        if (_big.warnAboutDuplicateBindings == b)
            return b;
        reqDraw();
        return _big.warnAboutDuplicateBindings = b;
    }

protected:
    override void calcSelf()
    {
        if (! _addTheseToBig.empty) {
            // Hack: We want _plus to be on until _big has seen a keypress.
            // Since _big takes focus, this.calcSelf() will only run after
            // _big loses focus. _plus.on = false here relies on this focus.
            _plus.on = false;
            keySet = KeySet(_big.keySet, _addTheseToBig);
            _addTheseToBig = KeySet();
        }
        if (_minus.execute) {
            assert (! keySet.empty);
            KeySet temp = keySet;
            temp.remove(temp.keysAsInts[$-1]);
            keySet = temp;
        }
        if (_plus.execute) {
            _addTheseToBig = _big.keySet;
            _plus.on = true;
            _big.on = true;
        }
    }

private:
    void formatButtonsAndCallCallback()
    {
        _minus.shown = keySet.len >= 1;
        _plus.shown = keySet.len >= 1 && keySet.len < 3;
        if (_smallBelowBig) {
            _minus.resize(_plus.shown ? xlg/2 : xlg, _minus.ylg);
            _big.resize(_big.xlg, _minus.shown || _plus.shown
                                    ? ylg - _minus.ylg : ylg);
        }
        else {
            _big.resize(xlg - _minus.xlg * (_minus.shown + _plus.shown), ylg);
        }
        if (_onChange !is null)
            _onChange();
    }
}
