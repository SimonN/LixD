module lix.acfunc;

import lix.enums;
import lix.lixxie;
//import graphic.sound;

class Sound {
    enum Id { A, B }
}

struct AcFunc {
    bool      pass_top;
    bool      leaving;
    bool      blockable;
    bool      aiming;

    Sound.Id sound_assign;
    Sound.Id sound_become;
    Sound.Id sound_aim;

    void function(Lixxie) assclk;
    void function(Lixxie) become;
    void function(Lixxie, const UpdateArgs) update;
}

AcFunc[Ac] ac_func;
