module graphic.internal.getters;

import file.filename;
import graphic.cutbit;
import graphic.internal.vars;
import lix.enums;

package:

Cutbit getInternalMutable(in Filename fn)
{
    Filename correctScale(in Filename f)
    {
        return new Filename(scaleDir ~ f.file);
    }
    string str = correctScale(fn).rootlessNoExt;
    if (auto ret = str in internal)
        return *ret;

    // if not yet returned, fall back onto non-scaled bitmap
    str = fn.rootlessNoExt;
    if (auto ret = str in internal)
        return *ret;
    else
        return nullCutbit;
}

const(Cutbit) implGetLixSprites(in Style st)
{
    if (auto ret = st in spritesheets)
        return *ret;
    else
        return nullCutbit;
}

const(Cutbit) implGetPanelInfoIcon(in Style st)
{
    if (auto ret = st in panelInfoIcons)
        return *ret;
    else
        return nullCutbit;
}

const(Cutbit) implGetSkillButton(in Style st)
{
    if (auto ret = st in skillButtonIcons)
        return *ret;
    else
        return nullCutbit;
}
