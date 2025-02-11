module graphic.internal.getters;

import std.range;
import std.exception : enforce;

import glo = basics.globals;
import basics.alleg5 : convertPinkToAlpha;
import file.filename;
import graphic.cutbit;
import graphic.internal.names;
import graphic.internal.recol;
import graphic.internal.spritecol;
import graphic.internal.vars;

package:

// Input: ID of internal bitmap file (IDs don't know about scaling subdir)
// Output: The cutbit from the correct scaling subdir, or a replacement image
Cutbit getInternalMutable(in InternalImage id)
{
    assert (nullCutbit, "call graphic.internal.initialize() first");
    if (_allGuiImages[id] !is null) {
        return _allGuiImages[id];
    }
    if (! _wantRecoloredGraphics) {
        return nullCutbit;
    }
    _allGuiImages[id] = loadMaybeScaledFromDiskOrInvaildCutbit(id);
    return _allGuiImages[id];
}

const(Cutbit) implGetSprites(in Spritesheet sheet, in Style st)
out (ret) { assert(ret); }
do {
    if (! _allSheets[sheet].isValid) {
        Cutbit cb = loadMaybeScaledFromDiskOrInvaildCutbit(sheet);
        _allSheets[sheet] = SpritesheetCollection(cb,
              sheet == Spritesheet.allSkills
            ? &lockThenRecolor!(SpecialRecol.spritesheets)
            : sheet == Spritesheet.infoBarIcons
            ? &lockThenRecolor!(SpecialRecol.infoBarIcons)
            /*
             * Both goalMarkers and skillsInPanel use SR.skillsInPanel.
             * For goalMarkers, this isn't a perfect descripition of recoloring
             * because SR.skillsInPanel recolors exactly the first row,
             * and goal markers have only that single row.
             */
            : &lockThenRecolor!(SpecialRecol.skillsInPanel));
        enforce(_allSheets[sheet].isValid,
            "Can't find unrecolored spritesheet at: "
            ~ sheet.toLoggableName
            ~ ". The spritesheet is required for physics"
            ~ " because the number of sprites per row affect worker cycles."
            ~ " Is your Lix installation broken?");
    }
    return _wantRecoloredGraphics
        ? _allSheets[sheet].get(st)
        : _allSheets[sheet].getUnrecolored;
}

const(Alcol3D) implGetAlcol3D(in Style style)
do {
    if (! _alcol3DforStyles[style].isValid) {
        _alcol3DforStyles[style] = makeAlcol3D(style);
    }
    return _alcol3DforStyles[style];
}

/*
 * Deallocate all VRAM. See all state in graphic.internal.vars to make
 * sure we go over all possible resources here.
 * We don't destroy non-VRAM resources like color tables.
 */
void implDeinitialize()
do {
    foreach (InternalImage id, ref Cutbit cb; _allGuiImages) {
        if (cb) {
            cb.dispose();
            cb = null;
        }
    }

    foreach (Spritesheet sheet, ref SpritesheetCollection coll; _allSheets) {
        coll.dispose;
    }
}

///////////////////////////////////////////////////////////////////////////////

private:

Cutbit loadMaybeScaledFromDiskOrInvaildCutbit(Id)(in Id id)
    if (is (Id == InternalImage) || is (Id == Spritesheet))
{
    immutable fn = toBestScaledFilenameOrNull(id);
    if (fn is null || ! fn.fileExists || ! fn.hasImageExtension) {
        return nullCutbit;
    }
    auto ret = new Cutbit(fn, Cutbit.Cut.ifGridExists);
    static if (is (Id == InternalImage)) {
        ret.albit.convertPinkToAlpha();
        if (id.needGuiRecoloring) {
            eidrecol(ret, SpecialRecol.ordinary);
        }
    }
    return ret;
}

Filename toBestScaledFilenameOrNull(Id)(in Id id)
    if (is (Id == InternalImage) || is (Id == Spritesheet))
{
    immutable unscaled = new VfsFilename(
        glo.dirDataBitmap.rootless ~ id.toBasenameNoExt ~ ".png");
    if (unscaled.fileExists && unscaled.hasImageExtension) {
        return unscaled;
    }
    foreach (candidate; candidateBasenames(_idealScale)) {
        auto scaled = new VfsFilename(
            glo.dirDataBitmap.rootless ~ id.toBasenameNoExt ~ "/" ~ candidate);
        assert (scaled.hasImageExtension,
            "Expected hasImageExtension for " ~ scaled.rootless);
        if (scaled.fileExists) {
            return scaled;
        }
    }
    return null;
}

string[] candidateBasenames(in float wantedScale)
{
    return wantedScale >= 6 ? ["3.png", "2.png", "1.5.png", "1.png"]
        :  wantedScale >= 4 ? ["2.png", "3.png", "1.5.png", "1.png"]
        :  wantedScale >= 3 ? ["3.png", "1.5.png", "2.png", "1.png"]
        :  wantedScale >= 2 ? ["2.png", "1.5.png", "1.png"]
        :  wantedScale >= 1.5f ? ["1.5.png", "1.png"] : ["1.png"];
}
