module graphic.internal.vars;

/*
 *  All global state of package graphic.internal goes in here.
 */

import basics.globals;
import basics.matrix;
import graphic.cutbit;
import graphic.internal.names;
public import graphic.color;
public import net.style;

package:

bool wantRecoloredGraphics;

Cutbit[InternalImage.max + 1] loadedCutbitMayBeScaled;
Cutbit[Style.max] spritesheets;
Cutbit[Style.max] panelInfoIcons;
Cutbit[Style.max] skillButtonIcons;
Cutbit[Style.max] goalMarkers;

Cutbit nullCutbit; // invalid bitmap to return instead of null pointer

Alcol3D[Style.max] alcol3DforStyles;

Matrix!Point eyesOnSpritesheet;

enum SpecialRecol {
    ordinary,
    spritesheets,
    panelInfoIcons,
    skillButtonIcons,
}

float _idealScale = 1.0f;
