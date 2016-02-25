module graphic.internal.getters;

import basics.globals;
import file.filename;
import graphic.cutbit;
import graphic.internal.loadfile;
import graphic.internal.recol;
import graphic.internal.vars;
import lix.enums;

private enum imgExt = ".png";

package:

Cutbit getLixRawSprites()
out (ret) {
    assert (ret && ret != nullCutbit, "can't find Lix spritesheet");
}
body {
    static fn = new Filename(fileImageSpritesheet.rootless ~ imgExt);
    if (auto ret = fn.rootlessNoExt in internal)
        return *ret;
    loadFromDisk(fn);
    assert (fn.rootlessNoExt in internal, "can't find Lix spritesheet");
    return *(fn.rootlessNoExt in internal);
}

// Input: filename without any scaling subdir
// Output: The cutbit from the correct scaling subdir, or a replacement image
// See comment near graphic.internal.vars.internal about how we save strings
Cutbit getInternalMutable(in Filename fn)
{
    if (noninteractiveMode)
        return nullCutbit;
    auto correctScale  = new Filename(scaleDir ~ fn.file ~ imgExt);
    auto fallbackScale = new Filename(fn.rootless ~ imgExt);
    if (auto ret = correctScale.rootlessNoExt in internal)
        return *ret;
    if (auto ret = fallbackScale.rootlessNoExt in internal)
        return *ret;
    // Neither the correcty-scaled image nor the fallback have already
    // been successfully loaded. Try to load from disk in this order.
    loadFromDisk(correctScale);
    if (auto ret = correctScale.rootlessNoExt in internal) {
        if (fn.needGuiRecoloring)
            eidrecol(*ret, 0);
        return *ret;
    }
    loadFromDisk(fallbackScale);
    if (auto ret = fallbackScale.rootlessNoExt in internal) {
        if (fn.needGuiRecoloring)
            eidrecol(*ret, 0);
        return *ret;
    }
    return nullCutbit;
}

const(Cutbit) implGetLixSprites(in Style st)
{
    if (noninteractiveMode)
        return getLixRawSprites();
    if (auto ret = st in spritesheets)
        return *ret;
    else
        return getLixRawSprites;
}

const(Cutbit) implGetPanelInfoIcon(in Style st)
{
    if (noninteractiveMode)
        return nullCutbit;
    if (auto ret = st in panelInfoIcons)
        return *ret;
    else
        return nullCutbit;
}

const(Cutbit) implGetSkillButton(in Style st)
{
    if (noninteractiveMode)
        return nullCutbit;
    if (auto ret = st in skillButtonIcons)
        return *ret;
    else
        return nullCutbit;
}
