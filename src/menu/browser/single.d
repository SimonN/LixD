module menu.browser.single;

import std.algorithm;
import std.format;
import std.conv;
import std.range;

import optional;

import basics.globals;
import file.option;
import file.language;
import file.filename;
import file.trophy;
import game.harvest;
import file.replay;
import gui;
import gui.picker;
import hardware.sound;
import level.level;
import menu.browser.withlast;

final class BrowserSingle : BrowserWithDelete {
private:
    bool _gotoEditorLoadFileRecent;
    bool _gotoEditorNewLevel;
    bool _gotoRepForLev;
    Level _levelRecent; // maybe null DTODONULL
    TextButton _edit;
    TextButton _newLevel;
    TextButton _repForLev;
    TextButton _exportImage;
    LabelTwo _by, _save, _trophySaved, _trophySkills;
    Label _exportImageDone;

public:
    this()
    {
        super(Lang.browserSingleTitle.transl,
            basics.globals.dirLevels, super.pickerConfig());
        commonConstructor();
        // Final class calls:
        super.highlight(file.option.singleLastLevel);
    }

    override @property inout(Level) levelRecent() inout
    {
        return _levelRecent;
    }

    bool gotoEditorNewLevel() const pure nothrow @safe @nogc
    {
        return _gotoEditorNewLevel;
    }

    bool gotoEditorLoadFileRecent() const pure nothrow @safe @nogc
    {
        assert (! _gotoEditorLoadFileRecent || fileRecent);
        return _gotoEditorLoadFileRecent;
    }

    bool gotoRepForLev() const pure nothrow @safe @nogc
    {
        assert (! _gotoRepForLev || fileRecent);
        return _gotoRepForLev;
    }

protected:
    final override void onOnHighlightNone()
    {
        only(_edit, _exportImage, _repForLev,
            _by, _save, _trophySaved, _trophySkills,
            _exportImageDone).each!(e => e.hide());
        _levelRecent = null;
        previewNone();
    }

    final override void onOnHighlight(Filename fn)
    in { assert (fn, "call onHighlightNone() instead"); }
    do {
        only(_edit, _exportImage, _repForLev, _by, _save).each!(e => e.show());
        _exportImageDone.hide();
        _levelRecent = new Level(fileRecent);
        previewLevel(_levelRecent);
        _by.value = _levelRecent.author;
        _save.value = "%d/%d".format(_levelRecent.required,
                                     _levelRecent.initial);
        TrophyKey key;
        key.fileNoExt = fn.fileNoExtNoPre;
        key.title = _levelRecent.name;
        key.author = _levelRecent.author;
        getTrophy(key).match!(
            (Trophy tro) {
                _trophySaved.shown = true;
                _trophySkills.shown = true;
                _trophySaved.value = tro.lixSaved;
                _trophySkills.value = tro.skillsUsed;
            }, () {
                _trophySaved.shown = false;
                _trophySkills.shown = false;
            });
    }

    override void onPlay(Filename fn)
    {
        assert (fileRecent  !is null);
        assert (_levelRecent !is null);
        // the super class guarantees that on_file_select is only called after
        // onFileHighlight has been called with the same fn immediately before
        if (_levelRecent.playable) {
            file.option.singleLastLevel = fileRecent;
            gotoGame = true;
        }
    }

    override Geom newDeleteButtonGeom() const
    {
        return new Geom(infoX, 20, infoXl/2, 20, From.BOTTOM_LEFT);
    }

    override MsgBox newMsgBoxDelete()
    {
        auto m = new MsgBox(Lang.saveBoxTitleDelete.transl);
        m.addMsg(Lang.saveBoxQuestionDeleteLevel.transl);
        m.addMsg(Lang.saveBoxLevelName.transl ~ " " ~ (_levelRecent !is null
            ? _levelRecent.name : fileRecent.fileNoExtNoPre));
        m.addMsg(Lang.saveBoxFileName.transl ~ " " ~ fileRecent.rootless);
        return m;
    }

private:
    void commonConstructor()
    {
        buttonPlayYFromBottom = 100f;
        _edit = new TextButton(new Geom(infoX + infoXl/2, 100,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserEdit.transl);
        _edit.hotkey = file.option.keyMenuEdit;
        _edit.onExecute = () {
            assert (fileRecent !is null);
            file.option.singleLastLevel = fileRecent;
            _gotoEditorLoadFileRecent = true;
        };
        _newLevel = new TextButton(new Geom(infoX + infoXl/2, 60,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserNewLevel.transl);
        _newLevel.hotkey = file.option.keyMenuNewLevel;
        _newLevel.onExecute = () {
            file.option.singleLastLevel = currentDir.guaranteedDirOnly;
            _gotoEditorNewLevel = true;
        };

        _repForLev = new TextButton(new Geom(infoX, 20 + 40, infoXl/2, 40,
            From.BOTTOM_LEFT), Lang.browserOpenRepForLev.transl);
        _repForLev.hotkey = file.option.keyMenuRepForLev;
        _repForLev.onExecute = () {
            assert (fileRecent !is null);
            assert (levelRecent !is null);
            file.option.singleLastLevel = fileRecent;
            _gotoRepForLev = true;
        };

        _exportImageDone = new Label(new Geom(infoX - this.xlg/2 + infoXl/4,
            40, infoXl/2, 20, From.BOTTOM), Lang.browserExportImage.transl);
        _exportImage = new TextButton(new Geom(infoX, 20 + 20, infoXl/2, 20,
            From.BOTTOM_LEFT), Lang.browserExportImage.transl);
        _exportImage.hotkey = file.option.keyMenuExport;
        _exportImage.onExecute = () {
            assert (fileRecent !is null);
            assert (levelRecent !is null);
            Filename imgFn = Level.exportImageFilename(fileRecent);
            levelRecent.exportImageTo(imgFn);
            _exportImage.hide();
            _exportImageDone.show();
            _exportImageDone.text = imgFn.stringForWriting;
            hardware.sound.playQuiet(Sound.DISKSAVE);
        };

        _by = new LabelTwo(new Geom(infoX, infoY + 20, infoXl, 20),
            Lang.browserInfoAuthor.transl);
        _save = new LabelTwo(new Geom(infoX, infoY + 40, infoXl, 20),
            Lang.browserInfoInitgoal.transl);
        immutable savedXl = min(110f, infoXl/2f);
        _trophySaved = new LabelTwo(new Geom(infoX, infoY + 60, savedXl, 20),
            Lang.browserInfoBestSaved.transl);
        _trophySkills = new LabelTwo(new Geom(infoX + savedXl, infoY + 60,
            infoXl - savedXl, 20), Lang.browserInfoBestSkills.transl);

        addChildren(_edit, _repForLev, _exportImage, _by, _save, _trophySaved,
            _trophySkills, _exportImageDone, _newLevel);
    }
}
