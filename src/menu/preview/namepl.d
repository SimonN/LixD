module menu.preview.namepl;

import std.algorithm;
import std.format;
import std.range;

import optional;

import graphic.color;
import file.language;
import level.level;
import menu.preview.base;
import gui;

class Nameplate : Element, PreviewLevelOrReplay {
private:
    LevelNameplate _level;
    ReplayNameplate _replay;

public:
    this(Geom g)
    {
        super(g);
        _level = new LevelNameplate(new Geom(0, 0, xlg, ylg));
        _replay = new ReplayNameplate(new Geom(0, 0, xlg, ylg));
        addChildren(_level, _replay);
    }

    void setUndrawBeforeDraw()
    {
        _level.setUndrawBeforeDraw();
        _replay.setUndrawBeforeDraw();
    }

    void previewNone()
    {
        _level.hide();
        _replay.hide();
    }

    void preview(in Level lev)
    {
        _level.show();
        _level.preview(lev);
        _replay.hide();
    }

    void preview(in Replay rep, in Level lev)
    {
        _level.hide();
        _replay.show();
        _replay.preview(rep, lev);
    }
}

private:

class LevelNameplate : Element {
private:
    Label _title;
    LabelTwo _by;
    LabelTwo _save;

public:
    this(Geom g)
    do {
        super(g);
        _title = new Label(new Geom(0, 0, xlg, 20, From.TOP_LEFT));
        _by = new LabelTwo(new Geom(0, 0, xlg, 20, From.LEFT),
            Lang.previewLevelAuthor.transl);
        _save = new LabelTwo(new Geom(0, 0, xlg, 20, From.BOTTOM_LEFT),
            Lang.previewLevelSingleGoal.transl);
        addChildren(_title, _by, _save);
        undrawColor = color.guiM;
    }

    void setUndrawBeforeDraw()
    {
        _title.undrawBeforeDraw = true;
        _by.setUndrawBeforeDraw();
        _save.setUndrawBeforeDraw();
    }

    void preview(in Level lev)
    {
        _title.text = lev.name;
        _by.value = lev.author;
        _save.value = format!"%d/%d"(lev.required, lev.initial);
    }
}

class ReplayNameplate : Element {
private:
    Label _title;
    LabelTwo _player;
    LabelTwo _pointsTo;

public:
    this(Geom g)
    do {
        super(g);
        _title = new Label(new Geom(0, 0, xlg, 20, From.TOP_LEFT));
        _player = new LabelTwo(new Geom(0, 0, xlg, 20, From.LEFT),
            Lang.previewReplayPlayer.transl);
        _pointsTo = new LabelTwo(new Geom(0, 0, xlg, 20, From.BOTTOM_LEFT),
            Lang.previewReplayPointsTo.transl);
        addChildren(_title, _player, _pointsTo);
        undrawColor = color.guiM;
    }

    void setUndrawBeforeDraw()
    {
        _title.undrawBeforeDraw = true;
        _player.setUndrawBeforeDraw();
        _pointsTo.setUndrawBeforeDraw();
    }

    void preview(in Replay rep, in Level lev)
    {
        _title.text = lev.name;
        _player.value = rep.players.byValue.map!(p => p.name).join(", ");
        rep.levelFilename.match!(
            () {
                _pointsTo.hide();
            },
            (f) {
                _pointsTo.show();
                _pointsTo.value = f.rootless;
            }
        );
    }
}
