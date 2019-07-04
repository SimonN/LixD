module game.nurse.unittest_;

/*
 * Test suite for the savestating functionality of Nurses.
 * Testing Nurses is ideal: They're right under the Game (= the UI).
 */

import basics.alleg5;
import basics.cmdargs;
import basics.globals;
import file.option : replayAfterFrameBack;
import basics.init;
import file.filename;
import game.nurse.savestat;
import file.replay;
import level.level;
import lix.lixxie;

private:

version (unittest) {
    // List all tests here
    void function()[] tests = [
        &testGithub294,
        &testLemforumTopic3541Post69225,
        &testLemforumTopic3541Post69228,
    ];

    /*
     * Regression test for github issue 294:
     * Manual savestate, sporadic replay desync
     *
     * Dig. Wait. Savestate. Framestep back to just after the digger. Bash.
     * Load the savestate. This correctly removed the basher from the physics.
     * Expected: Basher is removed from the replay, too.
     * Observed: Basher is kept in the replay, even though not in physics.
     */
    void testGithub294()
    {
        SaveStatingNurse nurse = newTestNurse();
        nurse.updateTo(Phyu(99));
        nurse.assign(Phyu(100), Ac.digger);
        assert (nurse.theLix.ac == Ac.walker,
            "I expect a long walkway in the test level");

        nurse.updateTo(Phyu(140));
        assert (nurse.theLix.ac == Ac.digger);
        nurse.saveUserState();

        nurse.framestepBackBy(21);
        nurse.assign(Phyu(120), Ac.basher);
        assert (nurse.theLix.ac == Ac.digger);
        nurse.updateTo(Phyu(120));
        assert (nurse.theLix.ac == Ac.basher);
        nurse.loadUserState();
        assert (nurse.theLix.ac == Ac.digger);

        nurse.framestepBackBy(20);
        assert (nurse.upd == 120);
        assert (nurse.theLix.ac == Ac.digger,
            "Under issue 294, this was a basher; digger is correct");
    }

    /*
     * Regression test for report in Lemmings Forums topic 3541, post 69225:
     *
     * Assign builder. Savestate. Framestep back to a phyu before the save.
     * Cancel the action that is in the savestate. Press "load savestate".
     *
     * Expected: This pressing of "load savestate" restores the builder both
     * to the physics and to the active replay.
     *
     * Observed: You have to press "load savestate" twice to get the actions
     * of the savestate back into the active replay. If you only press once
     * you get the savestates' physics, but the action isn't in the active
     * replay (click "load savestate" again to hear the snipping sound. This
     * already indicates a bug because "load savestate" should be idempotent.
     */
    void testLemforumTopic3541Post69225()
    {
        SaveStatingNurse nurse = newTestNurse();
        nurse.assign(Phyu(85), Ac.builder);
        nurse.updateTo(Phyu(100));
        assert (nurse.theLix.ac == Ac.builder,
            "Test level should have enough space to build here");
        nurse.saveUserState();

        nurse.framestepBackBy(20);
        assert (nurse.theLix.ac == Ac.walker);

        nurse.loadUserState();
        assert (nurse.theLix.ac == Ac.builder,
            "The savestated builder should be loaded back.");
        assert (nurse.constReplay.getDataForPhyu(Phyu(85)).length > 0,
            "The builder assignment should still be in the replay because"
            ~ " the builder is in the physics.");
    }

    /*
     * Regression that I never posted anywhere, but that I found after
     * replying to Lemmings Forums topic 3531, post 69225. I'll call it
     * post 69228, which is my next post where I said "I'm reasonably
     * confident." But there was still this bug left behind:
     *
     * Savestate. Assign builder. Load state.
     * Expected: This removes the builder exactly when we have enabled
     * that framestepping backwards removes undone skills.
     * Observed: This removes the builder regardless of the option.
     */
    void testLemforumTopic3541Post69228()
    {
        SaveStatingNurse nurse = newTestNurse();
        nurse.updateTo(Phyu(80));
        assert (nurse.theLix.ac == Ac.walker,
            "Test level should have enough space to walk along");
        nurse.saveUserState();
        nurse.assign(Phyu(90), Ac.builder);
        nurse.updateTo(Phyu(100));
        assert (nurse.theLix.ac == Ac.builder,
            "Test level should have enough space to build here");

        nurse.loadUserState();
        assert (nurse.theLix.ac == Ac.walker, "We savestated this walker");

        nurse.updateTo(Phyu(100));
        if (replayAfterFrameBack.value)
            assert (nurse.theLix.ac == Ac.builder, "Builder should replay.");
        else
            assert (nurse.theLix.ac == Ac.walker, "This builder should have"
                ~ "been cancelled when we stateloaded. We should be walker.");
    }

    ///////////////////////////////////////////////////////////////////////////
    // Add new tests above. Below is infrastructure that might change rarely. /
    ///////////////////////////////////////////////////////////////////////////

    SaveStatingNurse newTestNurse()
    {
        Filename fn = new VfsFilename(
            dirLevelsSingle.rootless ~ "/lemforum/Lovely/declination.txt");
        assert (fn.fileExists, "I'd like to test with Declination"
            ~ " Innovation Station, the level doesn't exist");
        Level lv = new Level(fn);
        assert (lv.playable, "Test level isn't playable");
        return new SaveStatingNurse(lv, ()
            {
                Replay rep = Replay.newForLevel(fn, lv.built);
                rep.addPlayer(PlNr(0), Style.garden, "Mr. Unittest");
                return rep;
            }(),
            new NullEffectSink);
    }

    void assign(SaveStatingNurse nurse, Phyu phyu, Ac ac)
    in { assert (nurse); }
    body {
        Ply d;
        d.player = PlNr(0);
        d.action = RepAc.ASSIGN;
        d.update = phyu;
        d.skill = ac;
        d.toWhichLix = 0;
        nurse.addPlyMaybeGoBack([d]);
    }

    const(Lixxie) theLix(Nurse nurse)
    in {
        assert (nurse);
        assert (nurse.stateOnlyPrivatelyForGame.tribes[Style.garden]
            .lixvec.length >= 1);
    }
    body {
        return nurse.stateOnlyPrivatelyForGame.tribes[Style.garden].lixvec[0];
    }

    void testWithCuttingFramesteps()
    {
        immutable bool old = replayAfterFrameBack.value;
        replayAfterFrameBack = false;
        scope (exit)
            replayAfterFrameBack = old;
        foreach (t; tests)
            t();
    }

    void testWithPreservingFramesteps()
    {
        immutable bool old = replayAfterFrameBack.value;
        replayAfterFrameBack = true;
        scope (exit)
            replayAfterFrameBack = old;
        foreach (t; tests)
            t();
    }
}

unittest {
    al_run_allegro(delegate int() {
        initializeNoninteractive(Runmode.VERIFY);
        scope (exit)
            deinitializeAfterUnittest();

        testWithCuttingFramesteps();
        testWithPreservingFramesteps();
        return 0;
    });
}
