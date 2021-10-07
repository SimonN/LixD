module menu.outcome.repsave;

/*
 * Replay-saving decisions and feedback for the GUI in menu.outcome.single.
 */

import optional;

import glo = file.option.allopts;
import file.language;
import file.replay;
import file.trophy;
import gui;
import hardware.sound;
import level.level;

class ReplaySaver : Element {
private:
    const(Level) _oldLevel;
    const(Replay) _theReplay;
    const(Trophy) _trophy;
    Optional!(const Replay) _loadedBeforePlay; // autosave only if different

    TextButton _saveManually;
    Label _doneAutosaving;
    Label _doneSavingManually;

public:
    this(
        Geom g,
        const(Level) oldLevel,
        const(Replay) theReplay,
        in Trophy tro,
        Optional!(const Replay) loadedBeforePlay,
    ) {
        super(g);
        _oldLevel = oldLevel;
        _theReplay = theReplay;
        _trophy = tro;

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
        if (! _theReplay.wasPlayedBy(glo.userName)) {
            return false;
        }
        if (_theReplay.numPlayers == 1) {
            return _trophy.lixSaved >= _oldLevel.required
                && glo.replayAutoSolutions.value
                && _theReplay != _loadedBeforePlay;
        }
        return glo.replayAutoMulti.value;
    }

    void maybeAutoSave() const
    {
        if (! shouldWeAutoSave) {
            return;
        }
        _theReplay.saveAsAutoReplay(_oldLevel);
    }

    void onSavingManually()
    {
        const fn = _theReplay.manualSaveFilename;
        // We abuse _doneAutosaving because it's immediately above our line
        _doneAutosaving.text = fn.dirRootless;
        _doneAutosaving.undrawBeforeDraw = true;
        _doneSavingManually.text = fn.file;

        _theReplay.saveManually(_oldLevel);
        _saveManually.hide();
        _doneSavingManually.show();
        playQuiet(Sound.DISKSAVE);
    }
}
