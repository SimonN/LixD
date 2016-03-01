module graphic.internal.vars;

import basics.globals;
import graphic.cutbit;
import lix.enums;

package:

bool noninteractiveMode;

Cutbit[string]    internal;
Cutbit[Style.max] spritesheets;
Cutbit[Style.max] panelInfoIcons;
Cutbit[Style.max] skillButtonIcons;

Cutbit nullCutbit; // invalid bitmap to return instead of null pointer

string scaleDir = dirDataBitmap.rootless; // load from which dir?

immutable int magicnrSpritesheets = 1;
immutable int magicnrPanelInfoIcons = 2;
immutable int magicnrSkillButtonIcons = 3;
