module graphic.internal.vars;

/*
 *  All global state of package graphic.internal goes in here.
 */

import enumap;

import basics.globals;
import basics.matrix;
import graphic.cutbit;
import graphic.internal.names;
import graphic.internal.spritecol;
public import graphic.color;
public import net.style;

package:

bool _wantRecoloredGraphics;

float _idealScale = 1.0f;

Enumap!(Spritesheet, SpritesheetCollection) _allSheets;
Enumap!(InternalImage, Cutbit) _allGuiImages;
Alcol3D[Style.max] _alcol3DforStyles;

Cutbit nullCutbit; // invalid bitmap to return instead of null pointer
