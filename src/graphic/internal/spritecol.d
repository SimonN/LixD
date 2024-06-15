module graphic.internal.spritecol;

import enumap;

import basics.matrix;
import graphic.cutbit;
import graphic.internal.recol;
import net.style;

struct SpritesheetCollection {
private:
    Cutbit _unrecolored; // Not GUI-recolored, not style-recolored
    Enumap!(Style, Cutbit) _recol; // All null initially. Lazy generation.
    Matrix!Point _eyes; // Null initially until we lazily cache the eyes.
    RecolFunc _recolFunc;

public:
    alias RecolFunc = Cutbit function(Cutbit src, in Style targetStyle);

    this(Cutbit cb, RecolFunc func) // Takes ownership of the cutbit.
    {
        _unrecolored = cb;
        _recolFunc = func;
    }

    ~this() { dispose(); }

    bool isValid() const pure nothrow @safe @nogc
    {
        return _unrecolored.valid;
    }

    void dispose()
    out {
        assert (! isValid);
        assert (_recol[Style.garden] is null);
    }
    do {
        if (_unrecolored !is null) {
            _unrecolored.dispose();
            _unrecolored = null;
        }
        foreach (Style st, ref Cutbit cb; _recol) {
            if (cb !is null) {
                cb.dispose();
                cb = null;
            }
        }
        _eyes = null;
    }

    const(Cutbit) get(in Style st)
    in { assert (isValid); }
    out (ret) { assert (ret.valid); }
    do {
        if (_recol[st] !is null) {
            return _recol[st];
        }
        _recol[st] = _recolFunc(_unrecolored, st);
        return _recol[st];
    }

    const(Cutbit) getUnrecolored()
    in { assert (isValid); }
    do { return _unrecolored; }

    /*
     * Where does a right-facing lix have the eye depicted on frame (xf, yf)?
     */
    Point eyesForFrame(in int xf, in int yf)
    in { assert (isValid); }
    do {
        if (_eyes is null) {
            _eyes = lockThenFindEyes(_unrecolored);
        }
        return _eyes.get(xf, yf);
    }
}
