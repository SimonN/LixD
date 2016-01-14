module menu.browrep;

static import basics.user;
import file.filename;
import file.language;
import gui;
import menu.browbase;

class BrowserReplay : BrowserBase {

    this()
    {
        super(Lang.browserReplayTitle.transl,
            basics.globals.dirReplays,
            basics.user.replayLastLevel,
            super.UseCheckmarks.no,
            super.UseReplayStyle.yes);
        _delete = newInfo!TextButton(infoY);
        _delete.text   = "(delete)";// Lang.browserDelete.transl;
        _delete.hotkey = basics.user.keyMenuDelete;
        _extract = newInfo!TextButton(infoY + 20);
        _extract.text   = "(extract)"; // Lang.browserExtract.transl;
        _extract.hotkey = basics.user.keyMenuExport;
    }

protected:

    override void onFileHighlight(Filename fn)
    {
    }

    override void onFileSelect(Filename fn)
    {
    }

    override void calcSelf()
    {
        super.calcSelf();
        // add save browser/deletion confirmation here? Or realize
        // those with gui focus instead of adding them here?
    }

private:

    TextButton _extract;
    TextButton _delete;

    auto newInfo(T)(float y)
        if (is (T : Element))
    {
        auto a = new T(new Geom(20, y, infoXl, 20, From.TOP_RIGHT));
        addChild(a);
        return a;
    }

};
