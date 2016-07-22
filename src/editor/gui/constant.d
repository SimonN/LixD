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

public:
    this(Level level)
    {
        enum thisXl = 450f;
        super(new Geom(0, 0, thisXl, 230, From.CENTER),
            Lang.winConstantsTitle.transl);
        enum butX   = 140f;
        enum butXl  = thisXl - butX - 20f;
        enum textXl = 120f;

        void label(in float y, in Lang cap)
        {
            addChild(new Label(new Geom(20, y, textXl, 20), cap.transl));
        }
        label( 40, Lang.winConstantsAuthor);
        label( 70, Lang.winConstantsLevelName);
        label(100, Lang.winConstantsPlayers);
        label(130, Lang.winConstantsInitial);
        label(160, Lang.winConstantsRequired);
        label(190, Lang.winConstantsSpawnint);

        _author    = new Texttype(new Geom(butX, 40, butXl, 20));
        _levelName = new Texttype(new Geom(butX, 70, butXl, 20));
        _author.text = level.author;
        _levelName.text = level.nameEnglish;

        NumPickConfig cfg;
        cfg.digits = 1;
        cfg.min = 1;
        cfg.max = basics.globals.teamsPerLevelMax;
        _intendedNumberOfPlayers = new NumPick(new Geom(butX + 20, 100,
                                                        130, 20), cfg);
        _intendedNumberOfPlayers.number = level.intendedNumberOfPlayers;

        cfg.sixButtons = true;
        cfg.digits = 3;
        cfg.max = Level.initialMax;
        _initial  = new NumPick(new Geom(butX, 130, 170, 20), cfg);
        _required = new NumPick(new Geom(butX, 160, 170, 20), cfg);
        _initial .number = level.initial;
        _required.number = level.required;

        cfg.sixButtons = false;
        cfg.digits = 2;
        cfg.max = Level.spawnintMax;
        _spawnint = new NumPick(new Geom(butX + 20, 190, 130, 20), cfg);
        _spawnint.number = level.spawnint;

        addChildren(_author, _levelName, _intendedNumberOfPlayers,
                    _initial, _spawnint, _required);
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
    }
}
