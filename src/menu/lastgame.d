module menu.lastgame;

/*
 * Stats after playing a level, displayed instead of the preview.
 */

import std.format;
import optional;

import basics.trophy;
import basics.globals;
import basics.user : addToUser, getTrophy;
import file.filename;
import game.harvest;
import game.replay;
import graphic.color;
import gui;
import file.language;
import hardware.sound;
import level.level;

class SingleplayerLastGameStats : LastGameStats {
private:
    Optional!Label _fraction;
    Optional!Label _trophyUpdate;
    Label _autoReplayDesc;

public:
    this(Geom g, Harvest ha)
    in {
        assert (g.xl >= 120, "Stats need more space");
        assert (g.yl >= 60, "Stats need more space");
    }
    body {
        super(g, ha);
        _autoReplayDesc = new Label(new Geom(0, 40, xlg/2f, 20),
            Lang.harvestReplayAutoNotSaved.transl);
        addChild(_autoReplayDesc);
        auto tro = trophy.unwrap;
        if (! tro || tro.lixSaved < level.required)
            return;

        _fraction = some(new Label(new Geom(0, 00, xlg, 40)));
        _trophyUpdate = some(new Label(new Geom(0, 20, xlg, 20)));
        addChildren(_fraction.unwrap, _trophyUpdate.unwrap);

        _fraction.unwrap.text = formatWinnerText(*tro);
        _fraction.unwrap.color = color.white;
        saveTrophy(*tro);
        if (saveAutoReplay())
            _autoReplayDesc.text = Lang.harvestReplayAutoSaved.transl;
    }

    bool isOnlyFinalRowShown() const
    {
        return _fraction.empty && _trophyUpdate.empty;
    }

protected:
    /*
     * undrawSelf: Explicitly undraw _autoReplayDesc and the manual button.
     * (Normally, undrawing doesn't loop over children because painting over
     * the (parent == this) is enough. This override doesn't paint over this.)
     * Reason: Work around a drawing order curiosity in the singleplayer
     * browser. For that movement to work, we need y-alignment
     * from the top. The curiosity is: First, singleplayerbrowser's
     * labels will be drawn, then we will be undrawn. We should not
     * paint over the labels that have already been drawn, but we
     * must paint over our own buttons.
     */
    override void undrawSelf()
    {
        foreach (ch; children)
            ch.undraw();
    }

private:
    void saveTrophy(Trophy tro) { with (Trophy.Cmp)
    {
        Filename lfn = replay.levelFilename;
        if (! lfn)
            return;
        const old = getTrophy(lfn);
        const bool addResult = tro.addToUser(lfn);
        if (old.empty)
            _trophyUpdate.unwrap.text = Lang.harvestTrophyFirst.transl;
        else if (tro.shouldReplace(*old.unwrap) == yesSameBuildBetterPlay)
            _trophyUpdate.unwrap.text = Lang.harvestTrophyImproved.transl;
        else if (tro.shouldReplace(*old.unwrap) != noSameBuildWorsePlay)
            _trophyUpdate.unwrap.text = Lang.harvestTrophyBuiltReset.transl;
    }}

    string formatWinnerText(Trophy tro) const
    {
        try {
            return format(Lang.harvestYouSavedEnough.transl,
                tro.lixSaved, level.initial);
        }
        catch (FormatException e)
            return format!"Saved %d, needed %d/%d"(
                tro.lixSaved, level.required, level.initial);
    }
}

abstract class LastGameStats : Element {
private:
    TextButton _saveManually;
    Label _doneSavingManually;
    Harvest _harvest; // We take ownership of last game's level and replay.

public:
    this(Geom g, Harvest ha)
    {
        super(g);
        _harvest = ha;
        {
            Geom newG() { return new Geom(0, 0, xlg/2f, 20, From.BOT_RIG); }
            _doneSavingManually = new Label(newG());
            _saveManually = new TextButton(newG(),
                Lang.harvestReplaySaveManually.transl);
        }
        _doneSavingManually.hide();
        _saveManually.onExecute = () {
            replay.saveManually(level);
            _saveManually.hide();
            _doneSavingManually.show();
            _doneSavingManually.text =
                replay.manualSaveFilename(level).rootless;
            playQuiet(Sound.DISKSAVE);
        };
        addChildren(_saveManually, _doneSavingManually);
    }

    @property const @nogc nothrow {
        const(Level) level() { return _harvest.level; }
        const(Replay) replay() { return _harvest.replay; }
    }

protected:
    inout(Optional!Trophy) trophy() inout nothrow
    {
        return _harvest.trophy;
    }

    bool saveAutoReplay() const // returns whether we really saved
    {
        if (! _harvest.autoReplayAllowed)
            return false;
        replay.saveAsAutoReplay(level);
        return replay.shouldWeAutoSave;
    }
}
