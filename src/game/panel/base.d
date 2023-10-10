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
import game.panel.rightbut;
import game.panel.skillbar;
import game.panel.tooltip;
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
            From.BOTTOM_LEFT));
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
                ? new SinglePlayerRightButtons(rbGeom)
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
        "framestepBackOne", "framestepBackMany", "framestepAheadOne",
        "framestepAheadMany", "splatRulerIsOn", "tweakerIsOn",
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
    void setLikeTribe(in Tribe tr, in Ac ploderToDisplay,
                      in bool overtimeRunning, in int overtimeRemainingInPhyus
    ) {
        if (tr is null)
            return;
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

    void describeTarget(in Lixxie l, in Passport p, int numUnderCursor)
    {
        stats.describeTarget(l, p, numUnderCursor);
    }

    void showInfo(in Tribe tr) { stats.showTribe(tr); }
    void dontShowSpawnInterval() { stats.dontShowSpawnInterval(); }
    void showSpawnInterval(in int si) { stats.showSpawnInterval(si); }
    void age(in Phyu phyu) { stats.age = phyu; }

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
