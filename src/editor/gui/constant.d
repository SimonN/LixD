module editor.gui.constant;

import basics.user;
import basics.globals;
import editor.gui.okcancel;
import file.language;
import gui;
import level.level;

class ConstantsWindow : OkCancelWindow {
private:
    Texttype _author;
    Texttype _levelName;
    NumPick _intendedNumberOfPlayers;
    NumPick _initial;
    NumPick _spawnint;
    NumPick _required;
    NumPick _overtime;

public:
    this(Level level)
    {
        enum thisXl = 450f;
        super(new Geom(0, 0, thisXl, 250, From.CENTER),
            Lang.winConstantsTitle.transl);
        enum butX   = 140f;
        enum butXl  = thisXl - butX - 20f;
        enum textXl = 120f;

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

        _author    = new Texttype(new Geom(butX, 30, butXl, 20));
        _levelName = new Texttype(new Geom(butX, 60, butXl, 20));
        _author.text = level.author;
        _levelName.text = level.nameEnglish;

        NumPickConfig cfg;
        cfg.digits = 1;
        cfg.min = 1;
        cfg.max = basics.globals.teamsPerLevelMax;
        _intendedNumberOfPlayers = new NumPick(new Geom(butX + 20, 90,
                                                        130, 20), cfg);
        _intendedNumberOfPlayers.number = level.intendedNumberOfPlayers;

        cfg.sixButtons = true;
        cfg.digits = 3;
        cfg.max = Level.initialMax;
        _initial  = new NumPick(new Geom(butX, 120, 170, 20), cfg);
        _required = new NumPick(new Geom(butX, 150, 170, 20), cfg);
        _initial .number = level.initial;
        _required.number = level.required;

        cfg.sixButtons = false;
        cfg.digits = 2;
        cfg.max = Level.spawnintMax;
        _spawnint = new NumPick(new Geom(butX + 20, 180, 130, 20), cfg);
        _spawnint.number = level.spawnint;

        cfg.time = true;
        cfg.sixButtons = true;
        cfg.digits = 5;
        cfg.min = 0;
        cfg.max = 30 * 60; // completely arbitrary
        cfg.stepBig = 60;
        _overtime = new NumPick(new Geom(butX, 210, 170, 20), cfg);
        _overtime.number = level.overtimeSeconds;
        addChildren(_author, _levelName, _intendedNumberOfPlayers,
                    _initial, _spawnint, _required, _overtime);
    }

protected:
    override void selfWriteChangesTo(Level level)
    {
        level.author = _author.text;
        level.nameEnglish = _levelName.text;
        level.intendedNumberOfPlayers = _intendedNumberOfPlayers.number;
        level.initial = _initial.number;
        level.required = _required.number;
        level.spawnint = _spawnint.number;
        level.overtimeSeconds = _overtime.number;
    }
}
