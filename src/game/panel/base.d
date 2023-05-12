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
import game.panel.tooltip;
import game.panel.rightbut;
import gui;
import hardware.sound;
import lix; // forward method of InfoBar to our users
import net.phyu;
import physics.tribe;

class Panel : Element, TooltipSuggester {
private:
    SkillButton[] _skills;
    SkillButton lastOnForRestoringAfterStateLoad;

    InfoBar stats;
    RightButtons _rb;

public:
    /*
     * After you create this, add names for the multiplayer score board.
     * lixRequired is ignored for multiplayer games.
     */
    this(in View aView, in int lixRequired)
    {
        super(new Geom(0, 0, gui.screenXlg, gui.panelYlg, From.BOTTOM));
        _skills.length = opt.skillSort.length;
        foreach (int id, ac; opt.skillSort) {
            _skills[id] = new SkillButton(new Geom(id * skillXl, 0,
                                     skillXl, skillYl, From.BOTTOM_LEFT));
            _skills[id].skill = ac;
            _skills[id].hotkey = opt.keySkill[opt.skillSort[id]].value;
            addChild(_skills[id]);
        }
        {
            auto barGeom = new Geom(0, 0, xlg - 4 * skillXl, ylg - skillYl);
            stats = aView.showTapeRecorderButtons && ! aView.showScoreGraph
                ? new InfoBarSingleplayer(barGeom, lixRequired)
                : new InfoBarMultiplayer(barGeom);
        }
        addChild(stats);
        {
            /*
             * [1] We don't have SaveStateButtons in this mode to preserve UI
             * space, and we don't have cool shades to preserve space.
             *
             * [3] This is the branch for (yes score graph, no tape recorder).
             * Hack: Even if neither score graph or trbs shown, still
             * enter this branch: Show the score graph to fill the void.
             */
            auto rbGeom = new Geom(0, 0, xlg - stats.xlg, ylg, From.TOP_RIGHT);
            _rb = (aView.showTapeRecorderButtons && aView.showScoreGraph)
                ? new BattleReplayRightButtons(rbGeom) // [1]
                : aView.showTapeRecorderButtons
                ? new SinglePlayerRightButtons(rbGeom)
                : new BattleRightButtons(rbGeom); // [3]
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
        foreach (b; _skills) {
            b.style = tr.style;
            if (b.skill.isPloder)
                b.skill = ploderToDisplay;
            // Skill buttons shouldn't show any skills left when we're nuking,
            // even though we still haven't used all skills yet.
            b.number = tr.hasNuked || multiNuking ? 0 : tr.usesLeft(b.skill);
        }
        nuke.on = tr.hasNuked || multiNuking;
        nuke.overtimeRunning = overtimeRunning;
        nuke.overtimeRemainingInPhyus = overtimeRemainingInPhyus;
        _rb.ourStyle = tr.style;
        makeCurrent(lastOnForRestoringAfterStateLoad);
    }

    void highlightFirstSkill()
    {
        assert (chosenSkillButtonOrNull is null);
        _skills.filter!(sk => sk.number != 0).takeOne.each!(
                                                (sk) { makeCurrent(sk); });
    }

    Ac chosenSkill() const
    {
        const(SkillButton) b = chosenSkillButtonOrNull();
        return b is null ? Ac.nothing : b.skill;
    }

    inout(SkillButton) chosenSkillButtonOrNull() inout
    {
        foreach (b; _skills)
            if (b.on && b.skill != Ac.nothing && b.number != 0)
                return b;
        return null;
    }

    void describeTarget(in Lixxie l, int nr) { stats.describeTarget(l, nr); }
    void showInfo(in Tribe tr) { stats.showTribe(tr); }
    void dontShowSpawnInterval() { stats.dontShowSpawnInterval(); }
    void showSpawnInterval(in int si) { stats.showSpawnInterval(si); }

    Phyu age(in Phyu phyu) { return stats.age = phyu; }

    bool isSuggestingTooltip() const { return _rb.isSuggestingTooltip; }
    Tooltip.ID suggestedTooltip() const { return _rb.suggestedTooltip; }
    Ac hoveredSkillOnlyForTooltip() const
    {
        foreach (sk; _skills.filter!(sk => sk.isMouseHere)) {
            return sk.skill;
        }
        return Ac.nothing;
    }


protected:
    override void calcSelf()
    {
        SkillButton oldSkill = chosenSkillButtonOrNull();
        _skills.filter!(sk => sk.execute && sk != oldSkill)
               .filter!(sk => sk.number != 0 || sk.hotkey.keyTapped).each!((sk)
        {
            makeCurrent(sk);
            if (sk.number != 0)
                hardware.sound.playLoud(Sound.PANEL);
            else
                hardware.sound.playQuiet(Sound.PANEL_EMPTY);
        });
    }

private:
    float skillYl() const { return this.geom.ylg - 20; }
    float skillXl() const { return gui.screenXlg / (opt.skillSort.length+4); }

    void makeCurrent(SkillButton skill)
    {
        if (chosenSkillButtonOrNull !is null)
            chosenSkillButtonOrNull.on = false;
        if (skill && skill.number != 0)
            skill.on = true;
        lastOnForRestoringAfterStateLoad = skill; // even if currently 0
    }
}
