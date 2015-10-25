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

    enum numTests = 10;
    enum ticksPerTest = 10 * ticksPerSecond;

    int ticks = 0;
    int ticksLastFPSLog = 0;

    int testID = -1;

    immutable int alTicksAtStart;

    Game game;
    Demo demo;

    @property bool exit()
    {
        return ticks >= numTests * ticksPerTest
            || keyTapped(ALLEGRO_KEY_ESCAPE);
    }

    private static int getAlTicks()
    {
        return al_get_timer_count(basics.alleg5.timer).to!int;
    }

    this()
    {
        alTicksAtStart = getAlTicks();
        log("Starting the benchmarking.");
    }

    void calc()
    {
        ticks = getAlTicks() - alTicksAtStart;
        immutable int curr_testID = ticks / ticksPerTest;

        if (ticks >= ticksLastFPSLog + 60) {
            ticksLastFPSLog = ticks;
            logf("Frames per second: %d", hardware.display.displayFps);
        }
        if (curr_testID != testID) {
            testID = curr_testID;
            prepareTest();
        }
        runTest();
    }

    void draw()
    {
        if (game) game.draw();
        if (demo) demo.draw();
    }



    private void prepareTest()
    {
        game = null;
        demo = null;

        core.memory.GC.collect();

        if (testID >= 0 && testID < 4) {
            string fn = "./levels/bench/" ~ (
                testID == 0 ? "downward-reduction-4p.txt" :
                testID == 1 ? "anyway.txt" :
                testID == 2 ? "200-gadgets.txt" :
                               "3500-gadgets.txt");
            logf("Starting test #%d: Level `%s'", testID, fn);
            Level lv = new Level(new Filename(fn));
            assert (lv.good, "This is a bad level, aborting.");
            game = new Game(Runmode.INTERACTIVE, lv);
        }
        else if (testID >= 4 && testID < numTests) {
            logf("Starting test #%d: Demo, mode %d", testID, testID - 3);
            demo = new Demo(testID - 3);
        }
    }

    private void runTest()
    {
        if (game) game.calc();
        if (demo) demo.calc();
    }

}
// end class Benchmark
