module game.panel;

import basics.globals;
import basics.user;
import graphic.gralib;
import gui;

class Panel : Element {

private:

    Button _dummy_bg;

public:

    @property float skill_xl() { return Geom.screen_xlg / (14 + 4); }
    @property float skill_yl() { return this.geom.ylg * 3f / 4f; }

    Button[] skills;

    // DTODO: implement two-tasks-button and replace these mockup BitmapButtons
    BitmapButton zoom, speed_back, speed_ahead, speed_fast,
                 restart, nuke_single, pause;


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

    BitmapButton new_control_button(int x, int y, int frame)
    {
        auto b = new BitmapButton(new Geom((3 - x) * skill_xl,
            y == 0 ?  0.5f * skill_yl : 0, skill_xl,
            0.5f * skill_yl, From.BOTTOM_RIGHT),
            get_internal(basics.globals.file_bitmap_game_panel));
        b.xf = frame;
        add_child(b);
        return b;
    }

    zoom        = new_control_button(0, 0,  2);
    speed_back  = new_control_button(0, 1, 10);
    speed_ahead = new_control_button(1, 1,  3);
    speed_fast  = new_control_button(2, 1,  4); // 5 if turbo is on
    restart     = new_control_button(1, 0,  8);
    nuke_single = new_control_button(2, 0,  9);

}



protected override void
calc_self()
{
    _dummy_bg.down = false;
}

}
// end class Panel
