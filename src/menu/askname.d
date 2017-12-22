module menu.askname;

import std.string;

static import basics.globconf;
static import basics.user;
static import hardware.keyboard;

import basics.alleg5; // Explicit press of ESC
import file.language;
import gui;
import menu.menubg;

class MenuAskName : MenuWithBackground {
private:
    bool _gotoMainMenu = false;
    bool _gotoExitApp = false;
    Texttype _tt;

public:
    @property bool gotoMainMenu() const { return _gotoMainMenu; }
    @property bool gotoExitApp() const { return _gotoExitApp; }

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
            if (_tt.text.strip.length > 0) {
                basics.globconf.userName = _tt.text.strip;
                basics.user.load();
                _gotoMainMenu = true;
                // Main menu will change resolution for us.
                // I don't dare to do it here because we're in a GUI dialog.
            }
        };
        _tt.on = true;
        addChild(_tt);
    }

protected:
    // this is called even if the Window doesn't have focus
    override void workSelf()
    {
        if (! _gotoMainMenu && ! _gotoExitApp) {
            _tt.down = false;
            _tt.on = true;
            if (hardware.keyboard.keyTapped(ALLEGRO_KEY_ESCAPE))
                _gotoExitApp = true;
        }
    }
}
