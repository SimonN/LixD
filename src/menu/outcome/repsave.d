module menu.outcome.repsave;

/*
 * Replay-saving decisions and feedback for the GUI in menu.outcome.single.
 */

import glo = file.option.allopts;
import game.harvest;
import file.language;
import hardware.sound;
import gui;

class ReplaySaver : Element {
private:
    const(Harvest) _harvest;

    TextButton _saveManually;
    Label _doneAutosaving;
    Label _doneSavingManually;

public:
    this(Geom g, const(Harvest) harv)
    {
        super(g);
        _harvest = harv;

        maybeAutoSave();
        _doneAutosaving = new Label(new Geom(0, 0, xlg, ylg/2, From.TOP),
            shouldWeAutoSave ? Lang.harvestReplayAutoSaved.transl : "");
        addChild(_doneAutosaving);

        _doneSavingManually = new Label(
            new Geom(0, ylg/2, xlg, ylg/2, From.TOP));
        _doneSavingManually.hide();
        addChild(_doneSavingManually);

        _saveManually = new TextButton(new Geom(_doneSavingManually.geom),
            shouldWeAutoSave
                ? Lang.harvestReplaySaveManuallyToo.transl
                : Lang.harvestReplaySaveManuallyAtAll.transl);
        _saveManually.onExecute = () { onSavingManually(); };
        addChild(_saveManually);
    }

private:
    bool shouldWeAutoSave() const
    {
        if (! _harvest.replay.wasPlayedBy(glo.userName)) {
            return false;
        }
        if (_harvest.replay.numPlayers == 1) {
            return _harvest.singleplayerHasWon
                && glo.replayAutoSolutions.value;
        }
        return glo.replayAutoMulti.value;
    }

    void maybeAutoSave() const
    {
        if (! shouldWeAutoSave) {
            return;
        }
        _harvest.replay.saveAsAutoReplay(_harvest.level);
    }

    void onSavingManually()
    {
        const fn = _harvest.replay.manualSaveFilename;
        // We abuse _doneAutosaving because it's immediately above our line
        _doneAutosaving.text = fn.dirRootless;
        _doneAutosaving.undrawBeforeDraw = true;
        _doneSavingManually.text = fn.file;

        _harvest.replay.saveManually(_harvest.level);
        _saveManually.hide();
        _doneSavingManually.show();
        playQuiet(Sound.DISKSAVE);
    }
}
