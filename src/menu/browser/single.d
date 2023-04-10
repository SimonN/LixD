module menu.browser.single;

import std.algorithm;
import std.format;
import std.conv;
import std.range;

import optional;

import basics.globals;
import opt = file.option.allopts;
import file.language;
import file.filename;
import file.trophy;
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
    LabelTwo _trophySaved, _trophySkills;
    Label _exportImageDone;

public:
    this()
    {
        super(Lang.browserSingleTitle.transl, basics.globals.dirLevels,
            ylOfNameplateForLevels, super.pickerConfig());
        commonConstructor();
        // Final class calls:
        super.highlight(opt.singleLastLevel.value);
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
            _trophySaved, _trophySkills,
            _exportImageDone).each!(e => e.hide());
        _levelRecent = null;
        previewNone();
    }

    final override void onOnHighlight(Filename fn)
    in { assert (fn, "call onHighlightNone() instead"); }
    do {
        only(_edit, _exportImage, _repForLev).each!(e => e.show());
        _exportImageDone.hide();
        _levelRecent = new Level(fileRecent);
        preview(_levelRecent);
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
            opt.singleLastLevel = fileRecent;
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
        _edit.hotkey = opt.keyMenuEdit.value;
        _edit.onExecute = () {
            assert (fileRecent !is null);
            opt.singleLastLevel = fileRecent;
            _gotoEditorLoadFileRecent = true;
        };
        _newLevel = new TextButton(new Geom(infoX + infoXl/2, 60,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserNewLevel.transl);
        _newLevel.hotkey = opt.keyMenuNewLevel.value;
        _newLevel.onExecute = () {
            opt.singleLastLevel = currentDir.guaranteedDirOnly;
            _gotoEditorNewLevel = true;
        };

        _repForLev = new TextButton(new Geom(infoX, 20 + 40, infoXl/2, 40,
            From.BOTTOM_LEFT), Lang.browserOpenRepForLev.transl);
        _repForLev.hotkey = opt.keyMenuRepForLev.value;
        _repForLev.onExecute = () {
            assert (fileRecent !is null);
            assert (levelRecent !is null);
            opt.singleLastLevel = fileRecent;
            _gotoRepForLev = true;
        };

        _exportImageDone = new Label(new Geom(infoX - this.xlg/2 + infoXl/4,
            40, infoXl/2, 20, From.BOTTOM), Lang.browserExportImage.transl);
        _exportImage = new TextButton(new Geom(infoX, 20 + 20, infoXl/2, 20,
            From.BOTTOM_LEFT), Lang.browserExportImage.transl);
        _exportImage.hotkey = opt.keyMenuExport.value;
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

        immutable savedXl = min(110f, infoXl/2f);
        _trophySaved = new LabelTwo(new Geom(infoX, trophyLineY, savedXl, 20),
            Lang.previewLevelSingleTrophySaved.transl);
        _trophySaved.setUndrawBeforeDraw();
        _trophySkills = new LabelTwo(new Geom(infoX + savedXl, trophyLineY,
            infoXl - savedXl, 20), Lang.previewLevelSingleTrophySkills.transl);
        _trophySkills.setUndrawBeforeDraw();

        addChildren(_edit, _repForLev, _exportImage, _trophySaved,
            _trophySkills, _exportImageDone, _newLevel);
    }
}
