module basics.bench;

/* class Benchmark runs a series of independent tests, each taking a
 * fixed amount of time. Benchmark should be run once, i.e. calced, until it
 * reports exit == true. Then, users should be instructed to exit the program
 * and send in the logfile and the profiling file.
 */

import core.memory;
import std.conv;

import basics.alleg5;
import basics.demo;
import basics.globals;
import file.filename;
import game.game;
import file.log;
import level.level;
import hardware.keyboard;
import hardware.display;

class Benchmark {

    enum num_tests = 10;
    enum ticks_per_test = 10 * ticksPerSecond;

    int ticks = 0;
    int ticks_last_fps_log = 0;

    int test_id = -1;

    immutable int alticks_at_start;

    Game game;
    Demo demo;

    @property bool exit()
    {
        return ticks >= num_tests * ticks_per_test
            || keyTapped(ALLEGRO_KEY_ESCAPE);
    }

    private static int get_al_ticks()
    {
        return al_get_timer_count(basics.alleg5.timer).to!int;
    }

    this()
    {
        alticks_at_start = get_al_ticks();
        Log.log("Starting the benchmarking.");
    }

    void calc()
    {
        ticks = get_al_ticks() - alticks_at_start;
        immutable int curr_test_id = ticks / ticks_per_test;

        if (ticks >= ticks_last_fps_log + 60) {
            ticks_last_fps_log = ticks;
            Log.logf("Frames per second: %d", hardware.display.display_fps);
        }
        if (curr_test_id != test_id) {
            test_id = curr_test_id;
            prepare_test();
        }
        run_test();
    }

    void draw()
    {
        if (game) game.draw();
        if (demo) demo.draw();
    }



    private void prepare_test()
    {
        game = null;
        demo = null;

        core.memory.GC.collect();

        if (test_id >= 0 && test_id < 4) {
            string fn = "./levels/bench/" ~ (
                test_id == 0 ? "downward-reduction-4p.txt" :
                test_id == 1 ? "anyway.txt" :
                test_id == 2 ? "200-gadgets.txt" :
                               "3500-gadgets.txt");
            Log.logf("Starting test #%d: Level `%s'", test_id, fn);
            Level lv = new Level(new Filename(fn));
            assert (lv.good, "This is a bad level, aborting.");
            game = new Game(lv);
        }
        else if (test_id >= 4 && test_id < num_tests) {
            Log.logf("Starting test #%d: Demo, mode %d", test_id, test_id - 3);
            demo = new Demo(test_id - 3);
        }
    }

    private void run_test()
    {
        if (game) game.calc();
        if (demo) demo.calc();
    }

}
// end class Benchmark
