module game.panel.rightbut;

/*
 * The part of the panel that is to the right of skill buttons.
 * This is everything of the panel except for skill buttons and the info bar.
 */

import std.algorithm;

import file.option;
import game.core.view;
import game.panel.nuke;
import game.panel.taperec;
import game.panel.tooltip;
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

    const @property {
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
        bool replayEditorIsOn() { return false; }
        bool highlightGoalsExecute() { return false; }
        bool zoomIn() { return false; }
        bool zoomOut() { return false; }
    }

    final @property bool nukeDoubleclicked() const
    {
        return nuke.doubleclicked;
    }

    final @property bool isSuggestingTooltip() const
    {
        return _suggesters.any!(sug => sug.isSuggestingTooltip);
    }

    final @property Tooltip.ID suggestedTooltip() const
    {
        // TooltipSuggester's contract requires that front exists here:
        return _suggesters.filter!(sug => sug.isSuggestingTooltip)
            .front.suggestedTooltip;
    }

    void setSpeedNormal() {}
    void pause(bool b) {}

    @property void ourStyle(in Style) {}
    void update(in Score) {}
    void add(Style style, string name) {}

protected:
    void addSuggester(const(TooltipSuggester) sug)
    in { assert (! _suggesters.canFind(sug), "Don't add a suggester twice."); }
    body { _suggesters ~= sug; }

    @property float skillXl() const { return this.geom.xlg / 4f; }
    @property float skillYl() const { return this.geom.ylg - 20f; }
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
        immutable float butYl = ylg - skillYl;
        makeGraphWithYl(ylg - butYl);

        makeSplatRuler(new Geom(0, 0, skillXl, butYl, From.BOT_RIG));
        _highlightGoals = new HighlightGoalsButton(
            new Geom(skillXl, 0, skillXl, butYl, From.BOT_RIG));
        addChild(_highlightGoals);
        addSuggester(_highlightGoals);

        _nukeMulti = new NukeButton(
            new Geom(2 * skillXl, 0, 2 * skillXl, butYl, From.BOT_RIG),
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
    SaveStateButtons _ssbs;

    mixin SplatRulerMixin;

public:
    this(Geom g)
    {
        super(g);
        auto shadesGeom = new Geom(0, 0, skillXl, ylg - skillYl,
            From.TOP_RIGHT);

        _ssbs = new SaveStateButtons(new Geom(shadesGeom.xlg, 0,
            4 * skillXl - shadesGeom.xlg, ylg - skillYl, From.TOP_RIGHT));
        addChild(_ssbs);
        addSuggester(_ssbs);
        makeTapeRecorderWithYl(skillYl);
        makeSplatRuler(shadesGeom);
    }

    override const @property {
        bool saveState() { return _ssbs.saveState; }
        bool loadState() { return _ssbs.loadState; }
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
        makeTapeRecorderWithYl(tapeYlg);
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

    public override const @property {
        bool paused()             { return _trbs.paused; }
        bool speedIsNormal()      { return _trbs.speedIsNormal; }
        bool speedIsFast()        { return _trbs.speedIsFast; }
        bool speedIsTurbo()       { return _trbs.speedIsTurbo; }
        bool restart()            { return _trbs.restart; }
        bool framestepBackOne()   { return _trbs.framestepBackOne; }
        bool framestepBackMany()  { return _trbs.framestepBackMany; }
        bool framestepAheadOne()  { return _trbs.framestepAheadOne; }
        bool framestepAheadMany() { return _trbs.framestepAheadMany; }
        bool zoomIn()             { return _trbs.zoomIn; }
        bool zoomOut()            { return _trbs.zoomOut; }
    }

    private void makeTapeRecorderWithYl(in float tapeYlg)
    {
        _trbs = new TapeRecorderButtons(new Geom(
            0, 0, 4 * skillXl, tapeYlg, From.BOTTOM_RIGHT));
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

    public override @property void ourStyle(in Style st)
    {
        _scoreGraph.ourStyle = st;
        _scoreBoard.ourStyle = st;
    }

    public override @property void update(in Score score)
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
            new Geom(0, 0, 4 * skillXl, graphYl, From.TOP_RIGHT));
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
    private SplatRulerButton _splatRuler;

    private void makeSplatRuler(Geom g)
    {
        _splatRuler = new SplatRulerButton(g);
        addChild(_splatRuler);
        addSuggester(_splatRuler);
    }

    public override const @property {
        bool splatRulerIsOn() { return _splatRuler.on; }
    }
}
