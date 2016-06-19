module gui.button.key;

/* class KeyButton:
 * You can assign several keys to this. If you click it, it will wait for a
 * hotkey assignment via keyboard or mouse, but then erase everything on it.
 * Multiple keys can only be assigned via this.keySet.
 *
 * class MultiKeyButton:
 * This has a KeyButton as a component, and will manage its multiple keys.
 * If you click the KeyButton component, you replace all of its keys with one
 * key, as described for KeyButton above. Click the '+' button to add extras.
 */

import basics.alleg5; // timerTicks
import basics.globals; // ticksForDoubleClick
import gui;
import hardware.keyboard;
import hardware.keyset;
import hardware.mouse;

class KeyButton : TextButton {
private:
    KeySet _keySet;
    void delegate() _onKeyTapped; // called on new assignment, not on cancel

public:
    this(Geom g) { super(g); }

    @property const(KeySet) keySet() const { return _keySet; }
    @property const(KeySet) keySet(in KeySet sc)
    {
        if (sc == _keySet)
            return sc;
        _keySet = KeySet(sc);
        formatScancode();
        return sc;
    }

    @property void onKeyTapped(void delegate() f) { _onKeyTapped = f; }

    @property override bool on() const { return super.on(); }
    @property override bool on(in bool b)
    {
        if (b == on)
            return b;
        super.on(b);
        if (b) addFocus(this);
        else    rmFocus(this);
        return b;
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
                if (_onKeyTapped !is null)
                    _onKeyTapped();
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

class MultiKeyButton : Element {
private:
    KeyButton _big;
    TextButton _plus;
    TextButton _minus;
    KeySet _addTheseToBig; // Saves _big's keys when we click _plus

    enum plusXlg = 15f;

public:
    this(Geom g)
    {
        super(g);
        _big = new KeyButton(new Geom(0, 0, xlg, ylg, From.RIGHT));
        _big.onKeyTapped = () { this.formatButtons(); };
        _plus = new TextButton(new Geom(plusXlg, 0, plusXlg, ylg),
            "+");
        _minus = new TextButton(new Geom(0, 0, plusXlg, ylg),
            "\u2212");
        addChildren(_big, _plus, _minus);
        keySet = KeySet();
    }

    @property const(KeySet) keySet() const { return _big.keySet; }
    @property const(KeySet) keySet(in KeySet set)
    {
        _big.keySet = set;
        formatButtons();
        return set;
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
    void formatButtons()
    {
        _plus.hidden = keySet.empty || keySet.len >= 3;
        _minus.hidden = keySet.empty;
        _big.resize(_minus.hidden ? xlg : _plus.hidden ? xlg - plusXlg :
            xlg - 2f * plusXlg, ylg);
    }
}
