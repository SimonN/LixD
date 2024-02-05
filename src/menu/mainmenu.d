module menu.mainmenu;

/* This is shown after the game has started in graphical mode, before input.
 * When the game is run for the first time, the small dialogues asking
 * for language and name are shown first instead, and only then this.
 */

import basics.arch;
import basics.globals;
import basics.alleg5 : allegroDllVersion;
import opt = file.option.allopts;
import file.language;
import gui;
import menu.menubg;
import net.versioning;

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
    @property const pure nothrow @safe @nogc {
        bool gotoSingle()  { return _single .execute; }
        bool gotoNetwork() { return _network.execute; }
        bool gotoReplays() { return _replays.execute; }
        bool gotoOptions() { return _options.execute; }
        bool exitProgram() { return _exit  .execute; }
    }

    this()
    {
        enum ylBelowBottomButton = 100;
        super(new Geom(0, 0,
            butXlg     + butSpg * 2,
            butYlg * 4 + butSpg * 4 + Window.titleYlg + ylBelowBottomButton,
            Geom.From.CENTER),
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
        _single .hotkey = opt.keyMenuMainSingle.value;
        _network.hotkey = opt.keyMenuMainNetwork.value;
        _replays.hotkey = opt.keyMenuMainReplays.value;
        _options.hotkey = opt.keyMenuMainOptions.value;
        _exit   .hotkey = opt.keyMenuExit.value;
        addChildren(_single, _network, _replays, _options, _exit);
    }

    void addLabelNearBottom(in float ygFromBot, in Alfont font, in string s)
    {
        auto l = new Label(new Geom(0, ygFromBot, xlg, 20, From.BOTTOM));
        l.font = font;
        l.text = s;
        addChild(l);
    }

    void addVersioning()
    {
        import std.conv : to;
        addLabelNearBottom(60, djvuM,
            Lang.versioningVersion.transl ~ " " ~ gameVersion.to!string);
        addLabelNearBottom(41, djvuS,
            Lang.versioningForOperatingSystem.transl ~ " " ~ osAndArch);
        addLabelNearBottom(30, djvuS, allegroDllVersion);
        addLabelNearBottom(20, djvuM, basics.globals.homepageURL);
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
            l.color = al_map_rgb_f(0.4, 0.35, 0.3);
            addChild(l);
        }
        int y = 0;
        if (opt.musicEnabled.value && ! dirDataMusic.dirExists) {
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
