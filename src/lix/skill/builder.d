module lix.skill.builder;

import lix;
import game.physdraw;
import game.terchang;
import hardware.sound;

// base class for Builder and Platformer
abstract class BrickCounter : Job {

    int skillsQueued;
    int bricksLeft;

    enum bricksAtStart = 12;

    int startFrame() const { return 0; }

    alias lixxie this;
    alias copyFromAndBindToLix = super.copyFromAndBindToLix;
    protected void copyFromAndBindToLix(in BrickCounter rhs, Lixxie bindToLix)
    {
        super.copyFromAndBindToLix(rhs, bindToLix);
        skillsQueued = rhs.skillsQueued;
        bricksLeft   = rhs.bricksLeft;
    }

    override PhyuOrder updateOrder() const { return PhyuOrder.adder; }

    override @property bool callBecomeAfterAssignment() const
    {
        return lixxie.ac != this.ac;
    }

    override void onManualAssignment()
    {
        if (lixxie.ac == this.ac) {
            // skillsQueued = ... would be a mistake. The new job (this) is
            // discarded. We want to give the extra skills to the old job.
            BrickCounter oldAc = cast (BrickCounter) lixxie.job;
            assert (oldAc);
            oldAc.skillsQueued = oldAc.skillsQueued + 1;
        }
    }

    override void onBecome()
    {
        bricksLeft = bricksAtStart;
        frame = startFrame();
    }

    override void onBecomingSomethingElse()
    {
        outsideWorld.tribe.returnSkills(this.ac, skillsQueued);
        skillsQueued = 0;
    }

    final void buildBrick()
    {
        assert (bricksLeft > 0);
        --bricksLeft;
        if (bricksLeft < 3 && skillsQueued == 0)
            playSound(Sound.BRICK);
        onBuildingBrick();
    }

    // override this to draw on terrain
    void onBuildingBrick() { }

    final bool maybeBecomeShrugger(Ac shruggingAc)
    {
        assert (bricksLeft   >= 0);
        assert (skillsQueued >= 0);

        if (bricksLeft > 0) {
            return false;
        }
        else if (skillsQueued > 0) {
            --skillsQueued;
            bricksLeft += bricksAtStart;
            return false;
        }
        else {
            become(shruggingAc);
            return true;
        }
    }

}
// end class BrickCounter



// ############################################################################
// ############################################################################
// ############################################################################



class Builder : BrickCounter {

    bool fullyInsideTerrain;

    override int startFrame() const { return 6; }

    mixin(CloneByCopyFrom!"Builder");
    protected void copyFromAndBindToLix(in Builder rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        fullyInsideTerrain = rhs.fullyInsideTerrain;
    }

    override void perform()
    {
        advanceFrame();

        if (frame == 0) {
            maybeBecomeShrugger(Ac.shrugger);
        }
        else if (frame == 8) {
            buildBrick();
            moveUp(2);
        }
        else if (frame == 12) {
            bumpAgainstTerrain();
        }
        else if (frame == 13 || frame == 14) {
            moveAhead();
        }
    }

    override void onBuildingBrick()
    {
        // don't glitch up through steel, but still get killed by top of
        // screen: first see whether trapped, then make brick.
        // If we are fully inside terrain, we'll move down later.
        fullyInsideTerrain = solidWallHeight(0, 2) > Walker.highestStepUp;

        TerrainAddition tc;
        tc.update = outsideWorld.state.update;
        tc.type   = TerrainAddition.Type.build;
        tc.style  = style;
        tc.x      = facingRight ? ex : ex - 10;
        tc.y      = ey;
        outsideWorld.physicsDrawer.add(tc);
    }

    private void bumpAgainstTerrain()
    {
        // The lix has already moved up and the image has its
        // feet below the regular position, inside the newly placed brick.
        //
        //   XX - the effective coordinate of the checking Lixxie. She has
        //        already moved up from inside the brick, but not yet
        //        walked forward.
        //   WW - checked for wallNearFoot
        //   TT - checked for insideThinHorizontalBeam
        //   WT - checked for both wallNearFoot and insideThinHorizontalBeam
        //
        //               WW  WW
        //
        //           XX
        //           TT  WT  WT
        //           ()()()()()()()()()()()()
        //           ()()()()()()()()()()()()
        //   [][][][][][][][][][][][]
        //   [][][][][][][][][][][][]

        // For wallNearFoot, we check at height +1 and too at height -2.
        // Why also at height -2? We want to allow building staircases on
        // top of existing staircases.
        // Why then at height +1 at all? We want to build up and connect to
        // a thin horizontal beam. To stop at that beam, we have do check
        // separately for insideThinHorizontalBeam.
        immutable bool wallNearFoot
            =  (isSolid(4, 1) && isSolid(4, -2))
            || (isSolid(2, 1) && isSolid(2, -2));
        // Height +1 is the coordinate above the brick, not height 0, because:
        // In rare cases, e.g. lix inside thin horizontal beam, the lix
        // wouldn't build up high enough to make the staircase
        // connect with the beam.
        immutable bool insideThinHorizontalBeam
            = isSolid(4, 1) && isSolid(2, 1) && isSolid(0, 1);
        // The check for hitHead is not shown in the ASCII art comment above.
        immutable bool hitHead = isSolid(4, -16);
        if (wallNearFoot || insideThinHorizontalBeam || hitHead) {
            turn();
            if (fullyInsideTerrain)
                moveDown(2);
            become(Ac.walker);
        }
    }
}
// end class Builder



// ############################################################################
// ############################################################################
// ############################################################################



class Platformer : BrickCounter {

    mixin(CloneByCopyFrom!"Platformer");

    enum standingUpFrame = 9;

    override int startFrame() const
    {
        if (lixxie.ac == Ac.shrugger2 && lixxie.frame < standingUpFrame)
            // continue platforming on same height, don't increase by 2
            return 16;
        else
            return 0;
    }

    override void perform()
    {
        enum loopBackToFrame = 10;
        bool loopCompleted = false;

        if (isLastFrame) {
            assert (frame == 25, "fix the switch below if you alter frames");
            frame = loopBackToFrame;
            loopCompleted = true;
        }
        else
            advanceFrame();

        // Platforming starts with (loobBackToFrame)-many frames 0, 1, ...
        // that then merge into the looping 16 frames. In the first set of
        // frames, one brick is built, and it is higher than the floor height.
        if (frame == 2)
            buildBrick();
        else if (frame == 5)
            planNextBrickFirstCycle();
        else if (frame == 7) {
            moveUpAndCollide();
            moveAheadAndCollide();
        }
        else if (frame == 8)
            moveAheadAndCollide();

        // Looping 16 frames: build brick at floor height, not above
        else if (frame == loopBackToFrame) {
            if (loopCompleted && ! maybeBecomeShrugger(Ac.shrugger2))
                planNextBrickSubsequentCycles();
        }
        else if (frame == 18)
            buildBrick();
        else if (frame >= 22 && frame < 25) // 22, 23, 24
            moveAheadAndCollide();
    }

    // this is called from the following private functions, and also
    // from Walker.become
    void abortAndStandUp()
    {
        become(Ac.shrugger2);
        assert (lixxie.job.ac == Ac.shrugger2);
        lixxie.job.frame = standingUpFrame;
    }

    override void onBuildingBrick()
    {
        immutable bool firstCycle = (frame == 2);

        TerrainAddition tc;
        tc.update = outsideWorld.state.update;
        tc.type   = firstCycle ? TerrainAddition.Type.platformLong
                               : TerrainAddition.Type.platformShort;
        tc.style  = style;
        tc.y      = firstCycle ? ey : ey + 2;
        tc.x      = firstCycle ? (facingRight ? ex     : ex - 6)
                               : (facingRight ? ex + 4 : ex - 8);
        outsideWorld.physicsDrawer.add(tc);
    }

    private bool platformerTreatsAsSolid(in int x, in int y)
    {
        // If the pixel is solid, return false nontheless if there is free air
        // over the pixel. Strange code from C++ Lix, this had a loop that
        // checked the exact same set of pixels 3 times.
        if (! isSolid(x, y))
            return false;
        if (isSolid(x + 2, y) && isSolid(x + 4, y))
            return true;
        assert (isSolid(x, y));
        return isSolid(x+2, y-2)
            || isSolid(x,   y-2)
            || isSolid(x-2, y-2);
    }

    private void planNextBrickFirstCycle()
    {
        // Plan ahead next brick lyaed in frame 18. Don't turn on collision.
        // Use -1 instead of -2 to pass through very thin horizontal gaps
        // above the floor.
        if (    platformerTreatsAsSolid( 6, -1)
             && platformerTreatsAsSolid( 8, -1)
             && platformerTreatsAsSolid(10, -1)
        )
            become(Ac.walker);
    }

    private void moveUpAndCollide()
    {
        immutable airAbove = ! isSolid(0, -1);
        if (airAbove)
            moveUp(2);
        else
            abortAndStandUp();
    }

    private void moveAheadAndCollide()
    {
        if (! platformerTreatsAsSolid(2, 1))
            moveAhead();
        else
            abortAndStandUp();
    }

    private void planNextBrickSubsequentCycles()
    {
        assert (this is lixxie.job);
        if (   platformerTreatsAsSolid(2, 1)
            && platformerTreatsAsSolid(4, 1)
            && platformerTreatsAsSolid(6, 1)
        )
            abortAndStandUp();
    }
}



class Shrugger : Job {
    mixin(CloneByCopyFrom!"Shrugger");
    override void perform()
    {
        if (isLastFrame) become(Ac.walker);
        else             advanceFrame();
    }
}
