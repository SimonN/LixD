module menu.outcome.trotable;

/*
 * Trophy table on the singleplayer outcome board.
 * Contains logic to save trophies.
 */

import file.language;
import file.trophy;
import gui;

class TrophyTable : Element {
private:
    Element[] _lines;

public:
    this(Geom g)
    {
        super(g);
        addChild(new TrophyHeader(new Geom(0, 0, xlg, 20f)));
    }

    void addSaveRequirement(in int lixRequired)
    {
        _lines ~= new SaveRequirementLine(
            new Geom(0, 20f + _lines.length * 20f, xlg, 20f), lixRequired);
        addChild(_lines[$-1]);
        reqDraw();
    }

    void addJustPlayed(in Trophy yourAttempt)
    {
        add(Lang.outcomeTrophyYourAttempt, yourAttempt);
    }

    void addOld(in Trophy previous)
    {
        add(Lang.outcomeTrophyPreviousRecord, previous);
    }

private:
    void add(in Lang caption, in Trophy trophy)
    {
        _lines ~= new TrophyLine(
            new Geom(0, 20f + _lines.length * 20f, xlg, 20f), caption, trophy);
        addChild(_lines[$-1]);
        reqDraw();
    }
}

private:

class TrophyHeader : Element {
private:
    Label _captionLixSaved;
    Label _captionSkillsUsed;

public:
    this(Geom g)
    {
        super(g);
        _captionLixSaved = new Label(new Geom(xlg/2.5f, 0, xlg - xlg/2.5f, ylg,
            From.RIGHT), Lang.outcomeTrophyLixSaved.transl);
        addChild(_captionLixSaved);

        _captionSkillsUsed = new Label(new Geom(0, 0, xlg/2.5f, ylg,
            From.RIGHT), Lang.outcomeTrophySkillsUsed.transl);
        addChild(_captionSkillsUsed);
    }
}

class TrophyLine : Element {
private:
    Label _name;
    Label _numLixSaved;
    Label _numSkillsUsed;

public:
    this(Geom g, Lang caption, in Trophy trophy)
    {
        super(g);
        _name = new Label(new Geom(0, 0, xlg/2, ylg), caption.transl);
        addChild(_name);

        _numLixSaved = new Label(
            new Geom(xlg/2.5f, 0, xlg/4, ylg, From.RIGHT));
        _numLixSaved.number = trophy.lixSaved;
        addChild(_numLixSaved);

        _numSkillsUsed = new Label(new Geom(0, 0, xlg/4, ylg, From.RIGHT));
        _numSkillsUsed.number = trophy.skillsUsed;
        addChild(_numSkillsUsed);
    }
}

class SaveRequirementLine : Element {
private:
    Label _name;
    Label _numLixRequired;

public:
    this(Geom g, in int lixRequired)
    {
        super(g);
        _name = new Label(new Geom(0, 0, xlg/2, ylg),
            Lang.winConstantsRequired.transl);
        addChild(_name);

        _numLixRequired = new Label(
            new Geom(xlg/2.5f, 0, xlg/4, ylg, From.RIGHT));
        _numLixRequired.number = lixRequired;
        addChild(_numLixRequired);
    }
}
