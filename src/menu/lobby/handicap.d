module menu.lobby.handicap;

/*
 * This is the handicap screen, accessible from the lobby.
 *
 * This is _not_ the button that you can click to spawn the screen.
 * That button is in menu.lobby.topleft.
 *
 * In the parlance within this module:
 * A "single handicap" is:
 *      - either a multiplication and/or a division,
 *      - or a delay.
 * Any number of different single handicaps can be combined in a
 * single Handicap struct to an arbitrary handicap, which is then possibly
 * no handicap == Handicap.init when you combine zero single handicaps.
 */

import std.algorithm;
import std.range;
import std.string;

import basics.globals;
import file.language;
import gui;
import net.handicap;

string toUiTextAbbreviated(in Handicap handi) pure @safe
{
    return toUiText(
        ["L", handi.initialLix.toHandiUiText],
        ["\u27BF", handi.initialSkills.toHandiUiText], // Left mouse button
        ["◔ ", handi.delayInPhyus.toHandiUiText], // Looks like a clock
        ["◎", handi.score.toHandiUiText]); // Bullseye, a scoring target
}

string toUiTextLongAndHelpful(in Handicap handi) @safe
{
    string space(in Lang lang) @safe { return " " ~ lang.transl; }
    return toUiText(
        [handi.initialLix.toHandiUiText, space(Lang.handicapInitialLix)],
        [handi.initialSkills.toHandiUiText, space(Lang.handicapInitialSkills)],
        [handi.delayInPhyus.toHandiUiText, space(Lang.handicapSpawnDelay)],
        [handi.score.toHandiUiText, space(Lang.handicapScore)]);
}

class HandicapPicker : Window {
    OkayCancel _okayCancel;
    FractionPicker _initialLix;
    FractionPicker _initialSkills;
    DelayPicker _delay;
    FractionPicker _score;

public:
    this(in Handicap oldHandi)
    {
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg),
            Lang.handicapTitle.transl);
        addLabel(40, Lang.handicapPhilosophy1);
        addLabel(60, Lang.handicapPhilosophy2);
        addLabel(80, Lang.handicapPhilosophy3);

        _initialLix = add!FractionPicker(120,
            Lang.handicapInitialLix, Lang.handicapInitialLixNormal);
        _initialLix.choose(oldHandi.initialLix);
        _initialSkills = add!FractionPicker(180,
            Lang.handicapInitialSkills, Lang.handicapInitialSkillsNormal);
        _initialSkills.choose(oldHandi.initialSkills);
        _delay = add!DelayPicker(240,
            Lang.handicapSpawnDelay, Lang.handicapSpawnDelayNormal);
        _delay.choose(oldHandi.delayInPhyus);
        _score = add!FractionPicker(300,
            Lang.handicapScore, Lang.handicapScoreNormal);
        _score.choose(oldHandi.score);

        _okayCancel = new OkayCancel(new Geom(0, 20, 220, 20, From.BOTTOM));
        addChild(_okayCancel);
    }

    OkayCancel.ExitWith exitWith() const nothrow @nogc
    {
        return _okayCancel.exitWith;
    }

    Handicap chosenHandicap() const pure nothrow @safe @nogc
    {
        Handicap ret;
        ret.initialLix = _initialLix.chosenHandicap;
        ret.initialSkills = _initialSkills.chosenHandicap;
        ret.delayInPhyus = _delay.chosenHandicap;
        ret.score = _score.chosenHandicap;
        return ret;
    }

private:
    OHP add(OHP)(in float y, in Lang caption, in Lang noHandi)
    {
        addLabel(y, caption);
        auto ret = new OHP(
            new Geom(0, y + 20, xlg - 160, 20, From.TOP), noHandi);
        addChild(ret);
        return ret;
    }

    void addLabel(in float y, in Lang caption)
    {
        string text = caption.transl;
        if (caption.descr.length > 0) {
            text ~= ": " ~ caption.descr[0];
        }
        addChild(new Label(new Geom(0, y, xlg-40, 20, From.TOP), text));
    }
}

///////////////////////////////////////////////////////////////////////////////
private: //////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

string toUiText(string[][] pairsOfNameAndValue...) pure @safe
{
    return pairsOfNameAndValue[]
        .filter!(pair => !pair[0].empty && !pair[1].empty)
        .map!(pair => pair[0] ~ pair[1])
        .join(", ");
}

string toHandiUiText(in Fraction frac) pure @safe
{
    if (frac == Fraction.init) {
        return "";
    }
    if (frac.denominator == 1) {
        if (frac.numerator < 0) {
            return format!"\u2212%d"(frac.numerator); // unicode minus
        }
        return format!"%d"(frac.numerator);
    }
    return fractionToUnicode(frac.numerator, frac.denominator);
}

string fractionToUnicode(
    in int numerator,
    in int denominator
) pure @safe
in { assert (denominator >= 1, "no zero, and put minus into the numerator"); }
do {
    string expressWithTheseDigits(int n, ref immutable string[10] digits)
    in { assert (digits.length == 10); }
    do {
        if (n == 0) {
            return digits[0];
        }
        if (n < 0) {
            n *= -1;
        }
        string ret;
        while (n > 0) {
            ret = digits[n % 10] ~ ret;
            n /= 10;
        }
        return ret;
    }
    // These are all 2-byte or 3-byte in UTF-8: ⁰¹²³⁴⁵⁶⁷⁸⁹⁄₀₁₂₃₄₅₆₇₈₉
    alias Strs = immutable string[10];
    static Strs numStrs = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"];
    static Strs denStrs = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"];
    return (numerator < 0 ? "\u2212" : "")
        ~ expressWithTheseDigits(numerator, numStrs)
        ~ "⁄"
        ~ expressWithTheseDigits(denominator, denStrs);
}

unittest {
    assert (Fraction(15, 1).toHandiUiText == "15");
    assert (Fraction(1, 15).toHandiUiText == "¹⁄₁₅");
}

string toHandiUiText(in int delayInPhyus) pure @safe
{
    return delayInPhyus == 0 ? "" : format!"%d s"(
        (delayInPhyus + (phyusPerSecondAtNormalSpeed - 1))
        / phyusPerSecondAtNormalSpeed);
}

unittest {
    Handicap h;
    h.initialLix = Fraction(5, 6);
    h.delayInPhyus = 15 * phyusPerSecondAtNormalSpeed;
    assert (h.toUiTextAbbreviated.startsWith("L⁵⁄₆, "), h.toUiTextAbbreviated);
}

class HandiButton(Value) : TextButton
if (is (Value == struct)
    || is (Value == short)) // Delay isn't wrapped in a struct.
{
public:
    immutable Value value;

    this(Geom g, in Lang textForNoHandi) {
        super(g, textForNoHandi.transl);
        value = Value.init;
    }

    this(Geom g, in Value v) {
        super(g, v.toHandiUiText);
        value = v;
    }
}

class OneHandiPicker(Value) : Element {
private:
    HandiButton!Value[] _buttons; // Invariant: Exactly one will be on.

public:
    this(Geom g, HandiButton!Value[] buttonsThatWeWillOwn)
    in {
        assert (buttonsThatWeWillOwn.length >= 1);
        assert (buttonsThatWeWillOwn.all!(b => b !is null));
    }
    do {
        super(g);
        _buttons = buttonsThatWeWillOwn;
        foreach (b; _buttons) {
            addChild(b);
        }
        choose(Value.init);
    }

    Value chosenHandicap() const pure nothrow @safe @nogc
    {
        foreach (b; _buttons) {
            if (b.on) {
                return b.value;
            }
        }
        assert (false, "Invariant violated: One button is always selected");
    }

    final void choose(in Value wanted)
    {
        foreach (b; _buttons) {
            b.on = false;
        }
        foreach (b; _buttons) {
            if (b.value == wanted) {
                b.on = true;
                return;
            }
        }
        // None found. Maintain invariant that always one button be selected.
        _buttons[0].on = true;
    }

protected:
    override void calcSelf()
    {
        foreach (b; _buttons) {
            if (b.execute) {
                choose(b.value);
                return;
            }
        }
    }
}

Geom asRatioOf(
    in Geom parent,
    in float xAsRatioOfParent,
    in float xlgAsRatioOfParent,
) {
    return new Geom(
        parent.xlg * xAsRatioOfParent, 0,
        parent.xlg * xlgAsRatioOfParent, parent.ylg, From.LEFT);
}


class FractionPicker : OneHandiPicker!Fraction {
public:
    this(Geom g, in Lang noHandi) {
        super(g, [
            new HandiButton!Fraction(asRatioOf(g, 0, 3/div), noHandi),
            makeButton(g, 3, Fraction(19, 20)),
            makeButton(g, 4, Fraction(5, 6)),
            makeButton(g, 5, Fraction(2, 3)),
            makeButton(g, 6, Fraction(1, 2)),
            makeButton(g, 7, Fraction(1, 3)),
            makeButton(g, 8, Fraction(1, 5)),
            makeButton(g, 9, Fraction(1, 7)),
            makeButton(g, 10, Fraction(1, 10)),
        ]);
    }

private:
    static immutable float div = 11f;

    static HandiButton!Fraction makeButton(
        Geom ourOwn,
        in int nthButton,
        in Fraction frac,
    ) {
        return new HandiButton!Fraction(
            asRatioOf(ourOwn, nthButton/div, 1/div), frac);
    }
}

class DelayPicker : OneHandiPicker!short {
public:
    this(Geom g, in Lang noHandi) {
        immutable float div = 11f;
        super(g, [
            new HandiButton!short(asRatioOf(g, 0, 3/div), noHandi),
            makeButton(g, 3, 5),
            makeButton(g, 4, 10),
            makeButton(g, 5, 20),
            makeButton(g, 6, 30),
            makeButton(g, 7, 45),
            makeButton(g, 8, 60),
            makeButton(g, 9, 90),
            makeButton(g, 10, 120),
        ]);
    }

private:
    static immutable float div = 11f;

    static HandiButton!short makeButton(
        Geom ourOwn,
        in int nthButton,
        in short delayInSeconds,
    ) {
        immutable short delayInPhyus
            = 0x7FFF & (delayInSeconds * phyusPerSecondAtNormalSpeed);
        return new HandiButton!short(
            asRatioOf(ourOwn, nthButton/div, 1/div), delayInPhyus);
    }
}
