module graphic.internal.getters;

import std.range;
import std.exception : enforce;

import basics.globals : dirDataBitmap;
import file.filename;
import graphic.cutbit;
import graphic.internal.loadfile;
import graphic.internal.names;
import graphic.internal.recol;
import graphic.internal.vars;

package:

/*
 * Mostly identical to getInternalMutable, except for:
 *  - Returns the real bitmap even when we don't need recolored graphics.
 *    (getInternalMutable would avoid unnecessary work then.)
 *  - Noisily fails when the sprites aren't found.
 *    (getInternalMutable would return nullCutbit silently.)
 */
Cutbit getLixRawSprites()
out (ret) {
    assert (valid(ret), "can't find Lix spritesheet");
}
do {
    if (loadedCutbitMayBeScaled[InternalImage.spritesheet] !is null) {
        return loadedCutbitMayBeScaled[InternalImage.spritesheet];
    }
    loadBestScaleFromDiskOrPutNullCutbit(InternalImage.spritesheet);
    enforce(valid(loadedCutbitMayBeScaled[InternalImage.spritesheet]),
        "Can't find Lix spritesheet at: "
        ~ dirDataBitmap.dirRootless
        ~ InternalImage.spritesheet.toBasename
        ~ ". The spritesheet is required for physics"
        ~ " because the number of sprites per row affect worker cycles."
        ~ " Is your Lix installation broken?");
    return loadedCutbitMayBeScaled[InternalImage.spritesheet];
}

// Input: ID of internal bitmap file (IDs don't know about scaling subdir)
// Output: The cutbit from the correct scaling subdir, or a replacement image
Cutbit getInternalMutable(in InternalImage id)
{
    assert (nullCutbit, "call graphic.internal.initialize() first");
    if (loadedCutbitMayBeScaled[id] !is null) {
        return loadedCutbitMayBeScaled[id];
    }
    if (! wantRecoloredGraphics) {
        return nullCutbit;
    }
    loadBestScaleFromDiskOrPutNullCutbit(id);
    return loadedCutbitMayBeScaled[id];
}

const(Cutbit) implGetLixSprites(in Style st)
out (ret) { assert(ret); }
do {
    if (! wantRecoloredGraphics)
        return getLixRawSprites();
    if (spritesheets[st] is null)
        makeLixSprites(st);
    return spritesheets[st];
}

const(Cutbit) implGetPanelInfoIcon(in Style st)
out (ret) { assert(ret); }
do {
    if (! wantRecoloredGraphics)
        return nullCutbit;
    if (panelInfoIcons[st] is null)
        makePanelInfoIcon(st);
    return panelInfoIcons[st];
}

const(Cutbit) implGetSkillButton(in Style st)
out (ret) { assert(ret); }
do {
    if (! wantRecoloredGraphics)
        return nullCutbit;
    if (skillButtonIcons[st] is null)
        makeSkillButtonIcon(st);
    return skillButtonIcons[st];
}

const(Cutbit) implGetGoalMarker(in Style st)
out (ret) { assert(ret); }
do {
    if (! wantRecoloredGraphics)
        return nullCutbit;
    if (goalMarkers[st] is null)
        makeGoalMarker(st);
    return goalMarkers[st];
}

const(Alcol3D) implGetAlcol3D(in Style style)
do {
    if (! alcol3DforStyles[style].isValid)
        makeAlcol3DforStyle(style);
    return alcol3DforStyles[style];
}

/*
 * Deallocate all VRAM. See all state in graphic.internal.vars to make
 * sure we go over all possible resources here.
 * We don't destroy non-VRAM resources like color tables for now.
 */
void implDeinitialize()
out { assert (spritesheets[Style.garden] is null, "badly deinitialized"); }
do {
    void deinitArray(T)(ref T arr)
    {
        foreach (ref cb; arr) {
            if (cb) {
                cb.dispose();
                cb = null;
            }
        }
    }
    deinitArray(loadedCutbitMayBeScaled);
    deinitArray(spritesheets);
    deinitArray(panelInfoIcons);
    deinitArray(skillButtonIcons);
    deinitArray(goalMarkers);
}
