module game.gui.panelinf;

import std.string; // format;
import std.typecons; // Rebindable;

import basics.globals; // game panel icons
import basics.nettypes; // Update
import basics.user; // languageIsEnglish
import game.tribe;
import graphic.internal;
import gui;
import hardware.display; // show fps
import hardware.sound; // warn when too few lix alive to win
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
private:
    int _targetDescNumber;
    Rebindable!(const(Lixxie)) _targetDescLixxie;
    Rebindable!(const(Tribe))  _tribe;

    CutbitElement _bOut, _bHatch, _bSaved, _bTime;
    Label         _lOut, _lHatch, _lSaved, _lTime;
    Label _spawnint, _targetDesc, _fps;

    // This is 0 if you have enough lix alive to win.
    // This is >= 0 if you don't have enough lix alive.
    // While it is <= the max number, increase it every frame.
    // If it's > 0 and < max, flicker the exit icon.
    int _warningSignFlicker;

public:
    this(Geom g)
    {
        super(g);
        implConstructor();
    }

    @property int
    targetDescriptionNumber(in int a)
    {
        _targetDescNumber = a;
        return a;
    }

    @property const(Lixxie)
    targetDescriptionLixxie(in Lixxie l)
    {
        _targetDescLixxie = l;
        return l;
    }

    void suggestTooltipForceDirection() { }
    void suggestTooltipPriorityInvert() { }
    void suggestTooltipBuilders() { }
    void suggestTooltipPlatformers() { }

    void showTribe(in Tribe tribe) {
        with (tribe)
    {
        assert (tribe);
        reqDraw();
        _lOut  .number = lixHatch + lixOut;
        _lHatch.number = lixHatch;
        _lSaved.text   = "%d/%d".format(lixSaved, lixRequired);
        _bOut.yf   = lixHatch + lixOut > 0 ? 0 : 1;
        _bHatch.yf = 1;
        _bTime.yf  = 1;
        // DTODO: spawnint: cull entirely, or make an icon
        _spawnint.text = "SI: %d".format(spawnint);
        if (basics.user.showFPS.value)
            _fps.text  = "FPS: %d".format(displayFps);

        handleWarningSignFlicker(tribe);
    }}

protected:
    override void calcSelf() { down = false; }
    override void drawOntoButton() { formatTargetDesc(); }

private:
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
        if (auto bc = cast (const BrickCounter) constJob)
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
        // I want to show the time in multiplayer. Until I have that,
        // I display the spawn interval in singleplayer.
        _bTime.hide();
        _spawnint   = new Label(new Geom(_bTime.xg, 0, 70, ylg, From.LEFT));
        _fps        = new Label(new Geom(280, 0, 70, this.ylg, From.LEFT));
        _targetDesc = new Label(new Geom(
            TextButton.textXFromLeft, 0, this.xlg, this.ylg, From.RIGHT));
        addChildren(_spawnint, _targetDesc, _fps);
    }

    void handleWarningSignFlicker(in Tribe tribe) {
        with (tribe)
    {
        enum flickerFreq = 0x10; // total duration of one cycle of 2 frames
        enum flickerMax = 4 * flickerFreq + 1;
        if (lixSaved + lixHatch + lixOut >= lixRequired)
            _warningSignFlicker = 0;
        else if (nuke)
            _warningSignFlicker = flickerMax;
        else if (_warningSignFlicker < flickerMax) {
            if (_warningSignFlicker % flickerFreq == 0)
                hardware.sound.playLoud(Sound.CLOCK);
            ++_warningSignFlicker;
        }
        _bSaved.xf = (_warningSignFlicker + flickerFreq - 1) % flickerFreq
            > flickerFreq/2 ? 5 : 10; // 5 = regular exit, 10 = warning sign
        _bSaved.yf = _bSaved.xf == 10 ? 0
            : lixSaved == 0 ? 1
            : lixSaved >= lixRequired ? 2 : 0;
    }}
}
