module game.panel;

/* Panel: A large GUI element that features all the visible buttons
 * during gameplay. Can appear in many different forms, see enum GapaMode
 * in game.panelinf.
 */

import basics.globals;
import basics.user;
import game;
import graphic.gralib;
import gui;

class Panel : Element {

public:

    @property float skill_xl() { return Geom.screen_xlg / (14 + 4); }
    @property float skill_yl() { return this.geom.ylg - 20; }

    SkillButton[] skills;

    BitmapButton zoom, restart, pause, nuke_single, nuke_multi;
    TwoTasksButton speed_back, speed_ahead, speed_fast;

    @property auto gapamode() const { return _gapamode; }
    // setter property is down below

private:

    private GapaMode _gapamode;

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
    foreach (int id, ac; basics.user.skill_sort) {
        skills[id] = new SkillButton(new Geom(id * skill_xl, 0,
                                 skill_xl, skill_yl, From.BOTTOM_LEFT));
        skills[id].skill = ac;
        add_child(skills[id]);
        // DTODO: set hotkeys to skillbuttons
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

    pause = new BitmapButton(
        new Geom(0, 0, skill_xl, skill_yl, From.BOTTOM_RIGHT),
        get_internal(basics.globals.file_bitmap_game_pause));

    nuke_multi = new BitmapButton(
        new Geom(0, 0, 4 * skill_xl, this.ylg - skill_yl, From.BOTTOM_RIGHT),
        get_internal(basics.globals.file_bitmap_game_nuke));

    add_child(pause);
    add_child(nuke_multi);

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



public void
set_like_tribe(in Tribe tr)
{
    if (tr is null)
        return;

    foreach (b; skills) {
        b.style  = tr.style;
        b.number = tr.skills[b.skill];
    }

    /*
    stats.set_tribe_local(tr);

    spawnint_slow.set_spawnint(tr->spawnint_slow);
    spawnint_cur .set_spawnint(tr->spawnint);
    rate_fixed   .set_number  (tr->spawnint_fast);

    nuke_single.set_on  (tr->nuke);
    nuke_multi .set_on  (tr->nuke);
    spec_tribe .set_text(tr->get_name());

    set_skill_on(skill_last_set_on);
    */

    req_draw();
}
// end function set_like_tribe()



protected override void
calc_self()
{
    _dummy_bg.down = false;
}

}
// end class Panel
