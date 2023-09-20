module game.panel.infobar;

import std.string; // format;
import std.typecons; // Rebindable;

import file.language;
import opt = file.option.allopts;
import graphic.color;
import graphic.internal;
import gui;
import hardware.display; // show fps
import hardware.sound; // warn when too few lix alive to win
import net.repdata; // Phyu
import physics.job.builder;
import physics.lixxie.lixxie;
import physics.tribe;

abstract class InfoBar : Button {
private:
    bool _showSpawnInterval;
    int _spawnInterval;
    int _targetDescNumber;
    static assert (Ac.init == Ac.nothing);

    Phyu _age;
    ConstLix _targetDescLixxie;
    Rebindable!(const(Tribe))  _tribe;
    CutbitElement _bOut, _bHatch;
    Label _lOut, _lHatch, _targetDesc, _fps;

public:
    this(Geom g)
    {
        super(g);
        makeElements(_bHatch, _lHatch,   4, 60, 4);
        makeElements(_bOut,   _lOut,    60, 60, 3);
        _targetDesc = new Label(new Geom(190, 0, this.xlg - 190, this.ylg));
        _fps = new Label(new Geom(
            TextButton.textXFromLeft, 0, this.xlg, this.ylg, From.RIGHT));
        addChildren(_targetDesc, _fps);
    }

    void describeTarget(in Lixxie l, in int nr)
    {
        if (_targetDescLixxie !is l || _targetDescNumber != nr)
            reqDraw();
        _targetDescLixxie = l;
        _targetDescNumber = nr;
    }

    void dontShowSpawnInterval()
    {
        if (! _showSpawnInterval)
            return;
        reqDraw();
        _showSpawnInterval = false;
    }

    void showSpawnInterval(in int si)
    {
        if (_showSpawnInterval && _spawnInterval == si)
            return;
        reqDraw();
        _showSpawnInterval = true;
        _spawnInterval = si;
    }

    @property Phyu age(in Phyu phyu)
    {
        if (_age == phyu)
            return phyu;
        reqDraw();
        return _age = phyu;
    }

    // Eventually, subclass InfoBar for singleplayer and multiplayer?
    // Pass lixRequired to the constructor of the one subclass.
    void showTribe(in Tribe tribe) {
        with (tribe)
    {
        assert (tribe);
        reqDraw();
        _lHatch.shown = _bHatch.shown = lixInHatch > 0;
        _lOut.shown = _bOut.shown = lixInHatch + lixOut > 0;
        _lHatch.number = lixInHatch;
        _bHatch.yf = 1;
        _lOut.number = lixInHatch + lixOut;
        _bOut.yf = lixInHatch + lixOut > 0 ? 0 : 1;
        onShowTribe(tribe);
    }}

protected:
    abstract void onShowTribe(in Tribe tribe);

    override void calcSelf() { down = false; }
    override void drawOntoButton()
    {
        formatTargetDesc();
        formatFPS();
    }

    // Helper function to make children.
    // This generates a pair of CutbitElement and Label.
    // Reeks like that pair should become its own class.
    auto makeElements(ref CutbitElement cbe, ref Label lab,
        in int x, in int xl, in int xf
    ) {
        cbe = new CutbitElement(new Geom(x, 0, this.ylg, this.ylg,
                        From.LEFT), getPanelInfoIcon(Style.garden));
        cbe.xf = xf;
        lab = new Label(new Geom(x + this.ylg, 0, xl - this.ylg, this.ylg,
                        From.LEFT));
        // Reason for undraw color: When the displayed values change or
        // when we show/hide these, we reqDraw() on the entire panel
        // anyway. Therefore, color.transp can't leave anything during
        // undraw of cbe and lab. If we don't put color.transp here, then
        // the panel will flicker once with the undraw color after these
        // are hidden. Reason for the flickering: They undraw after
        // the parent (this) is drawn, and they overlay not only a
        // gui-medium-color area, but (this)'s 3D button effect.
        cbe.undrawColor = color.transp;
        lab.undrawColor = color.transp;
        addChildren(cbe, lab);
    }

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
    do { with (_targetDescLixxie) {
        string s = "";
        if (_targetDescLixxie) {
            s = "%d %s%s".format(
                _targetDescNumber,
                ac.acToNiceCase,
                _targetDescNumber > 1 && opt.languageIsEnglish ? "s" : "");
            if (auto bc = cast (const BrickCounter) constJob)
                s ~= " [%d]".format(bc.skillsQueued * bc.bricksAtStart
                                    + bc.bricksLeft);
            if (abilityToRun || abilityToClimb || abilityToFloat)
                s ~= " (%s%s%s)".format(
                    abilityToRun   ? "R" : "",
                    abilityToClimb ? "C" : "",
                    abilityToFloat ? "F" : "");
        }
        else if (_showSpawnInterval)
            s = "%s: %d".format(Lang.winConstantsSpawnint.transl,
                                _spawnInterval);
        _targetDesc.text = s;
    }}

    void formatFPS()
    {
        if (! opt.showFPS.value) {
            return; // _fps.txt will remain "" forever.
        }
        _fps.text = "%s %d   FPS: %d".format(
            Lang.tweakerHeaderTick.transl, _age, displayFps);
    }
}

// ############################################################################

class InfoBarSingleplayer : InfoBar {
private:
    CutbitElement _bSaved;
    Label _lSaved;

    int _lixRequired;

    // This is 0 if you have enough lix alive to win.
    // This is >= 0 if you don't have enough lix alive.
    // While it is <= the max number, increase it every frame.
    // If it's > 0 and < max, flicker the exit icon.
    int _warningSignFlicker;
    bool _singleplayerWinSoundPlayed = false;

public:
    this(Geom g, in int lixRequired)
    {
        super(g);
        _lixRequired = lixRequired;
        makeElements(_bSaved, _lSaved, 120, 80, 5);
    }

protected:
    override void onShowTribe(in Tribe tribe) { with (tribe)
    {
        immutable saved = score.lixSaved.raw;
        if (saved < _lixRequired) {
            // "\u2212" is unicode minus
            _lSaved.text = "\u2212%d".format(_lixRequired - saved);
            _singleplayerWinSoundPlayed = false;
        }
        else {
            _lSaved.text = "+%d".format(saved - _lixRequired);
            if (! _singleplayerWinSoundPlayed) {
                _singleplayerWinSoundPlayed = true;
                hardware.sound.playLoud(Sound.YIPPIE);
            }
        }

        enum flickerFreq = 0x10; // total duration of one cycle of 2 frames
        enum flickerMax = 4 * flickerFreq + 1;
        if (score.potential >= _lixRequired)
            _warningSignFlicker = 0;
        else if (triggersOvertime)
            _warningSignFlicker = flickerMax;
        else if (_warningSignFlicker < flickerMax) {
            if (_warningSignFlicker == 0)
                hardware.sound.playLoud(Sound.CANT_WIN);
            ++_warningSignFlicker;
        }
        _bSaved.xf = (_warningSignFlicker + flickerFreq - 1) % flickerFreq
            > flickerFreq/2 ? 5 : 10; // 5 = regular exit, 10 = warning sign
        _bSaved.yf = _bSaved.xf == 10 ? 0 // colorful warning sign
            : score.lixSaved >= _lixRequired ? 2 : 1; // green or grayed-out
    }}
}

class InfoBarMultiplayer : InfoBar {
private:
    CutbitElement _bSaved; // same as in singleplayer. Abstract this sometime
    Label _lSaved;

public:
    this(Geom g)
    {
        super(g);
        makeElements(_bSaved, _lSaved, 120, 80, 5); // same as in SP :-/
    }

protected:
    override void onShowTribe(in Tribe tribe)
    {
        _bSaved.shown = _lSaved.shown = tribe.hasScored;
        if (tribe.hasScored) {
            _bSaved.yf = 1; // greyed out. Maybe invent something better
            _lSaved.text = tribe.score.lixSaved.asText;
        }
    }
}
