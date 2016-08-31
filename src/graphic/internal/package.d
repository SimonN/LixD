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
import lix.enums;

void initialize(Runmode runmode)
{
    nullCutbit = new Cutbit(cast (Cutbit) null);

    final switch (runmode) {
        case Runmode.VERIFY:
            dontWantRecoloredGraphics = true;
            break;
        case Runmode.INTERACTIVE:
        case Runmode.EXPORT_IMAGES:
            break;
        case Runmode.PRINT_AND_EXIT:
            assert (false);
    }
}

void setScaleFromGui(float scale) { implSetScale(scale); }

const(Cutbit) getInternal    (Filename fn) { return getInternalMutable  (fn); }
const(Cutbit) getLixSpritesheet (Style st) { return implGetLixSprites   (st); }
const(Cutbit) getPanelInfoIcon  (Style st) { return implGetPanelInfoIcon(st); }
const(Cutbit) getSkillButtonIcon(Style st) { return implGetSkillButton  (st); }
