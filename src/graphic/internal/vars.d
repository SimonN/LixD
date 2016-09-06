module graphic.internal.vars;

import basics.globals;
import graphic.cutbit;
public import net.style;

package:

bool dontWantRecoloredGraphics;

Cutbit[string]    internal;
Cutbit[Style.max] spritesheets;
Cutbit[Style.max] panelInfoIcons;
Cutbit[Style.max] skillButtonIcons;

Cutbit nullCutbit; // invalid bitmap to return instead of null pointer

immutable int magicnrSpritesheets = 1;
immutable int magicnrPanelInfoIcons = 2;
immutable int magicnrSkillButtonIcons = 3;

string scaleDir() // From which dir should we load?
{
    return _scaleDir != "" ? _scaleDir : dirDataBitmap.rootless;
}

void implSetScale(in float scale)
{
    _scaleDir =
        scale < 1.5f ? dirDataBitmap.rootless
     :  scale < 2.0f ? dirDataBitmapScale ~ "150/"
     :  scale < 3.0f ? dirDataBitmapScale ~ "200/"
     :                 dirDataBitmapScale ~ "300/";
}

private string _scaleDir = "";
