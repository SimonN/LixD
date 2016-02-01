module editor.draw;

import basics.alleg5;
import editor.editor;
import graphic.color;
import hardware.display;

package:

void implEditorDraw(Editor editor) { with (editor)
{
    DrawingTarget drata = DrawingTarget(al_get_backbuffer(display));
    al_clear_to_color(color.guiD);
}}
