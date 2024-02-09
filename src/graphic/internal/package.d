module graphic.internal;

/* Graphics library, loads spritesheets and offers them for use via string
 * lookup. This does not handle Lix terrain, special objects, or L1/L2 graphics
 * sets. All of those are handled by the tile library.
 */

import basics.cmdargs;
import file.filename;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.vars;

public import graphic.internal.names;

void initialize(Runmode runmode)
{
    if (! nullCutbit)
        // This doesn't allocate VRAM, OK to not kill it on deinitialize
        nullCutbit = new Cutbit(cast (Cutbit) null);

    final switch (runmode) {
        case Runmode.VERIFY:
            wantRecoloredGraphics = false;
            break;
        case Runmode.INTERACTIVE:
        case Runmode.EXPORT_IMAGES:
            wantRecoloredGraphics = true;
            break;
        case Runmode.PRINT_AND_EXIT:
            assert (false);
    }
}

void initializeScale(float scale) { _idealScale = scale; }
void deinitialize()               { implDeinitialize();  }

const(Cutbit) toCutbit(in InternalImage id) { return getInternalMutable(id); }
// also public: Filename toFilename(InternalImage) in graphic.internal.names

const(Cutbit) getLixSpritesheet (Style st) { return implGetLixSprites   (st); }
const(Cutbit) getPanelInfoIcon  (Style st) { return implGetPanelInfoIcon(st); }
const(Cutbit) getSkillButtonIcon(Style st) { return implGetSkillButton  (st); }
const(Cutbit) getGoalMarker     (Style st) { return implGetGoalMarker   (st); }

const(Alcol3D) getAlcol3DforStyle(Style st) { return implGetAlcol3D(st); }

const(typeof(graphic.internal.vars.eyesOnSpritesheet)) eyesOnSpritesheet()
{
    assert (graphic.internal.vars.eyesOnSpritesheet,
        "Generate at least one Lix style first before finding eyes."
        ~ " We require this for efficiency to lock the bitmap only once.");
    return graphic.internal.vars.eyesOnSpritesheet;
}
