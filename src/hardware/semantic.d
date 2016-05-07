module hardware.semantic;

// High-level input information that's gathered from mouse and keyboard,
// according to user options.

import basics.user;
import hardware.keyboard;

bool forcingLeft()
{
    return   keyHeld(basics.user.keyForceLeft)
        && ! keyHeld(basics.user.keyForceRight);
}

bool forcingRight()
{
    return ! keyHeld(basics.user.keyForceLeft)
        &&   keyHeld(basics.user.keyForceRight);
}
