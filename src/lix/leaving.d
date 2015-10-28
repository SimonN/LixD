module lix.leaving;

import lix;

class Splatter : PerformedActivity { }
class Burner   : PerformedActivity { }
class Drowner  : PerformedActivity { }
class Exiter   : PerformedActivity { }

// code moved out of lix.faller
/+
                    l.play_sound(ua, Sound::SPLAT);

                    // Nicht explodieren lassen, das täte er bei 76 :-)
                    if (l.get_updates_since_bomb() == 75
                        || ua.st.tribes.size() <= 1 // singleplayer
                    ) {
                        l.set_updates_since_bomb(0);
                    }
+/

// play the correct sounds in onBecome
/+
    acFunc[Ac.SPLATTER]  .soundBecome = Sound.SPLAT;
    acFunc[Ac.BURNER]    .soundBecome = Sound.FIRE;
    acFunc[Ac.DROWNER]   .soundBecome = Sound.WATER;
+/

// override methods appropriately
/+
    acFunc[Ac.SPLATTER]  .leaving =
    acFunc[Ac.BURNER]    .leaving =
    acFunc[Ac.DROWNER]   .leaving =
    acFunc[Ac.EXITER]    .leaving = true
+/
