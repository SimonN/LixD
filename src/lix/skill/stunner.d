module lix.skill.stunner;

import hardware.sound;
import lix;

class Stunner : Job {
private:
    int stayedInFrame8;

public:
    mixin JobChild;

    override void onBecome(in Job old)
    {
        playSound(Sound.OUCH);
    }

    override void perform()
    {
        // remain in frame 8 for several frames, to match L2 stunner duration
        bool considerBecomingWalker = false;
        if (frame == 8) {
            ++stayedInFrame8;
            if (stayedInFrame8 == 17)
                advanceFrame();
        }
        else if (isLastFrame)
            considerBecomingWalker = true;
        else
            advanceFrame();

        enum hollowBelow = (in int y) => ! this.isSolid(0, 2 + y);
        enum maxDown = 4; // digger shall not cause eternal stunning

        int moveDownBy = 0;
        for (int y = 0; y < maxDown; ++y) {
            if (hollowBelow(y)) ++moveDownBy;
            else                break;
        }
        if (moveDownBy == maxDown && hollowBelow(moveDownBy)) {
            moveDown(1);
            become(Ac.tumbler);
            Tumbler tumbling = cast (Tumbler) lixxie.job;
            assert (tumbling !is null);
            tumbling.speedX = 0;
            tumbling.speedY = 2;
        }
        else if (moveDownBy > 0) {
            moveDown(moveDownBy);
        }

        if (this is lixxie.job && considerBecomingWalker)
            become(Ac.walker);
    }
}
