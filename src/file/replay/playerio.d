module file.replay.playerio;

/*
 * Player and handicap serialization to/from text files.
 * See net.handicap for serialization to/from binary network packages.
 */

import std.algorithm;
import std.conv;
import std.string;

import enumap;

static import basics.globals;
import file.io;
import net.handicap;
import net.plnr;
import net.profile;
import net.style;

package:

/*
 * Usage:
 * 1. Feed us as many IoLines in here as you want. You should feed all
 *      "+"-lines from the replay. We'll discard all others.
 * 2. Call loseOwnershipOfProfileArray() and assign it where you want.
 * 3. Let the parser object go out of scope.
 */
struct ProfileImporter {
private:
    Profile[PlNr] ret;

public:
    void parse(in ref IoLine i)
    {
        if (i.text1 != basics.globals.replayPlayer
            && i.text1 != basics.globals.replayFriend
            && i.text1 != basics.globals.replaySingleHandi
        ) {
            return;
        }
        immutable plnr = PlNr(i.nr1 & 0xFF);
        touch(plnr);
        // For back-compat, we accept the FRIEND directive, even though
        // since March 2018, we only write PLAYER directives.
        if (i.text1 == basics.globals.replayPlayer
            || i.text1 == basics.globals.replayFriend
        ) {
            addNameAndStyleTo(ret[plnr], i);
        }
        else {
            addHandicapTo(ret[plnr].handicap, i);
        }
    }

    Profile[PlNr] loseOwnershipOfProfileArray()
    {
        auto temp = ret;
        ret = null;
        return temp;
    }

private:
    void touch(in PlNr plnr)
    {
        const p = plnr in ret;
        if (p is null) {
            ret[plnr] = Profile();
        }
    }

    static void addNameAndStyleTo(ref Profile p, in ref IoLine i)
    {
        p.style = stringToStyle(i.text2);
        p.name = i.text3;
    }

    static void addHandicapTo(ref Handicap h, in ref IoLine i)
    {
        foreach (key, word; handiKeywords.byKeyValue) {
            if (word == i.text2) {
                addHandicapTo(h, key, i.text3);
                return;
            }
        }
    }

    static void addHandicapTo(ref Handicap h, in HandiKey key, in string val)
    {
        try final switch (key) {
            case HandiKey.initialLix:
                h.initialLix = val.stringToFrac;
                break;
            case HandiKey.initialSkills:
                h.initialSkills = val.stringToFrac;
                break;
            case HandiKey.delayInPhyus:
                h.delayInPhyus = val.to!short;
                break;
            case HandiKey.score:
                h.score = val.stringToFrac;
                break;
        }
        catch (Exception) {}
    }
}

/*
 * We own only a reference to somebody else's Profile[PlNr].
 * We expect other code not to modify that Profile[PlNr] while we iterate.
 */
struct ProfileExporter {
private:
    const(Profile[PlNr]) _source;
    SingleProfileExporter _single;

public:
    this(const(Profile[PlNr]) src) pure nothrow @safe @nogc
    {
        _source = src;
        if (_source.length == 0) {
            assert (empty);
            return;
        }
        immutable PlNr minpl = _source.byKey.fold!min(_source.byKey.front);
        _single = SingleProfileExporter(minpl, *(minpl in _source));
    }

    bool empty() const pure nothrow @safe @nogc { return _single.empty; }
    IoLine front() const { return _single.front; }

    void popFront() @nogc
    {
        _single.popFront;
        if (! _single.empty) {
            return;
        }
        PlNr next = _single.plnr; // Find next-bigger after _single.plnr.
        foreach (PlNr i; _source.byKey) {
            if (i > _single.plnr && (next == _single.plnr || i < next)) {
                next = i;
            }
        }
        if (next != _single.plnr) {
            _single = SingleProfileExporter(next, *(next in _source));
            assert (! _single.empty && ! empty);
        }
    }
}

private:

struct SingleProfileExporter {
private:
    Profile _source;
    PlNr _plnr;
    bool _empty = true; // To be overwritten with false in non-default ctor.
    bool _wrotePlayerLine = false;
    HandiKey _nextKey = HandiKey.initialLix;

public:
    this(in PlNr plnr, in Profile prof) pure nothrow @safe @nogc
    {
        _plnr = plnr;
        _source = prof;
        _empty = false;
    }

    PlNr plnr() const pure nothrow @safe @nogc { return _plnr; }
    bool empty() const pure nothrow @safe @nogc { return _empty; }

    IoLine front() const
    {
        assert (! empty);
        if (! _wrotePlayerLine) {
            return IoLine.Plus(basics.globals.replayPlayer, _plnr,
                styleToString(_source.style), _source.name);
        }
        IoLine ret = IoLine.Plus(basics.globals.replaySingleHandi, _plnr,
            handiKeywords[_nextKey], "");
        final switch (_nextKey) {
            case HandiKey.initialLix:
                ret.text3 = _source.handicap.initialLix.fracToString;
                break;
            case HandiKey.initialSkills:
                ret.text3 = _source.handicap.initialSkills.fracToString;
                break;
            case HandiKey.delayInPhyus:
                ret.text3 = _source.handicap.delayInPhyus.to!string;
                break;
            case HandiKey.score:
                ret.text3 = _source.handicap.score.fracToString;
                break;
        }
        return ret;
    }

    void popFront() @nogc
    {
        if (! _wrotePlayerLine) {
            _wrotePlayerLine = true;
            if (_source.handicap.initialLix != Fraction.init)
                return;
        }
        if (_nextKey == HandiKey.initialLix) {
            _nextKey = HandiKey.initialSkills;
            if (_source.handicap.initialSkills != Fraction.init)
                return;
        }
        if (_nextKey == HandiKey.initialSkills) {
            _nextKey = HandiKey.delayInPhyus;
            if (_source.handicap.delayInPhyus != short.init)
                return;
        }
        if (_nextKey == HandiKey.delayInPhyus) {
            _nextKey = HandiKey.score;
            if (_source.handicap.score != Fraction.init)
                return;
        }
        if (_nextKey == HandiKey.score) {
            _empty = true;
        }
    }
}

enum HandiKey {
    initialLix,
    initialSkills,
    delayInPhyus,
    score,
}

immutable Enumap!(HandiKey, string) handiKeywords = enumap.enumap(
    HandiKey.initialLix, "LixInHatch",
    HandiKey.initialSkills, "SkillsInPanel",
    HandiKey.delayInPhyus, "SpawnDelayInPhyus",
    HandiKey.score, "Score");

string fracToString(in Fraction frac)
{
    return "%d/%d".format(frac.numerator, frac.denominator);
}

Fraction stringToFrac(in string s) pure nothrow @safe
{
    try {
        immutable slash = s.countUntil('/');
        alias Num = typeof(Fraction.numerator());
        if (slash < 0) {
            return Fraction(s[].strip.to!Num, 1);
        }
        // Slash found. Parse two ints.
        return Fraction(s[0 .. slash].strip.to!Num,
                        s[slash + 1 .. $].strip.to!Num);
    }
    catch (Exception) {
        return Fraction.init;
    }
}

unittest {
    assert (stringToFrac("12/34") == Fraction(12, 34));
    assert (stringToFrac("  12 /  35   ") == Fraction(12, 35));
    assert (stringToFrac("-2/-3") == Fraction(2, 3));
    assert (stringToFrac("5/-3") == Fraction(-5, 3));
    assert (stringToFrac("5") == Fraction(5, 1));
    assert (stringToFrac("Rubbish") == Fraction.init);
    assert (stringToFrac("Rubbish/More Rubbish") == Fraction.init);
    assert (stringToFrac("3/Rubbish") == Fraction.init);
}

version (unittest) {
    Profile unittestGuy()
    {
        Profile p;
        p.name = "TestGuy";
        p.style = Style.orange;
        p.handicap.initialLix = Fraction(2, 3);
        p.handicap.delayInPhyus = 10*15;
        return p;
    }

    Profile unittestLady()
    {
        Profile p;
        p.name = "TestLady";
        p.style = Style.red;
        p.handicap.initialSkills = Fraction(5, 6);
        p.handicap.score = Fraction(1, 2);
        return p;
    }
}

unittest {
    Profile tg = unittestGuy();
    assert (SingleProfileExporter(PlNr(3), tg)
        .map!(line => line.toString)
        .equal(["+PLAYER 3 Orange TestGuy",
            "+HANDICAP 3 LixInHatch 2/3",
            "+HANDICAP 3 SpawnDelayInPhyus 150"]));
    tg.handicap = Handicap.init;
    assert (SingleProfileExporter(PlNr(7), tg)
        .map!(line => line.toString)
        .equal(["+PLAYER 7 Orange TestGuy"]));
}

unittest {
    Profile[PlNr] arr;
    assert (ProfileExporter(arr).empty);
    arr[PlNr(2)] = unittestLady();
    arr[PlNr(0)] = unittestGuy();
    assert (ProfileExporter(arr)
        .map!(line => line.toString)
        .equal(["+PLAYER 0 Orange TestGuy",
            "+HANDICAP 0 LixInHatch 2/3",
            "+HANDICAP 0 SpawnDelayInPhyus 150",
            "+PLAYER 2 Red TestLady",
            "+HANDICAP 2 SkillsInPanel 5/6",
            "+HANDICAP 2 Score 1/2"]));
    ProfileImporter importer;
    foreach (ioLine; ProfileExporter(arr)) {
        importer.parse(ioLine);
    }
    Profile[PlNr] copied = importer.loseOwnershipOfProfileArray();
    assert (copied == arr);
    assert (ProfileExporter(copied).map!(line => line.toString)
        .equal(ProfileExporter(arr).map!(line => line.toString)));
}
