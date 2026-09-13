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

import std.algorithm;

import basics.alleg5; // timerTicks
import basics.globals; // ticksForDoubleClick
import file.language; // Hotkey names
import graphic.color;
import gui;
import hardware.keyboard;
import file.key.set;
import hardware.mouse;

// a Watched Key Button
interface WatchedKB {
    void registerWatcher(WatcherOfKB);
    const(KeySet) keySet() const pure nothrow @safe @nogc;

    // Watcher calls this to tell us that we should re-ask him about dupes.
    void rememberToAskWatcher() pure nothrow @safe @nogc;
}

// the Watcher of Key Buttons
interface WatcherOfKB {
    bool areDuplicatesKnownFor(in WatchedKB) const pure nothrow @safe @nogc;
    void scanForDuplicates();
}

class SingleKeyButton : TextButton {
private:
    KeySet _keySet;
    void delegate() _onChange;
    bool _hasRedText;

public:
    this(Geom g, void delegate() cb)
    in { assert (cb !is null); }
    do {
        _onChange = cb;
        super(g);
    }

    const(KeySet) keySet() const pure nothrow @safe @nogc { return _keySet; }
    const(KeySet) keySet(in KeySet sc)
    {
        if (sc == _keySet)
            return sc;
        _keySet = sc;
        formatScancode();
        _onChange();
        return sc;
    }

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

    mixin (GetSetWithReqDraw!"hasRedText");

protected:
    override void calcSelf()
    {
        super.calcSelf();
        if (! on) {
            on = execute;
            return;
        }
        auto tappedKey = hardware.keyboard.whatExactlyWasTapped;
        if (mouseClickLeft) {
            // Only LMB cancels. Esc, RMB, MMB, ... are assignable hotkeys.
            on = false;
        }
        else if (tappedKey.isValid) {
            keySet = KeySet(tappedKey);
            on = false;
        }
        formatScancode();
    }

    override Alcol colorText() const nothrow @safe @nogc
    {
        return _hasRedText ? color.guiTextWarning : super.colorText;
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

class MultiKeyButton : Element, WatchedKB {
private:
    SingleKeyButton _big;
    TextButton _plus;
    TextButton _minus;
    KeySet _addTheseToBig; // Saves _big's keys when we click _plus

    WatcherOfKB[] _dupeWatchers;

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
            _big = new SingleKeyButton(new Geom(0, 0, xlg, ylg),
                () { scanForDuplicates(); });
            immutable pYlg = ylg - 20f;
            immutable pY = ylg - pYlg;
            _plus = new DarkTextButton(new Geom(xlg/2, pY, xlg/2, pYlg), "+");
            _minus = new DarkTextButton(new Geom(0, pY, xlg/2, pYlg) ,"\u2212");
        }
        else {
            enum pXlg = 15f;
            _big = new SingleKeyButton(new Geom(0, 0, xlg, ylg, From.RIGHT),
                () { scanForDuplicates(); });
            _plus = new DarkTextButton(new Geom(pXlg, 0, pXlg, ylg), "+");
            _minus = new DarkTextButton(new Geom(0, 0, pXlg, ylg), "\u2212");
        }
        addChildren(_big, _minus, _plus);
    }

    const(KeySet) keySet() const { return _big.keySet; }
    const(KeySet) keySet(in KeySet set)
    {
        if (_big.keySet == set)
            return set;
        _big.keySet = set; // calls back into formatThreeButtons().
        return set;
    }

    final void registerWatcher(WatcherOfKB w)
    in {
        assert (! _dupeWatchers.canFind(w), "Don't register w twice.");
    }
    do {
        _dupeWatchers ~= w;
        // We assume that w already watches us. No need to call w.watch(this).
    }

    void rememberToAskWatcher() pure nothrow @safe @nogc
    {
        reqDraw();
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
            scanForDuplicates();
        }
        if (_minus.execute) {
            keySet = keySet.butWithOneKeyFewer;
            scanForDuplicates();
        }
        if (_plus.execute) {
            _addTheseToBig = _big.keySet;
            _plus.on = true;
            _big.on = true;
        }
    }

    override void drawSelf()
    {
        formatThreeButtons();
    }

private:
    void scanForDuplicates()
    {
        foreach (w; _dupeWatchers) {
            w.scanForDuplicates();
        }
    }

    void formatThreeButtons()
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
        _big.hasRedText = _dupeWatchers.any!(w
            => w.areDuplicatesKnownFor(this));
    }
}
