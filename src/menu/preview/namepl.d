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

    void preview(in Replay rep, in Filename fnOfThatReplay, in Level lev)
    {
        _level.hide();
        _replay.show();
        _replay.preview(rep, fnOfThatReplay, lev);
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
        undrawColor = color.gui.m;
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

    /*
     * Filename of the replay itself. This replay filename appears already in
     * the file picker on the left of the screen, but replay filenames can
     * get long and unwieldy. Let's show the _tail_ of the filename here
     * because the picker shows only the front when the picker abbreviates.
     */
    LabelTwo _repFn;
    LabelTwo _pointsTo; // Filename of the pointed-to level

public:
    this(Geom g)
    do {
        super(g);
        float yFor(int i) { return i * (ylg - 20f) / 3f; } // y for the i-th.
        _title = new Label(new Geom(0, yFor(0), xlg, 20, From.TOP_LEFT));
        _player = new LabelTwo(new Geom(0, yFor(1), xlg, 20, From.TOP_LEFT),
            Lang.previewReplayPlayer.transl);
        _repFn = new LabelTwo(new Geom(0, yFor(2), xlg, 20, From.TOP_LEFT),
            Lang.previewReplayFilenameOfReplay.transl);
        _repFn.abbreviateNear(Label.AbbreviateNear.beginning);
        _pointsTo = new LabelTwo(new Geom(0, yFor(3), xlg, 20, From.TOP_LEFT),
            Lang.previewReplayPointsTo.transl);
        addChildren(_title, _player, _repFn, _pointsTo);
        undrawColor = color.gui.m;
    }

    void setUndrawBeforeDraw()
    {
        _title.undrawBeforeDraw = true;
        _repFn.setUndrawBeforeDraw();
        _player.setUndrawBeforeDraw();
        _pointsTo.setUndrawBeforeDraw();
    }

    void preview(in Replay rep, in Filename fnOfThatReplay, in Level lev)
    {
        _title.text = lev.name;
        _player.value = rep.players.byValue.map!(p => p.name).join(", ");
        _repFn.value = fnOfThatReplay.file;
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
