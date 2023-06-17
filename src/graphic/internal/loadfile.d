module graphic.internal.loadfile;

/*
 * These functions assume that there is work to be done.
 * Don't call these if the result is already cached.
 */

import std.algorithm; // find

import basics.alleg5;
import basics.globals : dirDataBitmap;
import file.filename;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.names;
import graphic.internal.vars;
import graphic.internal.recol;

package:

void loadBestScaleFromDiskOrPutNullCutbit(in InternalImage id)
in {
    assert (loadedCutbitMayBeScaled[id] is null);
}
out {
    assert (loadedCutbitMayBeScaled[id] !is null); // but may be nullCutbit
}
do {
    immutable fn = toBestScaledFilenameOrNull(id);
    if (fn is null) {
        loadedCutbitMayBeScaled[id] = nullCutbit;
        return;
    }
    loadedCutbitMayBeScaled[id] = new Cutbit(fn, Cutbit.Cut.ifGridExists);
    loadedCutbitMayBeScaled[id].albit.convertPinkToAlpha();
    if (id.needGuiRecoloring) {
        eidrecol(loadedCutbitMayBeScaled[id],
            // Hack! This shouldn't depend on id. Move this decision elsewhere.
            id == InternalImage.scissorsInPanel
                ? SpecialRecol.skillButtonIcons : SpecialRecol.ordinary);
    }
}

void makeLixSprites(in Style st)
{
    assert (spritesheets[st] is null);
    auto src = getLixRawSprites;
    spritesheets[st] = lockThenRecolor!(SpecialRecol.spritesheets)(src, st);
}

void makePanelInfoIcon(in Style st)
{
    recolorForGuiAndPlayer!(SpecialRecol.panelInfoIcons)(
        InternalImage.gameIcon, panelInfoIcons, st);
}

void makeSkillButtonIcon(in Style st)
{
    recolorForGuiAndPlayer!(SpecialRecol.skillButtonIcons)(
        InternalImage.skillsInPanel, skillButtonIcons, st);
}

void makeGoalMarker(in Style st)
in { assert (goalMarkers[st] is null); }
do {
    // magicnrSkillButtonIcons isn't a perfect descripition: It recolors
    // exactly the first row. But goal markers have only one frame, thus OK.
    recolorForGuiAndPlayer!(SpecialRecol.skillButtonIcons)(
        InternalImage.goalMarker, goalMarkers, st);
}

private:

Filename toBestScaledFilenameOrNull(in InternalImage id)
{
    immutable correctScale = new VfsFilename(scaleDir ~ id.toBasename);
    if (correctScale.fileExists && correctScale.hasImageExtension) {
        return correctScale;
    }
    immutable fallbackScale = new VfsFilename(
        dirDataBitmap.dirRootless ~ id.toBasename);
    if (fallbackScale.fileExists && fallbackScale.hasImageExtension) {
        return fallbackScale;
    }
    return null;
}

void recolorForGuiAndPlayer(SpecialRecol magicnr)(
    in InternalImage id,
    ref Cutbit[Style.max] vec,
    in Style st
) {
    assert (vec[st] is null);
    Cutbit sourceCb = getInternalMutable(id);
    vec[st] = lockThenRecolor!magicnr(sourceCb, st);
}
