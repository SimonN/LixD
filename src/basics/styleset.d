module basics.styleset;

/*
 * A StyleSet is like an Enumap!(Style, bool), but it's implemented with
 * a bitset instead of a fixed-size array of bools.
 */

static import core.bitop;
import std.traits : EnumMembers;

public import net.style;

struct StyleSet {
pure nothrow @safe @nogc:
private:
    uint _field = 0;
    static immutable _returnValuesOfFront = [EnumMembers!Style];

public:
    bool empty() const { return _field == 0; }
    int  len() const { return core.bitop.popcnt(_field); }
    bool contains(in Style st) const { return (_field & (1 << st)) != 0; }

    void insert(in Style st) { _field |= (1 << st); }
    void clear() { _field = 0; }

    StyleSet opIndex() const pure nothrow @safe @nogc
    {
        return StyleSet(_field); // Mutable copy of this to allow popFront
    }

    Style front() const
    in { assert (! empty, "Range violation: front() on empty StyleSet"); }
    do { return _returnValuesOfFront[core.bitop.bsf(_field)]; }

    void popFront()
    in { assert (! empty, "Range violation: popFront() on empty StyleSet"); }
    do { _field &= ~(1 << front); }
}

static assert (Style.min >= 0, "Necessary for StyleSet's uint");
static assert (Style.max < 32, "Necessary for StyleSet's uint");

pure @safe @nogc unittest {
    import std.meta : aliasSeqOf;
    import std.range : iota;
    import std.traits : EnumMembers;
    static assert (EnumMembers!Style
        == aliasSeqOf!(EnumMembers!Style.length.iota));
}

pure @safe @nogc unittest {
    auto s = StyleSet();
    s.insert(Style.green);
    s.insert(Style.blue);
    s.insert(Style.red);

    int i = 0;
    foreach (Style element; s) {
        if (i == 0) assert (element == Style.red);
        if (i == 1) assert (element == Style.green);
        if (i == 2) assert (element == Style.blue);
        ++i;
    }
    assert (i == 3);
    assert (s.len == 3);
    assert (s.contains(Style.blue));
    assert (! s.contains(Style.purple));
}
