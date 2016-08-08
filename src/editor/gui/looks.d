module editor.gui.looks;

import editor.gui.okcancel;
import file.language;
import gui;
import level.level;

class LooksWindow : OkCancelWindow {
private:
    NumPick _red, _green, _blue;
    enum numPickXl = 120 + 40 + 10;

public:
    this(Level level)
    {
        super(new Geom(0, 0, 350, 200, From.CENTER),
            Lang.winLooksTitle.transl);
        auto newPick(in float y, in int startValue, in Lang desc)
        {
            NumPickConfig cfg;
            cfg.digits     = 3; // the first one is '0x'
            cfg.sixButtons = true;
            cfg.hex        = true;
            cfg.max        = 0xFF;
            cfg.stepMedium = 0x04;
            cfg.stepBig    = 0x10;
            auto ret = new NumPick(new Geom(20, y, numPickXl, 20,
                From.TOP_RIGHT), cfg);
            ret.number = startValue;
            this.addChild(ret);
            this.addChild(new Label(new Geom(20, y, xlg - 40 - numPickXl, 20),
                desc.transl));
            return ret;
        }
        _red = newPick(40, level.bgRed, Lang.winLooksRed);
        _green = newPick(70, level.bgGreen, Lang.winLooksGreen);
        _blue = newPick(100, level.bgBlue, Lang.winLooksBlue);

        // DTODO: Replace these with the correct GUI elements to set
        // initial scrolling position, both automatic and normal
        auto g = new Geom(20, 55, xlg-140, 20, From.BOTTOM_LEFT);
        addChild(new Label(new Geom(g), "Manual screen start not yet"));
        g.y = 42; addChild(new Label(new Geom(g), "implemented. Old levels:"));
        g.y = 29; addChild(new Label(new Geom(g), "Editor keeps their setting."));
        g.y = 16; addChild(new Label(new Geom(g), "New levels focus on hatches."));
    }

protected:
    override void selfWriteChangesTo(Level level)
    {
        level.bgRed = _red.number;
        level.bgGreen = _green.number;
        level.bgBlue = _blue.number;
    }
}
