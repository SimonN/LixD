module game.panel;

/* Panel: A large GUI element that features all the visible buttons
 * during gameplay. Can appear in many different forms, see enum GapaMode
 * in game.panelinf.
 */

import basics.globals;
import basics.user;
import game.panelinf;
import graphic.gralib;
import gui;

class Panel : Element {

public:

    @property float skill_xl() { return Geom.screen_xlg / (14 + 4); }
    @property float skill_yl() { return this.geom.ylg * 3f / 4f; }

    Button[] skills;

    BitmapButton zoom, restart, pause, nuke_single, nuke_multi;
    TwoTasksButton speed_back, speed_ahead, speed_fast;

    @property auto gapamode() const { return _gapamode; }
    // setter property is down below

private:

    private game.panelinf.GapaMode _gapamode;

    private Button _dummy_bg;



public:

this()
{
    super(new Geom(0, 0, Geom.screen_xlg,
                   Geom.screen_ylg / Geom.panel_yl_divisor, From.BOTTOM));

    _dummy_bg = new Button(new Geom(0, 0, this.xlg / 2,
                           this.ylg - skill_yl, From.TOP_LEFT));
    add_child(_dummy_bg);

    skills.length = basics.user.skill_sort.length;
    foreach (id, ac; basics.user.skill_sort) {
        skills[id] = new Button(new Geom(id * skill_xl,
                     0, skill_xl, skill_yl, From.BOTTOM_LEFT));
        this.add_child(skills[id]);
    }

    void new_control_button(T)(ref T b, int x, int y, int frame)
        if (is(T : BitmapButton))
    {
        b = new T(new Geom((3 - x) * skill_xl,
            y == 0 ?  0.5f * skill_yl : 0, skill_xl,
            0.5f * skill_yl, From.BOTTOM_RIGHT),
            get_internal(basics.globals.file_bitmap_game_panel));
        b.xf = frame;
        add_child(b);
    }

    new_control_button(zoom,        0, 0,  2);
    new_control_button(speed_back,  0, 1, 10);
    new_control_button(speed_ahead, 1, 1,  3);
    new_control_button(speed_fast,  2, 1,  4); // 5 if turbo is on
    new_control_button(restart,     1, 0,  8);
    new_control_button(nuke_single, 2, 0,  9);

    nuke_multi = new BitmapButton(
        new Geom(0, 0, 4 * skill_xl, 0, From.BOTTOM_RIGHT),
        get_internal(basics.globals.file_bitmap_game_nuke));

    gapamode = GapaMode.PLAY_SINGLE;
}



public @property GapaMode
gapamode(in GapaMode gp)
{
    _gapamode = gp;

    if (_gapamode == GapaMode.PLAY_SINGLE) {
        nuke_multi.hide();
    }
    else {
        // ...
    }

    return _gapamode = gp;
}



protected override void
calc_self()
{
    _dummy_bg.down = false;

    // debugging
    if (zoom.down)
        nuke_single.down = true;
}

}
// end class Panel
