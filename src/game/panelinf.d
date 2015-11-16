module game.panelinf;

import gui;
import lix;

// "GameplayPanelMode"
enum GapaMode {
    NONE,
    PLAY_SINGLE,
    PLAY_MULTI,
    REPLAY_SINGLE,
    REPLAY_MULTI,
    SPEC_MULTI
}

class PanelStats : Button {

    this(Geom g) { super(g); }

    @property void targetDescriptionNumber(in int) { }
    @property void targetDescriptionLixxie(in Lixxie)  { }

    void suggestTooltipForceDirection() { }
    void suggestTooltipPriorityInvert() { }
    void suggestTooltipBuilders() { }
    void suggestTooltipPlatformers() { }

    protected override void calcSelf()
    {
        down = false;
    }
}
