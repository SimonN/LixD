module game.panel.rightbut;

/*
 * The part of the panel that is to the right of skill buttons.
 * This is everything of the panel except for skill buttons and the info bar.
 */

import std.algorithm;

import opt = file.option.allopts;
import game.core.view;
import game.panel.nuke;
import game.panel.taperec;
import game.panel.tooltip;
import game.panel.savestat;
import graphic.internal;
import gui;
import hardware.sound;

abstract class RightButtons : Element, TooltipSuggester {
private:
    // Subclasses should register tooltip suggesters here with addSuggester.
    const(TooltipSuggester)[] _suggesters;

public:
    this(Geom g) { super(g); }

    abstract inout(NukeButton) nuke() inout;

    const {
        bool paused() { return false; }
        bool speedIsNormal() { return true; }
        bool speedIsFast() { return false; }
        bool speedIsTurbo() { return false; }
        bool restart() { return false; }
        bool saveState() { return false; }
        bool loadState() { return false; }
        bool framestepBackOne() { return false; }
        bool framestepBackMany() { return false; }
        bool framestepAheadOne() { return false; }
        bool framestepAheadMany() { return false; }

        bool splatRulerIsOn() { return false; }
        bool tweakerIsOn() { return false; }
        bool highlightGoalsExecute() { return false; }
    }

    final bool nukeDoubleclicked() const
    {
        return nuke.doubleclicked;
    }

    final bool isSuggestingTooltip() const
    {
        return _suggesters.any!(sug => sug.isSuggestingTooltip);
    }

    final Tooltip.ID suggestedTooltip() const
    {
        // TooltipSuggester's contract requires that front exists here:
        return _suggesters.filter!(sug => sug.isSuggestingTooltip)
            .front.suggestedTooltip;
    }

    void setSpeedNormal() {}
    void pause(bool b) {}

    void ourStyle(in Style) {}
    void update(in Score) {}
    void add(Style style, string name) {}

protected:
    void addSuggester(const(TooltipSuggester) sug)
    in { assert (! _suggesters.canFind(sug), "Don't add a suggester twice."); }
    do { _suggesters ~= sug; }

    float skillYl() const pure nothrow @safe @nogc { return geom.ylg - 20f; }
    float topRowYl() const pure nothrow @safe @nogc { return 20f; }
}

// ############################################################################
// ################################################# Subclasses of RightButtons
// ############################################################################

class BattleRightButtons : RightButtons {
private:
    NukeButton _nukeMulti;
    HighlightGoalsButton _highlightGoals;

    mixin ScoreMixin;
    mixin SplatRulerMixin;

public:
    this(Geom g)
    {
        super(g);
        immutable float butXl = xlg / 4f;
        makeGraphWithYl(skillYl);

        makeSplatRuler(new Geom(0, 0, butXl, topRowYl, From.BOT_RIG));
        _highlightGoals = new HighlightGoalsButton(
            new Geom(butXl, 0, butXl, topRowYl, From.BOT_RIG));
        addChild(_highlightGoals);
        addSuggester(_highlightGoals);

        _nukeMulti = new NukeButton(
            new Geom(0, 0, 2 * butXl, topRowYl, From.BOTTOM_LEFT),
            NukeButton.WithTimeLabel.yes);
        addChild(_nukeMulti);
        addSuggester(_nukeMulti);
    }

    override inout(NukeButton) nuke() inout { return _nukeMulti; }
    override bool highlightGoalsExecute() const
    {
        return _highlightGoals.execute;
    }

protected:
    override void calcSelf()
    {
        showOrHideScoreBoard();
    }
}

class SinglePlayerRightButtons : RightButtons {
private:
    mixin TapeRecorderMixin;
    mixin SplatRulerMixin;
    mixin TweakerMixin;
    mixin SaveStateMixin;

public:
    this(Geom g)
    {
        super(g);
        makeTapeRecorder(new Geom(0, 0, xlg, skillYl, From.BOTTOM));
        Geom mkGeom(in int nr, in int widthInButtons)
        {
            return new Geom(nr * (xlg / 4f), 0,
                widthInButtons * xlg / 4f, topRowYl);
        }
        makeSaveState(mkGeom(0, 2));
        makeTweaker(mkGeom(2, 1));
        makeSplatRuler(mkGeom(3, 1));
    }
}

class BattleReplayRightButtons : RightButtons {
private:
    mixin TapeRecorderMixin;
    mixin ScoreMixin;

public:
    this(Geom g)
    {
        super(g);
        immutable tapeYlg = this.ylg * 0.6f;
        makeGraphWithYl(this.ylg - tapeYlg);
        makeTapeRecorder(new Geom(0, 0, xlg, tapeYlg, From.BOTTOM_LEFT));
    }

protected:
    override void calcSelf()
    {
        showOrHideScoreBoard();
    }
}

// ############################################################################
// Mixins ############################################################## Mixins
// ############################################################################

private:

/*
 * Usage:
 * Mix into a child class of RightButtons.
 * Call makeTapeRecorderWithYl(float) in that class's constructor.
 */
mixin template TapeRecorderMixin() {
    private TapeRecorderButtons _trbs; // contains singleplayer nuke

    public override inout(NukeButton) nuke() inout { return _trbs.nuke; }
    public override void setSpeedNormal() { _trbs.setSpeedNormal(); }
    public override void pause(bool b) { _trbs.pause(b); }

    public override const {
        bool paused()             { return _trbs.paused; }
        bool speedIsNormal()      { return _trbs.speedIsNormal; }
        bool speedIsFast()        { return _trbs.speedIsFast; }
        bool speedIsTurbo()       { return _trbs.speedIsTurbo; }
        bool restart()            { return _trbs.restart; }
        bool framestepBackOne()   { return _trbs.framestepBackOne; }
        bool framestepBackMany()  { return _trbs.framestepBackMany; }
        bool framestepAheadOne()  { return _trbs.framestepAheadOne; }
        bool framestepAheadMany() { return _trbs.framestepAheadMany; }
    }

    private void makeTapeRecorder(Geom g)
    {
        _trbs = new TapeRecorderButtons(g);
        addChild(_trbs);
        addSuggester(_trbs);
    }
}

/*
 * Usage:
 * Mix into a child class of RightButtons.
 * Call makeGraphWithYl(float) in that class's constructor.
 * Call showOrHideScoreBoard() in that class's calcSelf().
 */
mixin template ScoreMixin() {
    private ScoreGraph _scoreGraph;
    private ScoreBoard _scoreBoard; // Present but usually hidden.

    public override void ourStyle(in Style st)
    {
        _scoreGraph.ourStyle = st;
        _scoreBoard.ourStyle = st;
    }

    public override void update(in Score score)
    {
        _scoreGraph.update(score);
        _scoreBoard.update(score);
    }

    public override void add(Style style, string name)
    {
        _scoreBoard.add(style, name);
    }

    private void makeGraphWithYl(in float graphYl)
    {
        _scoreGraph = new ScoreGraph(
            new Geom(0, 0, xlg, graphYl, From.TOP_RIGHT));
        _scoreBoard = new ScoreBoardOn3DBackground(
            new Geom(0, this.ylg, 400, 100, From.BOTTOM_RIGHT));

        import graphic.color;
        _scoreBoard.undrawColor = color.transp;
        _scoreBoard.hide();
        addChild(_scoreGraph);
        addChild(_scoreBoard);
        showOrHideScoreBoard();
    }

    private void showOrHideScoreBoard()
    {
        if (! _scoreBoard.shown && _scoreGraph.isMouseHere)
            _scoreBoard.shown = true;
        else if (_scoreBoard.shown && ! _scoreGraph.isMouseHere) {
            _scoreBoard.shown = false;
            // This is a hack. Ideally, only _scoreBoard's rectangle
            // should be redrawn with transp, without blending.
            gui.requireCompleteRedraw();
        }
    }
}

/*
 * Usage:
 * Mix into a child class of RightButtons.
 * Call makeSplatRuler(Geom) in that class's constructor.
 */
mixin template SplatRulerMixin() {
    private ToggleableTooltipSuggestingButton _splatRuler;

    private void makeSplatRuler(Geom g)
    {
        _splatRuler = new ToggleableTooltipSuggestingButton(g,
            GamePanel2Xf.showSplatRuler,
            opt.keyShowSplatRuler.value,
            Tooltip.ID.showSplatRuler);
        addChild(_splatRuler);
        addSuggester(_splatRuler);
    }

    public override const {
        bool splatRulerIsOn() { return _splatRuler.on; }
    }
}

mixin template TweakerMixin() {
    private ToggleableTooltipSuggestingButton _tweaker;

    private void makeTweaker(Geom g)
    {
        _tweaker = new ToggleableTooltipSuggestingButton(g,
            GamePanel2Xf.showTweaker,
            opt.keyShowTweaker.value,
            Tooltip.ID.showTweaker);
        addChild(_tweaker);
        addSuggester(_tweaker);
    }

    public override const {
        bool tweakerIsOn() { return _tweaker.on; }
    }
}

mixin template SaveStateMixin() {
    private SaveStateButtons _saveStateButtons;

    private void makeSaveState(Geom g)
    {
        _saveStateButtons = new SaveStateButtons(g);
        addChild(_saveStateButtons);
        addSuggester(_saveStateButtons);
    }

    public override const pure nothrow @safe @nogc {
        bool loadState() { return _saveStateButtons.loadState; }
        bool saveState() { return _saveStateButtons.saveState; }
    }
}
