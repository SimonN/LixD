module editor.select;

// This module is not about hovering (move the mouse over a tile, but don't
// click), but about selecting (add the hovered tiles to selection).

import editor.editor;
import hardware.mouse;

void selectTiles(Editor editor) { with (editor)
{
    if (mouseClickLeft) {
        _selection =_hover;
    }
}}
