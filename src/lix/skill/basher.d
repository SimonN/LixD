module lix.skill.basher;

import std.algorithm; // min, max

import lix;
import game.mask;
import game.physdraw;
import game.terchang;
import hardware.sound;

class Basher : PerformedActivity {

    enum halfPixelsToFall = 9;
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

    override UpdateOrder updateOrder() const { return UpdateOrder.remover; }

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
        tc.x = ex - masks[tc.type].offsetX;
        tc.y = ey - masks[tc.type].offsetY;
        outsideWorld.physicsDrawer.add(tc);
        if (wouldHitSteel(masks[tc.type])) {
            playSound(Sound.STEEL);
            steelWasHit = true;
            // do not cancel the basher yet, this will happen later
        }
    }

    void continueOrStop()
    {
        if (steelWasHit) {
            turn();
            become(Ac.walker);
        }
        else if (nothingMoreToBash(0))
            become(Ac.walker);
    }

    void stopIfMovedDownTooFar()
    {
        immutable stepSize = () {
            assert (halfPixelsMovedDown < halfPixelsToFall);
            for (int y; 2*y < halfPixelsToFall - halfPixelsMovedDown; ++y)
                if (lixxie.isSolid(0, 2 + y))
                    return y;
            return -1;
        }();
        if (stepSize >= 0) {
            moveDown(stepSize);
            halfPixelsMovedDown += 2 * stepSize;
            assert (halfPixelsMovedDown < halfPixelsToFall);
            if (halfPixelsMovedDown > 0)
                --halfPixelsMovedDown;
        }
        else {
            // was 3 in C++ Lix, but the walker uses 2, so we do that, too
            enum fallUpTo = 2;
            int y = 0;
            while (! isSolid(0, 2 + y) && y < fallUpTo)
                ++y;
            if (isSolid(0, 2 + y)) {
                moveDown(y);
                become(Ac.walker);
            }
            else
                Faller.becomeAndFallPixels(lixxie, y);
        }
    }

}
// end class Basher
