module game.panel.base;

/* Panel: A large GUI element that features all the visible buttons
 * during gameplay.
 *
 * Some methods don't do anything depending on View.
 */

import std.algorithm;
import std.range;

import opt = file.option.allopts;
import game.core.view;
import game.panel.infobar;
import game.panel.livenote;
import game.panel.rightbut;
import game.panel.skillbar;
import game.panel.tooltip;
import physics.gadget;
import gui;
import net.phyu;
import physics.lixxie.lixxie;
import physics.lixxie.fields;
import physics.tribe;

class Panel : Element, TooltipSuggester {
private:
    SkillBar _skillbar;
    InfoBar stats;
    RightButtons _rb;

public:
    /*
     * After you create this, add names for the multiplayer score board.
     * lixRequired is ignored for multiplayer games.
     */
    this(in View view, in int lixRequired)
    {
        super(new Geom(0, 0, gui.screenXlg, gui.panelYlg, From.BOTTOM));
        _skillbar = new SkillBar(new Geom(0, 0, skillBarXl, ylg - 20,
            From.BOTTOM_LEFT), view);
        addChild(_skillbar);
        {
            auto statsGeom = new Geom(0, 0, statsBarXl(), 20);
            stats = view.showTapeRecorderButtons && ! view.showScoreGraph
                ? new InfoBarSingleplayer(statsGeom, lixRequired)
                : new InfoBarMultiplayer(statsGeom);
        }
        addChild(stats);
        {
            auto rbGeom = new Geom(0, 0, xlg - stats.xlg, ylg, From.TOP_RIGHT);
            _rb = (view.showTapeRecorderButtons && view.showScoreGraph)
                ? new BattleReplayRightButtons(rbGeom)
                : view.showTapeRecorderButtons
                ? new SinglePlayerRightButtons(rbGeom,
                    LivestreamNote.readUserFile)
                /*
                 * This is the branch for (yes score graph, no tape recorder).
                 * Hack: Even if neither score graph or trbs shown, still
                 * enter this branch: Show the score graph to fill the void.
                 */
                : new BattleRightButtons(rbGeom);
        }
        addChild(_rb);
    }

    // Copy-pasted function names from RightButtons.
    static foreach (field; ["paused", "speedIsNormal", "speedIsFast",
        "speedIsTurbo", "restart", "saveState", "loadState",
        "rewindPrevPly", "rewindOneSecond", "rewindOneTick",
        "skipOneTick", "skipTenSeconds",
        "splatRulerIsOn", "tweakerIsOn",
        "highlightGoalsExecute", "nukeDoubleclicked"]
    ) {
        import std.format;
        mixin("const bool %s() { return _rb.%s(); }".format(field, field));
    }
    auto nuke() inout { return _rb.nuke; }
    void setSpeedNormal() { _rb.setSpeedNormal(); }
    void pause(bool b) { _rb.pause = b; }
    void ourStyle(in Style st) { _rb.ourStyle = st; }
    void update(in Score sco) { _rb.update = sco; }
    void add(in Style style, in string name) { _rb.add(style, name); }

    // call this from the Game
    void show(
        in Phyu now,
        in Tribe tr,
        in Ac ploderToDisplay,
        in bool overtimeRunning,
        in int overtimeRemainingInPhyus)
    in { assert (tr); }
    do {
        immutable bool multiNuking = tr.style != Style.garden
            && overtimeRunning && overtimeRemainingInPhyus == 0;
        _skillbar.setLikeTribe(tr, ploderToDisplay);
        if (multiNuking) {
            // Eye candy, to clarify that nobody can do anything more.
            _skillbar.setAllSkillsToZero();
        }
        nuke.on = tr.hasNuked || multiNuking;
        nuke.overtimeRunning = overtimeRunning;
        nuke.overtimeRemainingInPhyus = overtimeRemainingInPhyus;
        _rb.ourStyle = tr.style;
        stats.show(now, tr);
    }

    // Can return null. Should refactor to Optional!SkillButton.
    inout(SkillButton) chosenSkillButtonOrNull() inout pure nothrow @safe @nogc
    {
        return _skillbar.currentSkillOrNull;
    }

    Ac chosenSkill() const pure nothrow @safe @nogc
    {
        const(SkillButton) b = chosenSkillButtonOrNull();
        return b is null ? Ac.nothing : b.skill;
    }

    void chooseLeftmostSkill() nothrow @safe
    {
        _skillbar.chooseLeftmostSkill();
    }

    void describeNoLixxie() { stats.describeNoLixxie(); }
    void describeLixxie(in Lixxie l, in Passport p, int numUnderCursor)
    {
        stats.describeLixxie(l, p, numUnderCursor);
    }

    void describeNoGadget() { stats.describeNoGadget(); }
    void describeGadget(in Phyu now, in Tribe viewer, const(Gadget) gad)
    {
        stats.describeGadget(now, viewer, gad);
    }

    const nothrow @safe @nogc {
        bool isSuggestingTooltip() { return _rb.isSuggestingTooltip; }
        Tooltip.ID suggestedTooltip() { return _rb.suggestedTooltip; }
        Ac hoveredSkillOnlyForTooltip() { return _skillbar.hoveredSkill(); }
    }

private:
    float oneSkillXl() const nothrow @safe @nogc
    {
        return xlg / (opt.skillSort.length + 4);
    }

    float statsBarXl() const nothrow @safe @nogc
    {
        return xlg - (oneSkillXl * 4f);
    }

    float skillBarXl() const nothrow @safe @nogc
    {
        return oneSkillXl * opt.skillSort.length;
    }
}
