module lix.skill.miner;

import std.algorithm; // max

import hardware.sound;
import lix;
import physics;

class Miner : Job {
private:
    // Counts how many pixels the miner has been moved down during the frames
    // where the lix is not moving forward. This can happen due to terrain
    // being removed below the lix. When this counter exceeds 4, the lix stops
    // mining. This counter is reset after a miner swing.
    int movedDownSinceSwing;

    // Right before the miner advances forward, we check if the pixels the
    // lix will move to are solid. So the i-th bit of this bitfield tells us if
    // the pixel at the i-th future position is solid. Basically, the miner
    // behaves as it has always behaved before August 2015 if no terrain is
    // removed under him. It is only allowed to move down in two cases:
    // (1) It's not moving forward.
    // (2) It's moving forward, but the path was solid before moving.
    bool[futureLength] futureGroundIsSolid;

public:
    enum futureLength = 4;
    enum maxGapDepth = 3;

    override PhyuOrder updateOrder() const { return PhyuOrder.remover; }

    override void perform()
    {
        lixxie.advanceFrame();
        if (frame == 1) {
            checkFutureGround();
            antiShock(maxGapDepth);
        }
        else if (frame == 2) {
            removeEarth();
            movedDownSinceSwing = 0;
            antiShock(maxGapDepth + 1); // DTODOGEOO: why +1?
        }
        else if (frame >= 3 && frame < 7) {
            antiShock(maxGapDepth + 1);
        }
        else if (frame >= 7 && frame < 12) {
            normalMovement();
        }
        else if (frame >= 12 || frame == 0) {
            antiShock(maxGapDepth);
        }
    }

private:
    void antiShock(in int resiliance) {
        int downThisFrame = antiShockMoveDown(resiliance);
        if (! lixxie.isSolid || movedDownSinceSwing > resiliance)
            Faller.becomeWithAlreadyFallenPixels(lixxie, downThisFrame);
    }

    int antiShockMoveDown(in int maxDepth)
    {
        int downThisFrame = 0;
        while (downThisFrame < maxDepth
            && ! lixxie.isSolid(0, 2 + downThisFrame)
        ) {
            ++downThisFrame;
            ++movedDownSinceSwing;
        }
        if (lixxie.isSolid(0, 2 + downThisFrame)) {
            lixxie.moveDown(downThisFrame);
            return downThisFrame;
        }
        else
            // not solid: do nothing, we'll cancel the miner later
            return 0;
    }

    void removeEarth()
    {
        TerrainDeletion tc;
        tc.update = lixxie.outsideWorld.state.age;
        tc.type = lixxie.facingRight
            ? TerrainDeletion.Type.mineRight : TerrainDeletion.Type.mineLeft;
        tc.x = lixxie.ex - masks[tc.type].offsetX;
        tc.y = lixxie.ey - masks[tc.type].offsetY;
        lixxie.outsideWorld.physicsDrawer.add(tc);
        if (lixxie.wouldHitSteel(masks[tc.type])) {
            lixxie.outsideWorld.effect.addPickaxe(
                lixxie.outsideWorld.state.age,
                lixxie.outsideWorld.passport, lixxie.foot, lixxie.dir);
            lixxie.turn();
            lixxie.become(Ac.walker);
        }
    }

    void checkFutureGround()
    {
        for (int j = 0; j < futureLength; ++j)
            futureGroundIsSolid[j] = lixxie.isSolid(2 * j + 2,
                // Use (movedDownSinceSwing - j) because the lix might have
                // been moved down this frame already, and then it advances
                // horizontally for a few frames
                2 + (j+1) + max(movedDownSinceSwing - j, 0));
    }

    // normal movement == not the anti-shock movement
    void normalMovement()
    {
        int downThisFrame;
        if (frame != 9) {
            lixxie.moveAhead();
            if (movedDownSinceSwing == 0) {
                lixxie.moveDown(1);
                downThisFrame = 1;
            }
            else
                movedDownSinceSwing -= 1;
        }
        assert (frame >= 7 && frame < 12);
        immutable int future =
              frame == 7 ? 0
            : frame == 8 || frame == 9 ? 1
            : frame == 10 ? 2 : 3;
        if (futureGroundIsSolid[future])
            // += instead of = should fix what I think is a bug in C++
            downThisFrame += antiShockMoveDown(maxGapDepth);

        immutable bool downTooFar = movedDownSinceSwing > maxGapDepth;
        immutable bool solid = lixxie.isSolid(0, 2)
            || futureGroundIsSolid[future];
        immutable bool leeway
            = (frame == 7 || frame == 10) && lixxie.isSolid(0, 3);
        if (downTooFar || (! solid && ! leeway))
            Faller.becomeWithAlreadyFallenPixels(lixxie, downThisFrame);
    }
}
