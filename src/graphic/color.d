module graphic.color;

import basics.alleg5;

Color color;

class Color {

    AlCol bad;
    AlCol transp;
    AlCol red;

    void initialize()   { color = new Color(); }
    void deinitialize() { clear(color); color = null; }

private:

    this() {
        //             red   green blue  alpha
        bad    = AlCol(0.00, 0.00, 0.00, 0.5);
        transp = AlCol(0.00, 0.00, 0.00,   0);
        red    = AlCol(1,    0,    0,    1  );
    }
    ~this() { }

}
