module editor.gui.visuals;

import editor.gui.okcancel;
import file.language;
import gui;
import level.level;

class VisualsWindow : OkCancelWindow {
public:
    this(Level level)
    {
        super(new Geom(0, 0, 300, 200, From.CENTER),
            Lang.winScrollTitle.transl);
    }

protected:
    override void selfWriteChangesTo(Level level) const { }
}
