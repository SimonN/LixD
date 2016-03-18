module menu.browsin;

import basics.globals;
import basics.user;
import file.language;
import file.filename;
import gui;
import level.level;
import menu.browmain;

class BrowserSingle : BrowserCalledFromMainMenu {
private:
    bool _gotoEditor;
    TextButton _edit;

public:
    this()
    {
        super(Lang.browserSingleTitle.transl,
            basics.globals.dirLevels);
        super.movePreviewDown(40);
        scope (success)
            super.highlight(basics.user.singleLastLevel);
        _edit = new TextButton(new Geom(20, 80, infoXl, 40, From.TOP_RIGHT));
        _edit.text   = Lang.browserEdit.transl;
        _edit.hotkey = basics.user.keyMenuEdit;
        _edit.onExecute = () {
            assert (fileRecent !is null);
            _gotoEditor = true;
        };
        addChild(_edit);
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
        _edit.hidden = fn is null;
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
}
