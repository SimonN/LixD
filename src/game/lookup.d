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

import basics.help;

class Lookup {

public:

    alias short LoNr; // this is exactly 2 bytes long

    static immutable LoNr bit_terrain    = 0x0001;
    static immutable LoNr bit_steel      = 0x0002;
    static immutable LoNr bit_ow_left    = 0x0004;
    static immutable LoNr bit_ow_right   = 0x0008;

    static immutable LoNr bit_goal       = 0x0010;
    static immutable LoNr bit_goal_prox  = 0x0020;
    static immutable LoNr bit_fire       = 0x0040;
    static immutable LoNr bit_water      = 0x0080;

    static immutable LoNr bit_trap       = 0x0100;
    static immutable LoNr bit_fling      = 0x0200;
    static immutable LoNr bit_trampoline = 0x0400;

    this(in int _xl, in int _yl, in bool _tx = false, in bool _ty = false);
    ~this() { }

    // invariant(); -- exists, see below

    void resize(in int, in int, in bool, in bool);

    int  get_xl()      const { return xl; }
    int  get_yl()      const { return yl; }
    bool get_torus_x() const { return torus_x; }
    bool get_torus_y() const { return torus_y; }

    LoNr get                (int, int)                 const;
    bool get                (int, int, LoNr)           const;
    int  get_rectangle      (int, int, int, int, LoNr) const;
    bool get_solid          (int, int)                 const;
    bool get_solid_even     (int, int)                 const;
    bool get_steel          (int, int)                 const;

    //                       x,   y,   xl,  yl,  bit &
    void rm                 (int, int,           LoNr);
    void add                (int, int,           LoNr);
    void add_rectangle      (int, int, int, int, LoNr);
    void set_solid          (int, int);
    void set_solid_rectangle(int, int, int, int);
    void set_air            (int, int);

private:

    int xl;
    int yl;

    bool torus_x;
    bool torus_y;

    // "lt" == "lookup table", aligned as row, row, row, row, ...
    // I don't use the matrix class here, the code was already
    // written in C++ without it and works well
    LoNr[] lt;

    LoNr get_at(int x, int y) const   { return lt[y * xl + x]; }
    void add_at(int x, int y, LoNr n) { lt[y * xl + x] |= n;   }
    void rm_at (int x, int y, LoNr n) { lt[y * xl + x] &= ~n;  }

    int  get_rectangle_at(int, int, int, int, LoNr) const;
    void add_rectangle_at(int, int, int, int, LoNr);

    // move coordinates onto nontorus, or modulo them on torus.
    void amend(ref int x, ref int y) const;

    // Is the given point on the map?
    // This shall only be used in set/add functions, not in getters/readers.
    // On tori, this is the same as amend, and it returns true.
    // On non-tori, if pixel outide, returns false, otherwise true.
    bool amend_if_inside(ref int x, ref int y) const;




public:

this(
    in int _xl, in int _yl, in bool _tx = false, in bool _ty = false
) {
    resize(_xl, _yl, _tx, _ty);
}



invariant()
{
    assert (lt !is null);
}



void resize(in int _xl, in int _yl, in bool _tx, in bool _ty)
in {
    assert (_xl > 0);
    assert (_yl > 0);
}
body {
    xl = _xl;
    yl = _yl;
    torus_x = _tx;
    torus_y = _ty;
    lt   = new LoNr[xl * yl];
    lt[] = 0;
}



// These two functions assume the input completely in valid range for speed.
private int get_rectangle_at(int x, int y, int xr, int yr, LoNr n) const
{
    int count = 0;
    for  (int ix = x; ix < xr; ++ix)
     for (int iy = y; iy < yr; ++iy) if (get_at(ix, iy) & n) ++count;
    return count;
}



private void add_rectangle_at(int x, int y, int xr, int yr, LoNr n)
{
    for  (int ix = x; ix < xr; ++ix)
     for (int iy = y; iy < yr; ++iy) add_at(ix, iy, n);
}



LoNr get(int x, int y) const
{
    amend(x, y);
    return get_at(x, y);
}



bool get(int x, int y, LoNr n) const
{
    amend(x, y);
    return (get_at(x, y) & n) != 0;
}



int get_rectangle(int x, int y, int xr, int yr, LoNr n) const
{
    amend(x, y);
    const int xrr = x + xr <= xl ? xr : xl - x;
    const int yrr = y + yr <= yl ? yr : yl - y;
    int count =                       get_rectangle_at(x, y, xrr,    yrr,   n);
    if (torus_x && xr > xrr) count += get_rectangle_at(0, y, xr-xrr, yrr,   n);
    if (torus_y && yr > yrr) count += get_rectangle_at(0, y, xrr,    yr-yrr,n);
    if (torus_x && xr > xrr
     && torus_y && yr > yrr) count += get_rectangle_at(0, 0, xr-xrr, yr-yrr,n);
    return count;
}



bool get_solid(int x, int y) const
{
    amend(x, y);
    return (get_at(x, y) & bit_terrain) != 0;
}



bool get_solid_even(int x, int y) const
{
    amend(x, y);
    // x & ~1 makes numbers even by zeroing the last bit
    // x |  1 makes numbers odd
    return ( ( get_at(x &~ 1, y) | get_at(x | 1, y) ) & bit_terrain) != 0;
}



// int Lookup::get_solid_rect_even(int, int, int, int) const;



bool get_steel(int x, int y) const
{
    amend(x, y);
    return (get_at(x, y) & bit_steel) != 0;
}



//    int  get_steel_rectangle(int, int, int, int) const;



void rm(int x, int y, LoNr n)
{
    if (! amend_if_inside(x, y)) return;
    rm_at(x, y, n);
}



void add(int x, int y, LoNr n)
{
    if (! amend_if_inside(x, y)) return;
    add_at(x, y, n);
}



void add_rectangle(int x, int y, int xr, int yr, LoNr n)
{
    for  (int ix = 0; ix < xr; ++ix)
     for (int iy = 0; iy < yr; ++iy) add(x + ix, y + iy, n);
}



void set_solid(int x, int y)
{
    if (! amend_if_inside(x, y)) return;
    add_at(x, y, bit_terrain);
}



void set_solid_rectangle(int x, int y, int xr, int yr)
{
    add_rectangle(x, y, xr, yr, bit_terrain);
}



void set_air(int x, int y)
{
    if (! amend_if_inside(x, y))  return;
    if (get_at(x, y) & bit_steel) return;
    rm_at(x, y, bit_terrain);
}



private:

void amend(ref int x, ref int y) const
{
    x = torus_x ? positive_mod(x, xl)
      : x >= xl ? xl - 1
      : x <  0  ? 0 : x;
    y = torus_y ? positive_mod(y, yl)
      : y >= yl ? yl - 1
      : y <  0  ? 0 : y;
}



// Is the given point on the map?
bool amend_if_inside(ref int x, ref int y) const
{
    if (! torus_x && (x < 0 || x >= xl)) return false;
    if (! torus_y && (y < 0 || y >= yl)) return false;
    amend(x, y);
    return true;
}

}
// end class
