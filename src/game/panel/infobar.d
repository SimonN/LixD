module game.panel.infobar;

import std.string; // format;

import glo = basics.globals;
import file.language;
import opt = file.option.allopts;
import graphic.color;
import physics.gadget;
import graphic.internal;
import gui;
import hardware.display; // show fps
import hardware.sound; // warn when too few lix alive to win
import net.repdata; // Phyu
import physics.job.builder;
import physics.lixxie.lixxie;
import physics.lixxie.fields;
import physics.tribe;

abstract class InfoBar : Button {
private:
    Phyu _age;
    int _numLixUnderCursor;
    ConstLix _highlitLix; // May be null.
    Passport _highlitPassport; // Ignore whenever _highlitLix is null.
    string _hoveredGadget; // == "" when mouse isn't hovering over a gadget.

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

    void describeLixxie(
        in Lixxie l,
        in Passport p,
        in int numLixUnderCursor)
    {
        if (_highlitLix is l && _numLixUnderCursor == numLixUnderCursor) {
            return;
        }
        reqDraw();
        _highlitLix = l;
        _highlitPassport = p;
        _numLixUnderCursor = numLixUnderCursor;
    }

    void describeNoLixxie()
    {
        if (_highlitLix is null && _numLixUnderCursor == 0) {
            return;
        }
        reqDraw();
        _highlitLix = null;
        _highlitPassport = Passport();
        _numLixUnderCursor = 0;
    }

    void describeNoGadget()
    {
        if (_hoveredGadget.empty) {
            return;
        }
        reqDraw();
        _hoveredGadget = "";
    }

    void describeGadget(in Phyu now, in Tribe viewer, const(Gadget) gad)
    {
        _hoveredGadget = gad.tooltip(now, viewer);
        reqDraw(); // The gadget can change its own description every frame.
    }

    // Eventually, subclass InfoBar for singleplayer and multiplayer?
    // Pass lixRequired to the constructor of the one subclass.
    void show(in Phyu now, in Tribe tribe)
    in { assert (tribe); }
    do { with (tribe)
    {
        reqDraw();
        _age = now;
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
    abstract string formatExtraDesc();

    override void calcSelf() { down = false; }
    override void drawOntoButton()
    {
        _targetDesc.text = formatTargetDesc();
        _fps.text = formatFPS();
    }

    // Helper function to make children.
    // This generates a pair of CutbitElement and Label.
    // Reeks like that pair should become its own class.
    auto makeElements(ref CutbitElement cbe, ref Label lab,
        in int x, in int xl, in int xf
    ) {
        cbe = new CutbitElement(new Geom(x, 0, this.ylg, this.ylg, From.LEFT),
            Spritesheet.infoBarIcons.toCutbitFor(Style.garden));
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
    string formatTargetDesc()
    in {
        assert (_targetDesc);
        assert (_numLixUnderCursor >= 0,
            format("_numLixUnderCursor == %d, not >= 0", _numLixUnderCursor));
        assert ((_numLixUnderCursor == 0) == (_highlitLix is null),
            format("_highlitLix %s, but _numLixUnderCursor == %d",
            _highlitLix ? "exists" : "null", _numLixUnderCursor));
    }
    do {
        if (_numLixUnderCursor >= 1) {
            return formatTargetDescLix();
        }
        else if (_hoveredGadget.length >= 1) {
            return _hoveredGadget;
        }
        return formatExtraDesc();
    }

    string formatTargetDescLix()
    in {
        assert (_highlitLix !is null);
        assert (_numLixUnderCursor >= 1);
    }
    do {
        string s = format!"%s %s %s"(
            Lang.tweakerHeaderLixID.transl,
            _highlitPassport.id,
            _highlitLix.ac.skillTransl.isPerforming);
        if (auto bc = cast (const BrickCounter) _highlitLix.constJob) {
            s ~= " [%d]".format(bc.skillsQueued * bc.bricksAtStart
                + bc.bricksLeft);
        }
        if (_numLixUnderCursor >= 2) {
            s ~= " ";
            s ~= _numLixUnderCursor == 2 ? Lang.gameInfobarPlus1Lix.transl
                : Lang.gameInfobarPlusNLix.translf(_numLixUnderCursor - 1);
        }
        s ~= ".";
        return s;
    }

    string formatFPS()
    {
        if (! opt.showFPS.value) {
            return "";
        }
        return "%s %d   FPS: %d".format(
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

    override string formatExtraDesc() { return ""; }
}

class InfoBarMultiplayer : InfoBar {
private:
    CutbitElement _bSaved; // same as in singleplayer. Abstract this sometime
    Label _lSaved;

    bool _tribeHasSpawnHandicap;
    Phyu _firstSpawn;

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
        _firstSpawn = tribe.firstSpawnIncludingHandicap;
        _tribeHasSpawnHandicap
            = (tribe.firstSpawnIncludingHandicap
            != tribe.firstSpawnWithoutHandicap);
        if (tribe.hasScored) {
            _bSaved.yf = 1; // greyed out. Maybe invent something better
            _lSaved.text = tribe.score.lixSaved.asText;
        }
    }

    override string formatExtraDesc()
    {
        if (! _tribeHasSpawnHandicap || _age >= _firstSpawn) {
            return "";
        }
        immutable int seconds
            = (_firstSpawn - _age + (glo.phyusPerSecondAtNormalSpeed - 1))
            / glo.phyusPerSecondAtNormalSpeed;
        return format("%s %d:%02d", Lang.netGameFirstSpawnIn.transl,
            seconds / 60, seconds % 60);
    }
}
