module menu.mainmenu;

/* This is shown after the game has initialized everything.
 * When the game is run for the first time, the small dialogues asking
 * for language and name are shown first instead, and only then this.
 */

import net.versioning;
import basics.user;
import file.language;
import gui;
import menu.menubg;

static import basics.globals;

class MainMenu : MenuWithBackground {

    @property bool gotoSingle()  { return single .execute; }
    @property bool gotoNetwork() { return network.execute; }
    @property bool gotoReplays() { return replays.execute; }
    @property bool gotoOptions() { return options.execute; }
    @property bool exitProgram() { return _exit  .execute; }

    this()
    {
        immutable butXlg = 200; // large button length
        immutable butSlg =  90; // small button length
        immutable butYlg =  40; // any button's y length
        immutable butSpg =  20; // spacing

        TextButton buttextHeight(Geom.From from, int height)
        {
            int heightg = Window.titleYlg + butSpg + height*(butYlg+butSpg);
            return new TextButton(new Geom(
                height == 2 ? butSpg : 0,        heightg,
                height == 2 ? butSlg : butXlg,   butYlg, from));
        }
        super(new Geom(0, 0,
            butXlg     + butSpg * 2,                  // 80 = labels and space
            butYlg * 4 + butSpg * 4 + Window.titleYlg + 80, Geom.From.CENTER),
            basics.globals.nameOfTheGame);

        single  = buttextHeight(Geom.From.TOP,       0);
        network = buttextHeight(Geom.From.TOP,       1);
        replays = buttextHeight(Geom.From.TOP_LEFT , 2);
        options = buttextHeight(Geom.From.TOP_RIGHT, 2);
        _exit   = buttextHeight(Geom.From.TOP,       3);

        single .text = Lang.browserSingleTitle.transl;
        network.text = "(no netplay yet)"; // DTODO Lang.winLobbyTitle.transl;
        replays.text = Lang.browserReplayTitle.transl;
        options.text = Lang.optionTitle.transl;
        _exit  .text = Lang.commonExit.transl;

        single .hotkey = basics.user.keyMenuMainSingle;
        network.hotkey = basics.user.keyMenuMainNetwork;
        replays.hotkey = basics.user.keyMenuMainReplays;
        options.hotkey = basics.user.keyMenuMainOptions;
        _exit  .hotkey = basics.user.keyMenuExit;

        import std.conv;
        versioning = new Label(new Geom(0, 40, xlg, 20, Geom.From.BOTTOM),
            transl(Lang.commonVersion) ~ " " ~ gameVersion().toString());

        website    = new Label(new Geom(0, 20, xlg, 20, Geom.From.BOTTOM),
            basics.globals.homepageURL);

        addChildren(single, network, replays, options, _exit,
            versioning, website);
    }
    // end this()

private:

    TextButton single;
    TextButton network;
    TextButton replays;
    TextButton options;
    TextButton _exit;

    Label versioning;
    Label website;
}
// end class
