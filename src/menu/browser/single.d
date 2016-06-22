module menu.browser.single;

import std.algorithm;
import std.format;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import gui;
import gui.picker;
import level.level;
import menu.browser.frommain;

class BrowserSingle : BrowserCalledFromMainMenu {
private:
    bool _gotoEditor;
    TextButton _edit;
    LabelTwo _by, _save;

public:
    this()
    {
        super(Lang.browserSingleTitle.transl,
            basics.globals.dirLevels, PickerConfig!LevelTiler());
        scope (success)
            super.highlight(basics.user.singleLastLevel);
        _edit = new TextButton(new Geom(infoX + infoXl/2, 100,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserEdit.transl);
        _edit.hotkey = basics.user.keyMenuEdit;
        _edit.onExecute = () {
            assert (fileRecent !is null);
            basics.user.singleLastLevel = fileRecent;
            _gotoEditor = true;
        };
        _delete = new TextButton(new Geom(infoX + infoXl/2, 60,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserDelete.transl);
        _delete.hotkey = basics.user.keyMenuDelete;
        _by = new LabelTwo(new Geom(infoX, infoY + 20, infoXl, 20),
            Lang.browserInfoAuthor.transl);
        _save = new LabelTwo(new Geom(infoX, infoY + 40, infoXl, 20),
            Lang.browserInfoInitgoal.transl);
        addChildren(_edit, _delete, _by, _save);
    }

    @property bool gotoEditor() const
    {
        if (_gotoEditor)
            assert (fileRecent !is null);
        return _gotoEditor;
    }

protected:
    override void onFileHighlight(Filename fn)
    {
        assert (_edit);
        levelRecent  = fn is null ? null : new Level(fileRecent);
        [_edit, _delete, _by, _save].each!(e => e.hidden = fn is null);
        if (levelRecent) {
            _by  .value = levelRecent.author;
            _save.value = "%s/%s".format(levelRecent.required,
                                         levelRecent.initial);
        }
        previewLevel(levelRecent);
    }

    override void onFileSelect(Filename fn)
    {
        assert (fileRecent  !is null);
        assert (levelRecent !is null);
        // the super class guarantees that on_file_select is only called after
        // onFileHighlight has been called with the same fn immediately before
        if (levelRecent.good) {
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
        m.addMsg(Lang.saveBoxLevelName.transl ~ " " ~ (levelRecent !is null
            ? levelRecent.name : fileRecent.fileNoExtNoPre));
        m.addMsg(Lang.saveBoxFileName.transl ~ " " ~ fileRecent.rootful);
        return m;
    }
}
