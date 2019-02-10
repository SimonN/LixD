module graphic.internal.loadfile;

import std.algorithm; // find

import basics.alleg5;
import file.filename;
import graphic.color;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.names;
import graphic.internal.vars;
import graphic.internal.recol;

package:

void loadFromDisk(Filename fn)
{
    if (! fn.fileExists || ! fn.hasImageExtension) {
        return;
    }
    Cutbit cb = new Cutbit(fn, Cutbit.Cut.ifGridExists);
    if (!cb || !cb.valid) {
        return;
    }
    al_convert_mask_to_alpha(cb.albit, color.pink);
    internal[fn.rootlessNoExt] = cb;
    assert (fn.rootlessNoExt in internal);
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

void recolorForGuiAndPlayer(int magicnr)(
    in InternalImage id,
    ref Cutbit[Style.max] vec,
    in Style st
) {
    assert (vec[st] is null);
    Cutbit sourceCb = getInternalMutable(id);
    vec[st] = lockThenRecolor!magicnr(sourceCb, st);
}
