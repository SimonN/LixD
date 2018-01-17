module menu.mainmenu;

/* This is shown after the game has started in graphical mode, before input.
 * When the game is run for the first time, the small dialogues asking
 * for language and name are shown first instead, and only then this.
 */

import net.versioning;
import basics.globals;
import basics.globconf;
import basics.user;
import file.language;
import gui;
import menu.menubg;

static import basics.globals;
static import hardware.sound; // ...to warn about errors initializing audio.
                              // Maybe redesign into displaying the logfile?

class MainMenu : MenuWithBackground {
private:
    TextButton _single;
    TextButton _network;
    TextButton _replays;
    TextButton _options;
    TextButton _exit;

    enum butXlg = 200f; // large button length
    enum butSlg =  90f; // small button length
    enum butYlg =  40f; // any button's y length
    enum butSpg =  20f; // spacing

public:
    @property bool gotoSingle()  { return _single .execute; }
    @property bool gotoNetwork() { return _network.execute; }
    @property bool gotoReplays() { return _replays.execute; }
    @property bool gotoOptions() { return _options.execute; }
    @property bool exitProgram() { return _exit  .execute; }

    this()
    {
        super(new Geom(0, 0,
            butXlg     + butSpg * 2,                  // 80 = labels and space
            butYlg * 4 + butSpg * 4 + Window.titleYlg + 80, Geom.From.CENTER),
            basics.globals.nameOfTheGame);
        addButtons();
        addVersioning();
        warnAboutMissingMusic();
    }

private:
    void addButtons()
    {
        TextButton buttextHeight(Geom.From from, in float height)
        {
            float heightg = Window.titleYlg + butSpg + height*(butYlg+butSpg);
            return new TextButton(new Geom(
                height == 2 ? butSpg : 0,        heightg,
                height == 2 ? butSlg : butXlg,   butYlg, from));
        }
        _single  = buttextHeight(Geom.From.TOP,       0);
        _network = buttextHeight(Geom.From.TOP,       1);
        _replays = buttextHeight(Geom.From.TOP_LEFT , 2);
        _options = buttextHeight(Geom.From.TOP_RIGHT, 2);
        _exit    = buttextHeight(Geom.From.TOP,       3);
        _single .text = Lang.browserSingleTitle.transl;
        _network.text = Lang.winLobbyTitle.transl;
        _replays.text = Lang.browserReplayTitle.transl;
        _options.text = Lang.optionTitle.transl;
        _exit   .text = Lang.commonExit.transl;
        _single .hotkey = basics.user.keyMenuMainSingle;
        _network.hotkey = basics.user.keyMenuMainNetwork;
        _replays.hotkey = basics.user.keyMenuMainReplays;
        _options.hotkey = basics.user.keyMenuMainOptions;
        _exit   .hotkey = basics.user.keyMenuExit;
        addChildren(_single, _network, _replays, _options, _exit);
    }

    void addVersioning()
    {
        import std.conv : to;
        addChild(new Label(new Geom(0, 40, xlg, 20, Geom.From.BOTTOM),
            transl(Lang.commonVersion) ~ " " ~ gameVersion().toString()));
        addChild(new Label(new Geom(0, 20, xlg, 20, Geom.From.BOTTOM),
            basics.globals.homepageURL));
    }

    void warnAboutMissingMusic()
    {
        void printLine(in float yFromBottom, in string text)
        {
            import basics.alleg5;
            // We want to print in the corner of the screen, but, since we
            // add these labels as children to handle their drawing, must
            // specify position relative to the small window.
            Label l = new Label(new Geom(
                xlg / 2f - screenXlg / 2f + thickg,
                ylg / 2f - screenYlg / 2f + yFromBottom,
                screenXlg, 20, From.BOTTOM_LEFT), text);
            l.color = Alcol(0.4, 0.35, 0.3, 1);
            addChild(l);
        }
        int y = 0;
        if (basics.user.musicEnabled.value && ! dirDataMusic.dirExists) {
            printLine(y + 20, Lang.mainMenuGetMusic.transl);
            printLine(y +  0, musicDownloadURL);
            y += 40;
        }
        if (! hardware.sound.tryInitialize) {
            printLine(y, "Error initializing audio. See data/log.txt");
            y += 20;
        }
    }
}
