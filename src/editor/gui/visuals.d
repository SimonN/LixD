module editor.gui.visuals;

import editor.gui.okcancel;
import file.language;
import gui;
import level.level;
import menu.opthelp; // DTODO: move this out of package menu

class VisualsWindow : OkCancelWindow {
private:
    NumPickOption _red, _green, _blue;

    /+
    winScrollTitle,
    winScrollManual,
    winScrollX,
    winScrollY,
    winScrollRed,
    winScrollGreen,
    winScrollBlue,
    winScrollJump,
    winScrollCurrent,
    +/

public:
    this(Level level)
    {
        super(new Geom(0, 0, 380, 200, From.CENTER),
            Lang.winScrollTitle.transl);
        NumPickConfig cfg;
        cfg.digits     = 3; // the first one is '0x'
        cfg.sixButtons = true;
        cfg.hex        = true;
        cfg.max        = 0xFF;
        cfg.stepMedium = 0x04;
        cfg.stepBig    = 0x10;
        _red = new NumPickOption(new Geom(20, 40, xlg-40, 20),
            cfg, Lang.winScrollRed.transl, &level.bgRed);
        _green = new NumPickOption(new Geom(20, 70, xlg-40, 20),
            cfg, Lang.winScrollGreen.transl, &level.bgGreen);
        _blue = new NumPickOption(new Geom(20, 100, xlg-40, 20),
            cfg, Lang.winScrollBlue.transl, &level.bgBlue);
        foreach (e; [_red, _green, _blue]) {
            addChild(e);
            e.loadValue();
        }
        // DTODO: Replace these with the correct GUI elements to set
        // initial scrolling position, both automatic and normal
        auto g = new Geom(20, 55, xlg-140, 20, From.BOTTOM_LEFT);
        addChild(new Label(new Geom(g), "Manual screen start not yet"));
        g.y = 42;
        addChild(new Label(new Geom(g), "implemented. Old levels:"));
        g.y = 29;
        addChild(new Label(new Geom(g), "Editor keeps their setting."));
        g.y = 16;
        addChild(new Label(new Geom(g), "New levels: Focus on hatches."));
    }

protected:
    override void selfWriteChangesTo(Level level)
    {
        _red.saveValue();
        _green.saveValue();
        _blue.saveValue();
    }
}
