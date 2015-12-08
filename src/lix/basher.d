module lix.basher;

import std.algorithm; // min, max

import lix;
import game.mask;
import game.physdraw;
import game.terchang;
import hardware.sound;

class Basher : PerformedActivity {

    int  halfPixelsMovedDown; // per pixel down: += 2; per frame passed: -= 1;
    bool omitRelics;
    bool steelWasHit;

    mixin(CloneByCopyFrom!"Basher");
    protected void copyFromAndBindToLix(in Basher rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        halfPixelsMovedDown = rhs.halfPixelsMovedDown;
        omitRelics  = rhs.omitRelics;
        steelWasHit = rhs.steelWasHit;
    }

    override void onBecome()
    {
        // September 2015: start faster to make the basher slightly stronger
        frame = 2;
    }

    override void performActivity()
    {
        advanceFrame();

        switch (frame) {
            case  1: checkOmitRelics(); break;
            case  7: performSwing();    break;
            case 10: continueOrStop();  break;
            case 11: ..
            case 15: moveAhead();       break; // "..15" is inclusive! 5 cases!
            default: break;
        }
        stopIfMovedDownTooFar();
    }



private:

    bool nothingMoreToBash(in int whereX)
    {
        // whereX: use 0 if you want the normal check.
        // Use 10 if you want to check whether there will be nothing to bash
        // after going ahead by 10 pixels.
        assert (whereX == 0 || whereX == 10);

        // We don't check the pixels that would be in the upcoming basher
        // swing, but so far away that they will still be ahead of the lix
        // after a full basher's walk-ahead cycle. These pixels will be
        // checked after that next basher's walk cycle.
        // Checking everything would be a rectangle of 14, -16, 23, +1.
        if (countSolid(14 + whereX, -14, 21 + whereX, -3) < 15) {
            // Check for very thin walls
            for (int x = 14 + whereX; x <= 21 + whereX; x += 2)
                if (isSolid(x, -12))
                    return false;
            // No thin walls, but too few pixels altogether to continue
            return true;
        }
        return false;
    }

    void checkOmitRelics()
    {
        omitRelics
            = countSolid(14, -16, 15, 1) == 0 // nothing behind the relics
            && nothingMoreToBash(0); // 0, because we'll check to become
                                     // walker from current position, too
    }

    void performSwing()
    {
        TerrainChange tc;
        tc.update = outsideWorld.state.update;

        if (omitRelics) {
            if (dir > 0) tc.type = TerrainChange.Type.bashNoRelicsRight;
            else         tc.type = TerrainChange.Type.bashNoRelicsLeft;
        }
        else {
            if (dir > 0) tc.type = TerrainChange.Type.bashRight;
            else         tc.type = TerrainChange.Type.bashLeft;
        }
        tc.x      = ex - masks[tc.type].offsetX;
        tc.y      = ey - masks[tc.type].offsetY;
        outsideWorld.physicsDrawer.add(tc);

        if (steelWasHit)
            playSound(Sound.STEEL);
            // do not cancel the basher yet, this will happen later
    }

    void continueOrStop()
    {
        if (steelWasHit) {
            turn();
            become(Ac.WALKER);
        }
        else if (nothingMoreToBash(0)) {
            become(Ac.WALKER);
        }
    }

    void stopIfMovedDownTooFar()
    {
        enum fallAt = 9;

        // How many pixels have we descended? 9 pixels or more => fall.
        // The pixels inside the foot must be air, too. Otherwise, a basher can
        // fall in the tip of his tunnel, but the walkers following would not.
        int movedDownByThisFrame = 0;
        while (! isSolid() && ! isSolid(0, 1) && ! isSolid(0, 0)
            && halfPixelsMovedDown < fallAt
        ) {
            moveDown(1);
            movedDownByThisFrame += 1;
            halfPixelsMovedDown  += 2;
        }
        // Get up again to counter the Horus bug, but never go up further than
        // the basher started initially.
        while (halfPixelsMovedDown > 0 && isSolid() && isSolid(0, 1)) {
            moveUp(1);
            movedDownByThisFrame -= 1;
            halfPixelsMovedDown = max(0, halfPixelsMovedDown - 2);
        }

        // Lix too high? Then become faller, otherwise set lower movedDownBy.
        if (halfPixelsMovedDown >= fallAt) {
            moveUp(1);
            movedDownByThisFrame -= 1;
            become(Ac.FALLER);
            Faller faller = cast (Faller) performedActivity;
            if (faller)
                faller.pixelsFallen = movedDownByThisFrame;
        }
        else {
            halfPixelsMovedDown = max(0, halfPixelsMovedDown - 1);
        }
    }
    // end stopIfMovedDownTooFar

}
// end class Basher
