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
            _wantRecoloredGraphics = false;
            break;
        case Runmode.INTERACTIVE:
        case Runmode.EXPORT_IMAGES:
            _wantRecoloredGraphics = true;
            break;
        case Runmode.PRINT_AND_EXIT:
            assert (false);
    }
}

void initializeScale(float scale) { _idealScale = scale; }
void deinitialize()               { implDeinitialize();  }

const(Cutbit) toCutbit(in InternalImage id) { return getInternalMutable(id); }
const(Cutbit) toCutbitFor(in Spritesheet sheet, in Style st)
{
    return implGetSprites(sheet, st);
}

const(Alcol3D) getAlcol3DforStyle(Style st) { return implGetAlcol3D(st); }

Point eyesForFrame(in Spritesheet sheet, in int xf, in int yf)
{
    return _allSheets[sheet].eyesForFrame(xf, yf);
}
