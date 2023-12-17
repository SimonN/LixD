module menu.outcome.repsave;

/*
 * Replay-saving decisions and feedback for the GUI in menu.outcome.single.
 */

import optional;

import opt = file.option.allopts;
import file.language;
import file.replay;
import file.trophy;
import game.argscrea;
import gui;
import hardware.sound;

class ReplaySaver : Element {
private:
    const(ArgsToCreateGame) _previous;
    const(Replay) _theReplay;
    const(Trophy) _trophy;

    TextButton _saveManually;
    Label _doneAutosaving;
    Label _doneSavingManually;

public:
    this(
        Geom g,
        const(ArgsToCreateGame) previous,
        const(Replay) theReplay,
        in Trophy tro,
    ) {
        super(g);
        _previous = previous;
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
        _saveManually.hotkey = opt.keyOutcomeSaveReplay.value;
        addChild(_saveManually);
    }

private:
    bool shouldWeAutoSave() const
    {
        if (! _theReplay.wasPlayedBy(opt.userName)) {
            return false;
        }
        if (_theReplay.numPlayers == 1) {
            return _trophy.lixSaved >= _previous.level.required
                && opt.replayAutoSolutions.value
                && (_previous.loadedReplay.empty
                    || _previous.loadedReplay.front != _theReplay);
        }
        return false;
        /*
         * This is the singleplayer replay-saving functionality.
         * Don't return opt.replayAutoMulti.value.
         */
    }

    void maybeAutoSave() const
    {
        if (! shouldWeAutoSave) {
            return;
        }
        _theReplay.saveAsAutoReplay(_previous.level);
    }

    void onSavingManually()
    {
        const fn = _theReplay.manualSaveFilename;
        // We abuse _doneAutosaving because it's immediately above our line
        _doneAutosaving.text = fn.dirRootless;
        _doneAutosaving.undrawBeforeDraw = true;
        _doneSavingManually.text = fn.file;

        _theReplay.saveManually(_previous.level);
        _saveManually.hide();
        _doneSavingManually.show();
        playQuiet(Sound.DISKSAVE);
    }
}
