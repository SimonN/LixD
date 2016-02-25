module graphic.internal.loadfile;

import std.algorithm; // find

import basics.alleg5;
import basics.globals;
import file.filename;
import file.search;
import graphic.color;
import graphic.cutbit;
import graphic.internal.vars;

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
