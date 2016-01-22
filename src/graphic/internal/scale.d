module graphic.internal.scale;

import basics.globals;
import graphic.internal.vars;

package:

void implSetScale(float scale)
{
    scaleDir =
        scale < 1.5f ? dirDataBitmap.rootless
     :  scale < 2.0f ? dirDataBitmapScale.rootless ~ "150/"
     :  scale < 3.0f ? dirDataBitmapScale.rootless ~ "200/"
     :                 dirDataBitmapScale.rootless ~ "300/";
}
