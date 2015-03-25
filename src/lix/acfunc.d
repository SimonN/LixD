module lix.acfunc;

import lix.enums;
import lix.lixxie;
import hardware.sound;

struct AcFunc {
    bool  pass_top;
    bool  leaving;
    bool  blockable;

    Sound sound_assign;
    Sound sound_become;

    void function(Lixxie) assclk;
    void function(Lixxie) become;
    void function(Lixxie, in UpdateArgs) update;
}

AcFunc[Ac] ac_func;
