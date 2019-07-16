module menu.lastgame;

/*
 * Stats after playing a level, displayed below the preview instead
 * of a couple other stats that would normally show when you highlight a level
 * or replay in the browser.
 */

import std.algorithm;
import std.format;
import optional;

import basics.globals;
import file.option;
import file.option : replayLastLevel;
import file.filename;
import file.trophy;
import game.harvest;
import file.replay;
import graphic.color;
import gui;
import file.language;
import hardware.sound;
import level.level;

class StatsAfterReplay : StatsAfterSingleplayer {
private:
    Optional!(const Replay) _lastLoaded;

public:
    this(Geom g, Harvest ha, Optional!(const Replay) lastLoaded)
    {
        _lastLoaded = lastLoaded;
        super(g, ha);
    }

protected:
    override bool maySaveAutoReplay() const
    {
        return super.maySaveAutoReplay() && _harvest.replay != _lastLoaded;
    }
}

class StatsAfterSingleplayer : StatsAfterGame {
private:
    Optional!Label _youSaved;
    Label _autoReplayDesc;

public:
    this(Geom g, Harvest ha)
    in {
        assert (g.xl >= 60, "Stats need more space");
        assert (g.yl >= 60, "Stats need more space");
    }
    body {
        super(g, ha);
        // Hack: In 640x480, the English text "Replay autosaved"
        // was shortened to "Replay autosave.". To remedy, give some geoms of
        // leeway both to the left and to the right outside of this's xlg.
        _autoReplayDesc = new Label(new Geom(0, 20, xlg+15, 20, From.TOP));
        addChild(_autoReplayDesc);
        if (! solved)
            return;

        _youSaved = () {
            auto ret = new Label(new Geom(0, 00, xlg, 40, From.TOP),
                Lang.harvestYouSavedThisTime.translf(lixSaved));
            addChild(ret);
            return some(ret);
        }();
        saveTrophy();
        if (saveAutoReplay()) {
            _autoReplayDesc.text = Lang.harvestReplayAutoSaved.transl;
            saveManuallyText = Lang.harvestReplaySaveManuallyToo.transl;
        }
    }

    bool isOnlyFinalRowShown() const { return _youSaved.empty; }

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

    override bool maySaveAutoReplay() const
    {
        // This is the subclass of LastGameStats for singleplayer.
        // This is also called after watching a saved netgame replay (bad OO).
        // Never save those playbacks again.
        return _harvest.replay.numPlayers == 1
            // Don't autosave other people's singleplayer solutions again.
            && _harvest.replay.players.byValue.front.name == userName;
    }
}

abstract class StatsAfterGame : Element {
private:
    TextButton _saveManually;
    Label _doneSavingManually;
    Harvest _harvest; // We take ownership of last game's level and replay.

public:
    /*
     * This delegate will be called back after the replay has been saved
     * manually. It will be called with argument Filename = the filename
     * of the manually-saved replay.
     */
    void delegate(Filename) onSavingManually = null; // may remain null

    this(Geom g, Harvest ha)
    {
        super(g);
        _harvest = ha;
        {
            Geom newG() { return new Geom(0, 0, xlg, 20, From.BOT_RIG); }
            _doneSavingManually = new Label(newG());
            _saveManually = new TextButton(newG(),
                Lang.harvestReplaySaveManuallyAtAll.transl);
        }
        _doneSavingManually.hide();
        _saveManually.onExecute = () {
            replay.saveManually(level);
            _saveManually.hide();
            _doneSavingManually.show();
            _doneSavingManually.text = replay.manualSaveFilename.rootless;
            playQuiet(Sound.DISKSAVE);
            if (onSavingManually !is null) {
                onSavingManually(replay.manualSaveFilename);
            }
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
    abstract bool maySaveAutoReplay() const;

    final void saveTrophy()
    {
        if (replay.players.length != 1
            || replay.players.byValue.front.name != file.option.userName)
            return;
        maybeImprove(_harvest.trophyKey, _harvest.trophy);
    }

    // Returns whether the Replay class decided to save.
    final bool saveAutoReplay() const
    {
        if (! maySaveAutoReplay())
            return false;
        replay.saveAsAutoReplay(level);
        return replay.shouldWeAutoSave;
    }

    @property string saveManuallyText(string s)
    {
        return _saveManually.text = s;
    }
}

private:

// Work around Phobos 18615: Rebindable!_Date doesn't use _Date.opEquals.
// Date is immutable(_Date) and MutableDate is Rebindable!Date.
import file.date;
bool privateEqual(Date a, Date b) { return a == b; }

unittest {
    Optional!Trophy old = Trophy(new Date("2000-01-01"),
        new VfsFilename("./levels/a.txt"));
    Level level = new Level();
    level.built = new Date("2000-01-01");
    assert (privateEqual(level.built, old.unwrap.built),
        "should be equal if we explicitly compare two Dates, even"
        ~ " when one is Rebindable!_Date.");
}
