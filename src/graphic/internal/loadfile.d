module graphic.internal.loadfile;

/*
 * These functions assume that there is work to be done.
 * Don't call these if the result is already cached.
 */

import std.algorithm; // find

import basics.alleg5;
import basics.globals : dirDataBitmap;
import file.filename;
import graphic.color;
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
body {
    immutable fn = toBestScaledFilenameOrNull(id);
    if (fn is null) {
        loadedCutbitMayBeScaled[id] = nullCutbit;
        return;
    }
    loadedCutbitMayBeScaled[id] = new Cutbit(fn, Cutbit.Cut.ifGridExists);
    al_convert_mask_to_alpha(loadedCutbitMayBeScaled[id].albit, color.pink);
    if (id.needGuiRecoloring) {
        eidrecol(loadedCutbitMayBeScaled[id], 0);
    }
}

void makeLixSprites(in Style st)
{
    assert (spritesheets[st] is null);
    auto src = getLixRawSprites;
    spritesheets[st] = lockThenRecolor!magicnrSpritesheets(src, st);
}

void makePanelInfoIcon(in Style st)
{
    recolorForGuiAndPlayer!magicnrPanelInfoIcons(
        InternalImage.gameIcon, panelInfoIcons, st);
}

void makeSkillButtonIcon(in Style st)
{
    recolorForGuiAndPlayer!magicnrSkillButtonIcons(
        InternalImage.skillIcons, skillButtonIcons, st);
}

void makeGoalMarker(in Style st)
in { assert (goalMarkers[st] is null); }
body {
    // magicnrSkillButtonIcons isn't a perfect descripition: It recolors
    // exactly the first row. But goal markers have only one frame, thus OK.
    recolorForGuiAndPlayer!magicnrSkillButtonIcons(
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

void recolorForGuiAndPlayer(int magicnr)(
    in InternalImage id,
    ref Cutbit[Style.max] vec,
    in Style st
) {
    assert (vec[st] is null);
    Cutbit sourceCb = getInternalMutable(id);
    vec[st] = lockThenRecolor!magicnr(sourceCb, st);
}
