module menu.outcome.repsave;

/*
 * Replay-saving decisions and feedback for the GUI in menu.outcome.single.
 */

static import file.option.allopts;
import file.replay;
import gui;

class ReplaySaver : Element {
private:
    Replay _replay;

    TextButton _saveManually;
    Label _doneAutosaving;
    Label _doneSavingManually;

public:
    this(Geom g, Replay rep)
    {
        super(g);
    }

private:
    bool shouldWeAutoSave() const
    {
        return _replay.numPlayers > 1
            ? file.option.allopts.replayAutoMulti.value
            : file.option.allopts.replayAutoSolutions.value;
    }
}
