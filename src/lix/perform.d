module lix.perform;

import hardware.sound;
import lix.enums;
import lix.lixxie;

// call this from Lixxie.perform(OutsideWorld*)
package void performActivityUseGadgets(Lixxie l)
{
    l.addEncountersFromHere();

    l.performedActivity.performActivity();

    l.killOutOfBounds();
    l.useWater();
    l.useNonconstantTraps();
    l.useFlingers();
    l.useTrampos();
    l.useGoals();
}

private:

void useGoals           (Lixxie l) { }
void useWater           (Lixxie l) { /* and fire */ }
void useNonconstantTraps(Lixxie l) { }
void useFlingers        (Lixxie l) { }
void useTrampos         (Lixxie l) { }

void killOutOfBounds(Lixxie l) { with (l)
{
    if (! healthy)
        return;
    const phymap = outsideWorld.state.lookup;
    if (   ey >= phymap.yl + 23
        || ey >= phymap.yl + 15 && ac != Ac.floater
        || ex >= phymap.xl +  4
        || ex <= -4
    ) {
        playSound(Sound.OBLIVION);
        become(Ac.nothing);
    }
}}
