module hardware.semantic;

// High-level input information that's gathered from mouse and keyboard,
// according to user options.

import basics.user;

bool forcingLeft()
{
    return   basics.user.keyForceLeft.keyHeld
        && ! basics.user.keyForceRight.keyHeld;
}

bool forcingRight()
{
    return ! basics.user.keyForceLeft.keyHeld
        &&   basics.user.keyForceRight.keyHeld;
}

int keyMenuMoveByTotal()
{
    return keyMenuUpBy1  .keyTappedAllowingRepeats * -1
        +  keyMenuUpBy5  .keyTappedAllowingRepeats * -5
        +  keyMenuDownBy1.keyTappedAllowingRepeats * 1
        +  keyMenuDownBy5.keyTappedAllowingRepeats * 5;
}
