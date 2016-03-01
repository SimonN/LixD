module graphic.internal.loadfile;

import std.algorithm; // find

import basics.alleg5;
import basics.globals;
import file.filename;
import file.search;
import graphic.color;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.vars;
import graphic.internal.recol;
import lix.enums; // Style

package:

void loadFromDisk(Filename fn)
{
    if (! fn.fileExists || ! fn.hasImageExtension) {
        return;
    }
    Cutbit cb = new Cutbit(fn);
    if (!cb || !cb.valid) {
        return;
    }
    al_convert_mask_to_alpha(cb.albit, color.pink);
    internal[fn.rootlessNoExt] = cb;
    assert (fn.rootlessNoExt in internal);
}

bool needGuiRecoloring(Filename fn)
{
    return [fileImageGuiNumber,
            fileImageEditFlip,
            fileImageEditHatch,
            fileImageEditPanel,
            fileImageGameArrow,
            fileImageGameNuke,
            fileImageGamePanel,
            fileImageGamePanel2,
            fileImageGamePanelHints,
            fileImageGameSpawnint,
            fileImageGamePause,
            fileImageLobbySpec,
            fileImageMenuCheckmark,
            fileImagePreviewIcon
        ].find(fn) != null;
}

void makeLixSprites(in Style st)
{
    assert (spritesheets[st] is null);
    auto src = getLixRawSprites;
    spritesheets[st] = lockThenRecolor(src, magicnrSpritesheets, st);
}

void makePanelInfoIcon(in Style st)
{
    recolorForGuiAndPlayer(fileImageGameIcon,
        magicnrPanelInfoIcons, panelInfoIcons, st);
}

void makeSkillButtonIcon(in Style st)
{
    recolorForGuiAndPlayer(fileImageSkillIcons,
        magicnrSkillButtonIcons, skillButtonIcons, st);
}

private:

void recolorForGuiAndPlayer(
    in Filename fn,
    in int magicnr,
    ref Cutbit[Style.max] vec,
    in Style st
) {
    assert (vec[st] is null);
    Cutbit sourceCb = getInternalMutable(fn);
    vec[st] = lockThenRecolor(sourceCb, magicnr, st);
}
