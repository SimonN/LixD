module physics.job.stunner;

import hardware.sound;
import physics.job;
import tile.phymap;

class Stunner : Job {
private:
    int stayedInFrame8;

public:
    override void onBecome(in Job old)
    {
        /*
         * Fix github #448: Don't repeat "ouch" if stuck in permanent flinger.
         * Asking for ! lixxie.flingNew didn't fix this. Directly ask physics.
         */
        if ((lixxie.lookup.get(lixxie.foot) & Phybit.steam) == 0) {
            lixxie.playSound(Sound.OUCH);
        }
    }

    override void perform()
    {
        // remain in frame 8 for several frames, to match L2 stunner duration
        bool considerBecomingWalker = false;
        if (frame == 8) {
            ++stayedInFrame8;
            if (stayedInFrame8 == 17)
                lixxie.advanceFrame();
        }
        else if (lixxie.isLastFrame) {
            considerBecomingWalker = true;
        }
        else {
            lixxie.advanceFrame();
        }

        enum hollowBelow = (in int y) => ! lixxie.isSolid(0, 2 + y);
        enum maxDown = 4; // digger shall not cause eternal stunning

        int moveDownBy = 0;
        for (int y = 0; y < maxDown; ++y) {
            if (hollowBelow(y)) ++moveDownBy;
            else                break;
        }
        if (moveDownBy == maxDown && hollowBelow(moveDownBy)) {
            lixxie.moveDown(1);
            lixxie.become(Ac.tumbler);
            Tumbler tumbling = cast (Tumbler) lixxie.job;
            assert (tumbling !is null);
            tumbling.speedX = 0;
            tumbling.speedY = 2;
        }
        else if (moveDownBy > 0) {
            lixxie.moveDown(moveDownBy);
        }

        if (this is lixxie.job && considerBecomingWalker)
            lixxie.become(Ac.walker);
    }
}
