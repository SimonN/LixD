module menu.lastgame;

/*
 * Stats after playing a level, displayed below the preview instead
 * of a couple other stats that would normally show when you highlight a level
 * or replay in the browser.
 */

import std.algorithm;
import std.format;
import optional;

import basics.trophy;
import basics.globals;
import basics.globconf;
import basics.user : addToUser, getTrophy, replayLastLevel;
import file.filename;
import game.harvest;
import game.replay;
import graphic.color;
import gui;
import file.language;
import hardware.sound;
import level.level;

// This class has a strange name, it's also called from the replay browser,
// not only from the singleplayer browser.
class SingleplayerLastGameStats : LastGameStats {
private:
    Optional!Label _trophyUpdate;
    Optional!LabelTwo _goal;
    Optional!LabelTwo _youSaved;
    Label _autoReplayDesc;

public:
    this(Geom g, Harvest ha)
    in {
        assert (g.xl >= 120, "Stats need more space");
        assert (g.yl >= 60, "Stats need more space");
    }
    body {
        super(g, ha);
        _autoReplayDesc = new Label(new Geom(0, 40, xlg/2f, 20));
        addChild(_autoReplayDesc);
        if (! solved)
            return;

        _youSaved = () {
            auto ret = new LabelTwo(new Geom(0, 00, xlg/2f, 40),
                Lang.harvestYouSaved.transl);
            ret.value = format!"%d/%d"(lixSaved, level.initial);
            addChild(ret);
            return some(ret);
        }();
        _trophyUpdate = () {
            auto ret = new Label(new Geom(xlg/2f, 00, xlg/2f, 20));
            addChild(ret);
            return some(ret);
        }();
        _goal = () {
            auto ret = new LabelTwo(new Geom(0, 20, xlg, 40),
                Lang.harvestYouNeeded.transl);
            ret.value = format!"%d/%d"(level.required, level.initial);
            addChild(ret);
            return some(ret);
        }();
        saveTrophy();
        if (saveAutoReplay())
            _autoReplayDesc.text = Lang.harvestReplayAutoSaved.transl;
    }

    bool isOnlyFinalRowShown() const
    {
        return _goal.empty && _youSaved.empty && _trophyUpdate.empty;
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

    override bool saveAutoReplay() const
    {
        if (_harvest.replay.numPlayers > 1) {
            // This is the subclass of LastGameStats for singleplayer.
            // This is also called after watching a saved netgame replay.
            // Never save those playbacks again.
            return false;
        }
        const(Replay) old = Replay.loadFromFile(replayLastLevel);
        if (old == _harvest.replay)
            return false;

        replay.saveAsAutoReplay(level);
        return replay.shouldWeAutoSave;
    }

    override void onFirstTrophy()
    {
        _trophyUpdate.unwrap.text(Lang.harvestTrophyFirst.transl);
    }

    override void onRestoredTrophy()
    {
        _trophyUpdate.unwrap.text = Lang.harvestTrophyBuiltReset.transl;
    }

    override void onImprovedTrophy()
    {
        _trophyUpdate.unwrap.text = Lang.harvestTrophyImproved.transl;
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
            _doneSavingManually.text = replay.manualSaveFilename.rootless;
            playQuiet(Sound.DISKSAVE);
        };
        addChildren(_saveManually, _doneSavingManually);
    }

    @property const @nogc nothrow {
        const(Level) level() { return _harvest.level; }
        const(Replay) replay() { return _harvest.replay; }
        int lixSaved() { return _harvest.trophy.lixSaved; }
        bool solved() {
            return _harvest.trophy.lixSaved >= _harvest.level.required;
        }
    }

protected:
    abstract bool saveAutoReplay() const; // returns whether we really saved

    // Override these to react to the result of saving the trophy
    void onFirstTrophy() { }
    void onRestoredTrophy() { }
    void onImprovedTrophy() { }

    final void saveTrophy()
    {
        if (! _harvest.maySaveTrophy || replay.levelFilename.empty
            || replay.players.length != 1
            || replay.players.byValue.front.name != basics.globconf.userName)
            return;

        auto lfn = *replay.levelFilename.unwrap;
        Optional!Trophy old = getTrophy(lfn);
        if (! _harvest.trophy.addToUser(lfn))
            return;

        if (old.empty)
            onFirstTrophy();
        else if (! privateEqual(level.built, old.unwrap.built))
            onRestoredTrophy();
        else
            onImprovedTrophy();
    }
}

private:

// Work around Phobos 18615: Rebindable!_Date doesn't use _Date.opEquals.
// Date is immutable(_Date) and MutableDate is Rebindable!Date.
import file.date;
bool privateEqual(Date a, Date b) { return a == b; }

unittest {
    Optional!Trophy old = Trophy("2000-01-01", 1, 2, 3);
    Level level = new Level();
    level.built = new Date("2000-01-01");
    assert (privateEqual(level.built, old.unwrap.built),
        "should be equal if we explicitly compare two Dates, even"
        ~ " when one is Rebindable!_Date.");
}
