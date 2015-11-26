module lix.builder;

import lix;
import game.physdraw;
import hardware.sound;

class Builder : PerformedActivity {

    int skillsQueued;
    int bricksLeft;
    bool fullyInsideTerrain;

    enum bricksAtStart = 12;

    mixin(CloneByCopyFrom!"Builder");
    protected void copyFromAndBindToLix(in Builder rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        skillsQueued       = rhs.skillsQueued;
        bricksLeft         = rhs.bricksLeft;
        fullyInsideTerrain = rhs.fullyInsideTerrain;
    }

    override @property bool callBecomeAfterAssignment() const
    {
        return lixxie.ac != Ac.BUILDER;
    }

    override void onManualAssignment()
    {
        if (lixxie.ac == Ac.BUILDER)
            skillsQueued = skillsQueued + 1;
    }

    override void onBecome()
    {
        bricksLeft = bricksAtStart;
        frame = 6;
    }

    override void onBecomingSomethingElse()
    {
        outsideWorld.tribe.returnSkills(Ac.BUILDER, skillsQueued);
        skillsQueued = 0;
    }



    override void performActivity()
    {
        advanceFrame();

        if (frame == 0) {
            maybeBecomeShrugger();
        }
        else if (frame == 8) {
            buildBrick();
            moveUp();
        }
        else if (frame == 12) {
            bumpAgainstTerrain();
        }
        else if (frame == 13 || frame == 14) {
            moveAhead();
        }
    }



    private void buildBrick()
    {
        // don't glitch up through steel, but still get killed by top of
        // screen: first see whether trapped, then make brick.
        // If we are fully inside terrain, we'll move down later.
        fullyInsideTerrain = solidWallHeight(0, 2) > Walker.highestStepUp;
        assert (bricksLeft > 0);
        --bricksLeft;

        TerrainChange tc;
        tc.update = outsideWorld.state.update;
        tc.type   = TerrainChange.Type.builderBrick;
        tc.style  = style;
        tc.x      = facingRight ? ex - 2 : ex - 8;
        tc.y      = ey;
        outsideWorld.physicsDrawer.add(tc);

        if (bricksLeft < 3 && skillsQueued == 0)
            playSoundIfTribeLocal(Sound.BRICK);
    }

    private void bumpAgainstTerrain()
    {
        // The lix has already moved up and the image has its
        // feet below the regular position, inside the newly placed brick.
        //
        //   XX - the effective coordinate of the checking Lixxie. She has
        //        already moved up from inside the brick, but not yet
        //        walked forward.
        //   11 - numbers denote the checks in the corresp. code line below
        //
        //
        //                   33  22  11
        //
        //               XX
        //           44  44  34  24  11
        //           ()()()()()()()()()()()()
        //           ()()()()()()()()()()()()
        //   [][][][][][][][][][][][]
        //   [][][][][][][][][][][][]

        // 1, 2, 3 in the image above: don't build through walls
        // +6|-1 is the coordinate above the brick, not +6|-2, because:
        // In rare cases, e.g. lix inside thin horizontal beam, the lix
        // wouldn't build up high enough to make the staircase
        // connect with the beam.
        // The three isSolid on the right-hand side enable building
        // staircases on top of other staircases. At least that's how
        // I explained it in 2006. I haven't checked it thoroughly in 2015.
        immutable bool wallNearFoot
            =  (isSolid(6, 1) && isSolid(6, -2))
            || (isSolid(4, 1) && isSolid(4, -2))
            || (isSolid(2, 1) && isSolid(2, -2));

        // 4 in the image above check for being inside a thin horiz. beam
        immutable bool insideThinHorizontalBeam = isSolid(4, 1)
            && isSolid(2, 1) && isSolid(0,  1) && isSolid(-2, 1);

        immutable bool hitHead = isSolid(6, -16) || isSolid(4, -16);

        if (wallNearFoot || insideThinHorizontalBeam || hitHead) {
            turn();
            if (fullyInsideTerrain)
                moveDown();
            become(Ac.WALKER);
        }
    }

    private void maybeBecomeShrugger()
    {
        assert (bricksLeft >= 0);
        if (bricksLeft == 0) {
            assert (skillsQueued >= 0);
            if (skillsQueued == 0) {
                become(Ac.SHRUGGER);
            }
            else {
                --skillsQueued;
                bricksLeft += bricksAtStart;
            }
        }
    }

}
// end class Builder

/+
void update_shrugger(Lixxie& l)
{
    if (l.is_last_frame()) l.become(LixEn::WALKER);
    else l.next_frame();
}
+/

// important to implement this in the shrugger's become,
// this comes from (become walker)
/+
        else if (lixxie.ac == Ac.PLATFORMER && frame > 5) {
            become(Ac.SHRUGGER2);
            frame = 9;
            // See also the next else-if.
            // Clicking twice on the platformer shall turn it around.
        }
        else if (lixxie.ac == Ac.SHRUGGER || lixxie.ac == Ac.SHRUGGER2) {
            become(Ac.WALKER);
            turn();
        }
+/

class Shrugger   : PerformedActivity { mixin(CloneByCopyFrom!"Shrugger"); }
class Platformer : PerformedActivity { mixin(CloneByCopyFrom!"Platformer"); }
