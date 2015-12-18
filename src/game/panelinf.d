module game.panelinf;

import std.string; // format;
import std.typecons; // Rebindable;

import basics.user; // languageIsEnglish
import game.tribe;
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

    this(Geom g)
    {
        super(g);
        _targetDesc = new Label(new Geom(
            TextButton.textXFromLeft, 0, this.xlg, this.ylg, From.RIGHT));
        _debugging = new Label(new Geom(
            TextButton.textXFromLeft, 0, this.xlg, this.ylg));
        addChildren(_targetDesc, _debugging);
    }

    @property int
    targetDescriptionNumber(in int a)
    {
        if (_targetDescNumber != a) {
            _targetDescNumber = a;
            // reqDraw();
        }
        return a;
    }

    @property const(Lixxie)
    targetDescriptionLixxie(in Lixxie l)
    {
        if (_targetDescLixxie !is l) {
            _targetDescLixxie = l;
            // reqDraw();
        }
        return l;
    }

    void suggestTooltipForceDirection() { }
    void suggestTooltipPriorityInvert() { }
    void suggestTooltipBuilders() { }
    void suggestTooltipPlatformers() { }

    void showTribe(in Tribe tribe) {
        with (tribe)
    {
        if (tribe !is null)
            _debugging.text = "out %d/%d, in %d/%d"
                .format(lixHatch + lixOut, lixInitial, lixSaved, lixRequired);
        else
            _debugging.text = "tribeLocal is null";
    }}

private:

    int _targetDescNumber;
    Rebindable!(const(Lixxie)) _targetDescLixxie;
    Rebindable!(const(Tribe))  _tribe;

    Label _targetDesc;
    Label _debugging; // split into many labels

    void formatTargetDesc()
    in {
        assert (  _targetDesc);
        assert (  _targetDescNumber >= 0,
            format("_targetDescNumber == %d, not >= 0", _targetDescNumber));
        assert ( (_targetDescNumber == 0) == (_targetDescLixxie is null),
            format("_targetDescLixxie %s, but _targetDescNumber == %d",
            _targetDescLixxie ? "exists" : "null", _targetDescNumber));
    }
    body {
        _targetDesc.text = (! _targetDescLixxie) ? "" : format("%d %s%s",
            _targetDescNumber,
            _targetDescLixxie.ac.acToNiceCase,
            _targetDescNumber > 1 && languageIsEnglish ? "s" : "");
    }

protected:

    override void calcSelf()
    {
        down = false;
    }

    override void drawSelf()
    {
        super.drawSelf();
        formatTargetDesc();
    }
}
