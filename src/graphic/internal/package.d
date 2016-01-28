module graphic.internal;

/* Graphics library, loads spritesheets and offers them for use via string
 * lookup. This does not handle Lix terrain, special objects, or L1/L2 graphics
 * sets. All of those are handled by the tile library.
 */

import basics.cmdargs;
import file.filename;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.scale;
import graphic.internal.init;
import graphic.internal.vars;
import lix.enums;

void initialize(Runmode runmode)
{
    switch (runmode) {
        case Runmode.INTERACTIVE: implInitializeInteractive(); break;
        case Runmode.VERIFY:      implInitializeVerify();      break;
        default: assert (false);
    }
}

void deinitialize()                  { implDeinitialize();      }
void setScaleFromGui(in float scale) { implSetScale(scale);     }

const(Cutbit) getInternal(in Filename fn)  { return getInternalMutable  (fn); }
const(Cutbit) getLixSpritesheet (Style st) { return implGetLixSprites   (st); }
const(Cutbit) getPanelInfoIcon  (Style st) { return implGetPanelInfoIcon(st); }
const(Cutbit) getSkillButtonIcon(Style st) { return implGetSkillButton  (st); }
