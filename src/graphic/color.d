module graphic.color;

import basics.alleg5;

Color color;

void initialize()   { color = new Color(); }
void deinitialize() { clear(color); color = null; }

class Color {

    AlCol bad;
    AlCol transp;
    AlCol pink;

    AlCol shadow;
    AlCol white;
    AlCol red;

private:

    this() {
        //             red   green blue  alpha
        bad    = AlCol(0.00, 0.00, 0.00, 0.5);
        transp = AlCol(0.00, 0.00, 0.00, 0  );
        pink   = AlCol(1,    0,    1,    1  );
        white  = AlCol(1,    1,    1,    1  );
        shadow = AlCol(0.5,  0.4,  0.25, 1  );
        red    = AlCol(1,    0,    0,    1  );
    }
    ~this() { }

}
