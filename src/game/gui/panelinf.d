module game.gui.panelinf;

import std.string; // format;
import std.typecons; // Rebindable;

import basics.globals; // game panel icons
import basics.user; // languageIsEnglish
import game.tribe;
import graphic.internal;
import gui;
import hardware.display; // show fps
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
        implConstructor();
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

    void showTribe(in Tribe tribe) { with (tribe)
    {
        assert (tribe);
        reqDraw();
        _lOut  .number = lixHatch + lixOut;
        _lHatch.number = lixHatch;
        _lSaved.text   = "%d/%d".format(lixSaved, lixRequired);
        _lTime .text   = "(---)";
        _bOut.yf   = lixHatch + lixOut > 0 ? 0 : 1;
        _bHatch.yf = 1;
        _bSaved.yf = lixSaved == 0 ? 1 : lixSaved >= lixRequired ? 2 : 0;
        _bTime.yf  = 1;
        _fps.text  = "FPS: %d".format(displayFps);
    }}

protected:

    override void calcSelf()
    {
        down = false;
    }

    override void drawOntoButton()
    {
        formatTargetDesc();
    }

private:

    int _targetDescNumber;
    Rebindable!(const(Lixxie)) _targetDescLixxie;
    Rebindable!(const(Tribe))  _tribe;

    CutbitElement _bOut, _bHatch, _bSaved, _bTime;
    Label         _lOut, _lHatch, _lSaved, _lTime;
    Label _targetDesc, _fps;

    void formatTargetDesc()
    in {
        assert (  _targetDesc);
        assert (  _targetDescNumber >= 0,
            format("_targetDescNumber == %d, not >= 0", _targetDescNumber));
        assert ( (_targetDescNumber == 0) == (_targetDescLixxie is null),
            format("_targetDescLixxie %s, but _targetDescNumber == %d",
            _targetDescLixxie ? "exists" : "null", _targetDescNumber));
    }
    body { with (_targetDescLixxie) {
        string s = "";
        scope (exit)
            _targetDesc.text = s;
        if (! _targetDescLixxie)
            return;
        s = "%d %s%s".format(
            _targetDescNumber,
            ac.acToNiceCase,
            _targetDescNumber > 1 && languageIsEnglish ? "s" : "");
        if (auto bc = cast (const BrickCounter) constPerformedActivity)
            s ~= " [%d]".format(bc.skillsQueued * bc.bricksAtStart + bc.bricksLeft);
        if (abilityToRun || abilityToClimb || abilityToFloat)
            s ~= " (%s%s%s)".format(
                abilityToRun   ? "R" : "",
                abilityToClimb ? "C" : "",
                abilityToFloat ? "F" : "");
    }}

    void implConstructor()
    {
        assert (! _bOut);
        auto makeElements(ref CutbitElement cbe, ref Label lab,
            in int x, in int xl, in int xf
        ) {
            cbe = new CutbitElement(new Geom(x, 0, this.ylg, this.ylg,
                            From.LEFT), getPanelInfoIcon(Style.garden));
            cbe.xf = xf;
            lab = new Label(new Geom(x + this.ylg, 0, xl - this.ylg, this.ylg,
                            From.LEFT));
            addChildren(cbe, lab);
        }
        makeElements(_bOut,   _lOut,     0, 60, 3);
        makeElements(_bHatch, _lHatch,  60, 60, 4);
        makeElements(_bSaved, _lSaved, 120, 80, 5);
        makeElements(_bTime,  _lTime,  200, 70, 7);
        _fps        = new Label(new Geom(270, 0, 70, this.ylg, From.LEFT));
        _targetDesc = new Label(new Geom(
            TextButton.textXFromLeft, 0, this.xlg, this.ylg, From.RIGHT));
        addChildren(_targetDesc, _fps);
    }
}