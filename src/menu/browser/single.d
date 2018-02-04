module menu.browser.single;

import std.algorithm;
import std.format;
import std.conv;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import gui;
import gui.picker;
import hardware.sound;
import level.level;
import menu.browser.frommain;

class BrowserSingle : BrowserCalledFromMainMenu {
private:
    bool _gotoEditorLoadFileRecent;
    bool _gotoEditorNewLevel;
    Level _levelRecent;
    TextButton _edit;
    TextButton _newLevel;
    TextButton _exportImage;
    LabelTwo _by, _save, _trophySaved, _trophySkills;
    Label _exportImageDone1, _exportImageDone2;
    Element[] _hideWhenNullLevelHighlit;

public:
    this()
    {
        super(Lang.browserSingleTitle.transl,
            basics.globals.dirLevels, super.pickerConfig());
        scope (success)
            super.highlight(basics.user.singleLastLevel);

        _edit = new TextButton(new Geom(infoX + infoXl/2, 100,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserEdit.transl);
        _edit.hotkey = basics.user.keyMenuEdit;
        _edit.onExecute = () {
            assert (fileRecent !is null);
            basics.user.singleLastLevel = fileRecent;
            _gotoEditorLoadFileRecent = true;
        };
        _newLevel = new TextButton(new Geom(infoX + infoXl/2, 60,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserNewLevel.transl);
        _newLevel.hotkey = basics.user.keyMenuNewLevel;
        _newLevel.onExecute = () {
            basics.user.singleLastLevel = currentDir.guaranteedDirOnly;
            _gotoEditorNewLevel = true;
        };

        {
            auto g = new Geom(infoX - this.xlg/2 + infoXl/4,
                                60, infoXl/2, 40, From.BOTTOM);
            _exportImage = new TextButton(new Geom(g),
                Lang.browserExportImage.transl);
            g.yl = 20;
            g.y += 20;
            _exportImageDone1 = new Label(new Geom(g),
                Lang.browserExportImageDone.transl);
            g.y -= 20;
            _exportImageDone2 = new Label(new Geom(g));
        }
        _exportImage.hotkey = basics.user.keyMenuExport;
        _exportImage.onExecute = () {
            assert (fileRecent !is null);
            assert (levelRecent !is null);
            Filename imgFn = Level.exportImageFilename(fileRecent);
            levelRecent.exportImageTo(imgFn);
            _exportImage.hide();
            _exportImageDone1.show();
            _exportImageDone2.show();
            _exportImageDone2.text = imgFn.stringzForWriting.to!string;
            hardware.sound.playQuiet(Sound.DISKSAVE);
        };

        _delete = new TextButton(new Geom(infoX, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserDelete.transl);
        _delete.hotkey = basics.user.keyMenuDelete;

        _by = new LabelTwo(new Geom(infoX, infoY + 20, infoXl, 20),
            Lang.browserInfoAuthor.transl);
        _save = new LabelTwo(new Geom(infoX, infoY + 40, infoXl, 20),
            Lang.browserInfoInitgoal.transl);
        immutable savedXl = min(110f, infoXl/2f);
        _trophySaved = new LabelTwo(new Geom(infoX, infoY + 60, savedXl, 20),
            Lang.browserInfoResultSaved.transl);
        _trophySkills = new LabelTwo(new Geom(infoX + savedXl, infoY + 60,
            infoXl - savedXl, 20), Lang.browserInfoResultSkills.transl);

        _hideWhenNullLevelHighlit = [ _edit, _delete, _exportImage,
            _by, _save, _trophySaved, _trophySkills,
            _exportImageDone1, _exportImageDone2];
        _hideWhenNullLevelHighlit.each!(la => addChild(la));
        addChildren(_newLevel);
    }

    override @property inout(Level) levelRecent() inout
    {
        return _levelRecent;
    }

    @property bool gotoEditorNewLevel() const { return _gotoEditorNewLevel; }
    @property bool gotoEditorLoadFileRecent() const
    {
        assert (! _gotoEditorLoadFileRecent || fileRecent);
        return _gotoEditorLoadFileRecent;
    }

protected:
    override void onFileHighlight(Filename fn)
    {
        assert (_edit);
        _hideWhenNullLevelHighlit.each!(e => e.shown = fn !is null);
        _exportImageDone1.hide();
        _exportImageDone2.hide();

        _levelRecent = fn is null ? null : new Level(fileRecent);
        previewLevel(_levelRecent);
        if (! _levelRecent)
            return;
        _by  .value = _levelRecent.author;
        _save.value = "%d/%d".format(_levelRecent.required,
                                     _levelRecent.initial);
        const tro = getTrophy(fn);
        _trophySaved.shown = tro !is null;
        _trophySkills.shown = tro !is null;
        if (tro) {
            _trophySaved.value = "%d".format(tro.lixSaved);
            _trophySkills.value = "%d".format(tro.skillsUsed);
        }
    }

    override void onFileSelect(Filename fn)
    {
        assert (fileRecent  !is null);
        assert (_levelRecent !is null);
        // the super class guarantees that on_file_select is only called after
        // onFileHighlight has been called with the same fn immediately before
        if (_levelRecent.good) {
            basics.user.singleLastLevel = fileRecent;
            gotoGame = true;
        }
    }

    override void calcSelf()
    {
        super.calcSelf();
        calcDeleteMixin();
    }

private:
    mixin DeleteMixin deleteMixin;

    MsgBox newMsgBoxDelete()
    {
        auto m = new MsgBox(Lang.saveBoxTitleDelete.transl);
        m.addMsg(Lang.saveBoxQuestionDeleteLevel.transl);
        m.addMsg(Lang.saveBoxLevelName.transl ~ " " ~ (_levelRecent !is null
            ? _levelRecent.name : fileRecent.fileNoExtNoPre));
        m.addMsg(Lang.saveBoxFileName.transl ~ " " ~ fileRecent.rootless);
        return m;
    }
}
