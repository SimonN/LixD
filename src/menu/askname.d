module menu.askname;

static import basics.globconf;
static import basics.user;
import file.language;
import gui;
import menu.menubg;

class MenuAskName : MenuWithBackground {

    @property bool done() { return _done; }

    this()
    {
        super(new Geom(0, 0, 200, 140, From.CENTER));
        super.windowTitle =  Lang.windowAskNameTitle.transl;

        addChild(new Label(new Geom(0, 40, this.xlg, 20, From.TOP),
            Lang.windowAskNameFirst.transl));
        addChild(new Label(new Geom(0, 60, this.xlg, 20, From.TOP),
            Lang.windowAskNameSecond.transl));

        _tt = new Texttype(new Geom(0, 100, this.xlg-40, 20, From.TOP));
        _tt.onEnter = () {
            if (_tt.text.length > 0) {
                _done = true;
                basics.globconf.userName = _tt.text;
                basics.user.load();
            }
        };
        _tt.on = true;
        addChild(_tt);
    }

protected:

    // this is called even if the Window doesn't have focus
    override void workSelf()
    {
        if (! _done) {
            _tt.down = false;
            _tt.on = true;
        }
    }

private:

    bool _done = false;
    Texttype _tt;
}
