module editor.gui.constant;

import basics.user; // length of sorted skill array
import basics.globals;
import editor.gui.okcancel;
import file.language;
import gui;
import level.level;

class ConstantsWindow : OkCancelWindow {
private:
    NumPick _intendedNumberOfPlayers;
    NumPick _initial;
    NumPick _spawnint;
    NumPick _required;

public:
    this(Level level)
    {
        super(new Geom(0, 0, 400, 250, From.CENTER),
            Lang.winConstantsTitle.transl);
        enum butX   = 140;
        enum butXl  = 400 - butX - 20;
        enum textXl = 120;

        void label(in float y, in Lang cap)
        {
            addChild(new Label(new Geom(20, y, textXl, 20), cap.transl));
        }
        label( 30, Lang.winConstantsAuthor);
        label( 60, Lang.winConstantsLevelName);
        label( 90, Lang.winConstantsPlayers);
        label(120, Lang.winConstantsInitial);
        label(150, Lang.winConstantsRequired);
        label(180, Lang.winConstantsSpawnint);
        label(210, Lang.winConstantsOvertime);

        NumPickConfig cfg;
        cfg.digits = 1;
        cfg.min = 1;
        cfg.max = basics.globals.teamsPerLevelMax;
        _intendedNumberOfPlayers = new NumPick(new Geom(butX, 90, 120,20),cfg);
        _intendedNumberOfPlayers.number = level.intendedNumberOfPlayers;

        cfg.sixButtons = true;
        cfg.digits = 3;
        cfg.max = Level.initialMax;
        _initial  = new NumPick(new Geom(butX, 120, 160, 20), cfg);
        _required = new NumPick(new Geom(butX, 150, 160, 20), cfg);
        _initial .number = level.initial;
        _required.number = level.required;

        cfg.sixButtons = false;
        cfg.digits = 2;
        cfg.max = Level.spawnintMax;
        _spawnint = new NumPick(new Geom(butX, 180, 120, 20), cfg);
        _spawnint.number = level.spawnint;

        // DTODO: write format-time in NumPick and add overtime for multiplayer
        addChildren(_intendedNumberOfPlayers,
                    _initial, _spawnint, _required);
    }

protected:
    override void selfWriteChangesTo(Level level)
    {
        level.intendedNumberOfPlayers = _intendedNumberOfPlayers.number;
        level.initial  = _initial.number;
        level.required = _required.number;
        level.spawnint = _spawnint.number;
    }
}
