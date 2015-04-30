module menu.mainmenu;

/* This is shown after the game has initialized everything.
 * When the game is run for the first time, the small dialogues asking
 * for language and name are shown first instead, and only then this.
 */

import basics.alleg5;  // drawing bg to screen
import basics.globals; // title bar text
import basics.versioning;
import basics.user;
import graphic.gralib; // menu background
import file.language;
import gui;

class MainMenu : Window {

    @property bool goto_single()  { return single .clicked; }
    @property bool goto_network() { return network.clicked; }
    @property bool goto_replay()  { return replay .clicked; }
    @property bool goto_options() { return options.clicked; }
    @property bool exit_program() { return exit   .clicked; }

private:

    TextButton single;
    TextButton network;
    TextButton replay;
    TextButton options;
    TextButton exit;

    Label versioning;
    Label website;



public this()
{
    immutable but_xlg = 200; // large button length
    immutable but_slg =  90; // small button length
    immutable but_ylg =  40;
    immutable but_spg =  20;

    TextButton buttext_height(Geom.From from, int height)
    {
        int heightg = Window.title_ylg + but_spg + height*(but_ylg+but_spg);
        return new TextButton(from,
            height == 2 ? but_spg : 0,         heightg,
            height == 2 ? but_slg : but_xlg,   but_ylg);
    }

    super(Geom.From.CENTER, 0, 0,
        but_xlg     + but_spg * 2,                  // 80 = labels and space
        but_ylg * 4 + but_spg * 4 + Window.title_ylg + 80,
        basics.globals.main_name_of_game);

    single  = buttext_height(Geom.From.TOP,       0);
    network = buttext_height(Geom.From.TOP,       1);
    replay  = buttext_height(Geom.From.TOP_LEFT , 2);
    options = buttext_height(Geom.From.TOP_RIGHT, 2);
    exit    = buttext_height(Geom.From.TOP,       3);

    single .set_text(transl(Lang.browser_single_title));
    network.set_text(transl(Lang.win_lobby_title));
    replay .set_text(transl(Lang.browser_replay_title));
    options.set_text(transl(Lang.option_title));
    exit   .set_text(transl(Lang.common_exit));

    single .set_hotkey(basics.user.key_me_main_single);
    network.set_hotkey(basics.user.key_me_main_network);
    replay .set_hotkey(basics.user.key_me_main_replay);
    options.set_hotkey(basics.user.key_me_main_options);
    exit   .set_hotkey(basics.user.key_me_exit);

    // DTODO: make constructor of Label take floats, because xlg is float
    import std.conv;
    versioning = new Label(Geom.From.BOTTOM, 0, 40, xlg.to!int,
        transl(Lang.main_version) ~ " " ~ get_version_string());

    website = new Label(Geom.From.BOTTOM, 0, 20, xlg.to!int,
        basics.globals.main_website);

    add_children(single, network, replay, options, exit, versioning, website);
}
// end this()



protected override void
draw_self()
{
    auto bg = get_internal(file_bitmap_menu_background);
    if (bg && bg.is_valid())
        al_draw_scaled_bitmap(bg.get_albit(),
         0, 0, bg.get_xl(),     bg.get_yl(),
         0, 0, Geom.screen_xls, Geom.screen_yls, 0);
    else
        torbit.clear_to_black();

    super.draw_self();
}

}
// end class
