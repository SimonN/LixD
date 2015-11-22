module game.lookup;

/* A lookup table for quick land/steel detection and backwards correspondence
 * of playfield positions to interactive objects.
 *
 * Right now, this doesn't store pointers to objects. Thus, it can be checked
 * whether there is fire or water or steel at a given position, but it cannot
 * tell what exact interactive object instance sits there. If this behavior
 * is desired, the object in question must be looked up manually in the list
 * of objects of its type.
 */

import basics.alleg5;
import basics.help;
import file.filename;

class Lookup {

public:

    alias short LoNr; // this is exactly 2 bytes long

    static immutable LoNr bitTerrain    = 0x0001;
    static immutable LoNr bitSteel      = 0x0002;
    // bit_ow_left  = 0x0004;
    // bit_ow_right = 0x0008; -- Lix doesn't have one-way arrows

    static immutable LoNr bitGoal       = 0x0010;
    static immutable LoNr bitGoal_prox  = 0x0020;
    static immutable LoNr bitFire       = 0x0040;
    static immutable LoNr bitWater      = 0x0080;

    static immutable LoNr bitTrap       = 0x0100;
    static immutable LoNr bitFling      = 0x0200;
    static immutable LoNr bitTrampoline = 0x0400;

/*  this(in int _xl, in int _yl, in bool _tx = false, in bool _ty = false);
 *  this(in Lookup rhs);
 *
 *  invariant();
 *
 *  void resize(in int, in int, in bool, in bool);
 */
    @property int  xl()     const { return _xl; }
    @property int  yl()     const { return _yl; }
    @property bool torusX() const { return _tx; }
    @property bool torusY() const { return _ty; }

/*  LoNr get              (int, int)                 const;
 *  bool get              (int, int, LoNr)           const;
 *  int  getRectangle     (int, int, int, int, LoNr) const;
 *  bool getSolid         (int, int)                 const;
 *  bool getSolidEven     (int, int)                 const;
 *  bool getSteel         (int, int)                 const;
 *
 *  //                     x,   y,   xl,  yl,  bit &
 *  void rm               (int, int,           LoNr);
 *  void add              (int, int,           LoNr);
 *  void addRectangle     (int, int, int, int, LoNr);
 *  void setSolid         (int, int);
 *  void setSolidRectangle(int, int, int, int);
 *  void setAir           (int, int);
 *
 *  void saveToFile(in Filename) const;
 */

private:

    int _xl;
    int _yl;

    bool _tx;
    bool _ty;

    // "lt" == "lookup table", aligned as row, row, row, row, ...
    // I don't use the matrix class here, the code was already
    // written in C++ without it and works well
    LoNr[] lt;

    LoNr getAt(int x, int y) const   { return lt[y * _xl + x]; }
    void addAt(int x, int y, LoNr n) { lt[y * _xl + x] |= n;   }
    void rmAt (int x, int y, LoNr n) { lt[y * _xl + x] &= ~n;  }

/*  int  getRectangleAt(int, int, int, int, LoNr) const;
 *  void addRectangleAt(int, int, int, int, LoNr);
 *
 *  void amend(ref int x, ref int y) const;
 *
 *      Move coordinates onto nontorus, or modulo them on torus.
 *
 *  bool amendIfInside(ref int x, ref int y) const;
 *
 *      Is the given point on the map?
 *      This shall only be used in set/add functions, not in getters/readers.
 *      On tori, this is the same as amend, and it returns true.
 *      On non-tori, if pixel outide, returns false, otherwise true.
 */


public:

this(
    in int a_xl, in int a_yl, in bool a_tx = false, in bool a_ty = false
) {
    resize(a_xl, a_yl, a_tx, a_ty);
}



this(in Lookup rhs)
{
    assert (rhs !is null);

    _xl = rhs._xl;
    _yl = rhs._yl;
    _tx = rhs._tx;
    _ty = rhs._ty;
    lt  = rhs.lt.dup;
}



invariant()
{
    if (_xl > 0 || _yl > 0 || lt !is null) {
        assert (_xl > 0);
        assert (_yl > 0);
        assert (lt !is null);
        assert (lt.length == _xl * _yl);
    }
    else {
        assert (lt is null);
    }
}



void resize(in int a_xl, in int a_yl, in bool a_tx, in bool a_ty)
in {
    assert (a_xl > 0);
    assert (a_yl > 0);
}
body {
    _xl = a_xl;
    _yl = a_yl;
    _tx = a_tx;
    _ty = a_ty;
    lt = new LoNr[_xl * _yl];
}



// These two functions assume the input completely in valid range for speed.
private int getRectangleAt(int x, int y, int xr, int yr, LoNr n) const
{
    int count = 0;
    for  (int ix = x; ix < xr; ++ix)
     for (int iy = y; iy < yr; ++iy) if (getAt(ix, iy) & n) ++count;
    return count;
}



private void addRectangleAt(int x, int y, int xr, int yr, LoNr n)
{
    for  (int ix = x; ix < xr; ++ix)
     for (int iy = y; iy < yr; ++iy) addAt(ix, iy, n);
}



LoNr get(int x, int y) const
{
    amend(x, y);
    return getAt(x, y);
}



bool get(int x, int y, LoNr n) const
{
    amend(x, y);
    return (getAt(x, y) & n) != 0;
}



int getRectangle(int x, int y, int xr, int yr, LoNr n) const
{
    amend(x, y);
    const int xrr = x + xr <= _xl ? xr : _xl - x;
    const int yrr = y + yr <= _yl ? yr : _yl - y;
    int count =                   getRectangleAt(x, y, xrr,    yrr,   n);
    if (_tx && xr > xrr) count += getRectangleAt(0, y, xr-xrr, yrr,   n);
    if (_ty && yr > yrr) count += getRectangleAt(0, y, xrr,    yr-yrr,n);
    if (_tx && xr > xrr
     && _ty && yr > yrr) count += getRectangleAt(0, 0, xr-xrr, yr-yrr,n);
    return count;
}



bool getSolid(int x, int y) const
{
    amend(x, y);
    return (getAt(x, y) & bitTerrain) != 0;
}



bool getSolidEven(int x, int y) const
{
    amend(x, y);
    // x & ~1 makes numbers even by zeroing the last bit
    // x |  1 makes numbers odd
    return ( ( getAt(x &~ 1, y) | getAt(x | 1, y) ) & bitTerrain) != 0;
}



// int Lookup::getSolidRectEven(int, int, int, int) const;



bool getSteel(int x, int y) const
{
    amend(x, y);
    return (getAt(x, y) & bitSteel) != 0;
}



//    int  getSteelRectangle(int, int, int, int) const;



void rm(int x, int y, LoNr n)
{
    if (! amendIfInside(x, y)) return;
    rmAt(x, y, n);
}



void add(int x, int y, LoNr n)
{
    if (! amendIfInside(x, y)) return;
    addAt(x, y, n);
}



void addRectangle(int x, int y, int xr, int yr, LoNr n)
{
    for     (int ix = 0; ix < xr; ++ix)
        for (int iy = 0; iy < yr; ++iy)
            add(x + ix, y + iy, n);
}



void setSolid(int x, int y)
{
    if (! amendIfInside(x, y)) return;
    addAt(x, y, bitTerrain);
}



void setSolidRectangle(int x, int y, int xr, int yr)
{
    addRectangle(x, y, xr, yr, bitTerrain);
}



void setAir(int x, int y)
{
    if (! amendIfInside(x, y))  return;
    if (getAt(x, y) & bitSteel) return;
    rmAt(x, y, bitTerrain);
}



// for testing
public void saveToFile(in Filename fn) const
{
    Albit outputBitmap = albitMemoryCreate(_xl, _yl);
    scope (exit)
        al_destroy_bitmap(outputBitmap);
    auto drata = DrawingTarget(outputBitmap);

    foreach (y; 0 .. _yl) foreach (x; 0 .. _xl) {
        immutable int red   = get(x, y, bitTerrain);
        immutable int green = get(x, y, bitSteel);
        immutable int blue  = get(x, y, bitGoal | bitFire  | bitWater
                                      | bitTrap | bitFling | bitTrampoline);
        al_put_pixel(x, y, AlCol(red, blue, green, 1));
    }
    al_save_bitmap(fn.rootfulZ, outputBitmap);
}



private:

void amend(ref int x, ref int y) const
{
    x = _tx ? positiveMod(x, _xl)
      : x >= _xl ? _xl - 1
      : x <  0   ? 0 : x;
    y = _ty ? positiveMod(y, _yl)
      : y >= _yl ? _yl - 1
      : y <  0   ? 0 : y;
}



// Is the given point on the map?
bool amendIfInside(ref int x, ref int y) const
{
    if (! _tx && (x < 0 || x >= _xl)) return false;
    if (! _ty && (y < 0 || y >= _yl)) return false;
    amend(x, y);
    return true;
}

}
// end class
