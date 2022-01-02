module editor.gui.constant;

import file.option;
import basics.globals;
import editor.gui.okcancel;
import file.language;
import gui;
import level.level;

class ConstantsWindow : OkCancelWindow {
private:
    Texttype _levelName;
    Texttype _author;
    NumPick _intendedNumberOfPlayers;
    NumPick _initial;
    NumPick _spawnint;
    NumPick _required;
    NumPick _overtime;
    Label _requiredLabel;
    Label _overtimeLabel;

public:
    this(Level level)
    {
        enum thisXl = 450f;
        super(new Geom(0, 0, thisXl, 230, From.CENTER),
            Lang.winConstantsTitle.transl);
        enum butX   = 140f;
        enum butXl  = thisXl - butX - 20f;
        enum textXl = 120f;

        Label label(in float y, in Lang cap)
        {
            Label l = new Label(new Geom(20, y, textXl, 20), cap.transl);
            addChild(l);
            return l;
        }
        label( 40, Lang.winConstantsLevelName);
        label( 70, Lang.winConstantsAuthor);
        label(100, Lang.winConstantsPlayers);
        label(130, Lang.winConstantsInitial);
        label(190, Lang.winConstantsSpawnint);
        _requiredLabel = label(160, Lang.winConstantsRequired);
        _overtimeLabel = label(160, Lang.winConstantsOvertime);

        _levelName = new Texttype(new Geom(butX, 40, butXl, 20));
        _author    = new Texttype(new Geom(butX, 70, butXl, 20));
        _levelName.text = level.md.nameEnglish;
        _author.text = level.author;

        NumPickConfig cfg;
        cfg.digits = 4;
        cfg.stepMedium = 3;
        cfg.min = 1;
        cfg.max = basics.globals.teamsPerLevelMax;
        _intendedNumberOfPlayers = new NumPick(new Geom(butX + 20, 100,
                                                        130, 20), cfg);
        _intendedNumberOfPlayers.number = level.intendedNumberOfPlayers;

        cfg.sixButtons = true;
        cfg.stepMedium = 10;
        cfg.max = Level.initialMax;
        _initial  = new NumPick(new Geom(butX, 130, 170, 20), cfg);
        _required = new NumPick(new Geom(butX, 160, 170, 20), cfg);
        _initial .number = level.initial;
        _required.number = level.required;

        cfg.sixButtons = false;
        cfg.max = Level.spawnintMax;
        _spawnint = new NumPick(new Geom(butX + 20, 190, 130, 20), cfg);
        _spawnint.number = level.spawnint;

        cfg.sixButtons = true;
        cfg.time = true;
        cfg.stepBig = 60;
        cfg.max = 60*9;
        cfg.min = 0;
        _overtime = new NumPick(new Geom(_required.geom), cfg);
        _overtime.number = level.overtimeSeconds;

        addChildren(_levelName, _author, _intendedNumberOfPlayers,
                    _initial, _spawnint, _required, _overtime);
        showOrHideModalFields();
    }

protected:
    override void selfWriteChangesTo(Level level)
    {
        level.md.nameEnglish = _levelName.text;
        level.md.author = _author.text;
        level.intendedNumberOfPlayers = _intendedNumberOfPlayers.number;
        level.md.initial = _initial.number;
        level.md.required = _required.number;
        level.spawnint = _spawnint.number;
        level.overtimeSeconds = _overtime.number;
    }

    override void calcSelf() { showOrHideModalFields(); }

    void showOrHideModalFields()
    {
        immutable bool multi = _intendedNumberOfPlayers.number > 1;
        _required.shown = ! multi;
        _requiredLabel.shown = ! multi;
        _overtime.shown = multi;
        _overtimeLabel.shown = multi;
    }
}
