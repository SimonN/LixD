import std.math; // fmod
import std.conv; // convert double to int

import alleg5;
import help; // positive_mod

class Torbit {

private:

    AlBit bitmap;

    int  xl;
    int  yl;
    bool torus_x;
    bool torus_y;

public:

    this(int xl, int yl, bool tx = false, bool ty = false);
    this(const Torbit rhs);

    bool  is_broken() const { return ! bitmap; }
    AlBit get_albit()       { return bitmap; }

    int  get_xl()       const { return xl; }
    int  get_yl()       const { return yl; }
    bool get_torus_x () const { return torus_x; }
    bool get_torus_y () const { return torus_y; }

    void set_torus_x (bool b = true)  { torus_x = b; }
    void set_torus_y (bool b = true)  { torus_y = b; }
    void set_torus_xy(bool x, bool y) { set_torus_x(x); set_torus_y(y); }

    void draw_from(AlBit, int x = 0, int y = 0,
                   bool mirr = false, double rot = 0, double scal = 0) {}

    void copy_to_screen() {}

/*
D-Quiz. Was heißt innerhalb einer Klasse: const int* f();</message>
Antwort erwartet &quot;das ist eine Methode, die...&quot;</message>
Eine Methode, die einen const Pointer auf int zurückgibt?</message>
Nein, das wäre const(int*) f();</message>
Ah, also nur ein Pointer auf const int.</message>
Nein, das wäre const(int)* f();</message>
Hmmm</message>
Ein Funktionspointer ist es ja wohl nicht, das wäre mit dem function keyword oder delegate zu lösen.</message>
Das const ohne Klammern macht, was in C++ immer hinter die Signatur geschrieben wird, dass es also auch an const this aufgerufen werden kann.</message>
ah</message>
In D kann man es auch dahinter schreiben, und das ist auch empfohlen wegen Klarheit :)</message>
*/


}
