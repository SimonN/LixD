module hardware.sound;

import basics.alleg5;
import basics.globals;
import basics.user;
import file.filename;
import file.log;
import file.search; // file exists

/*  void initialize();
 *  void deinitialize();
 *
 *  void play_loud   (in Sound);
 *  void play_quiet  (in Sound);
 *  void play_loud_if(in Sound, in bool);
 *
 *  void draw();
 *
 *      Draws all scheduled sounds. Drawing a sound == play it with the
 *      library function.
 */

enum Sound {
    NOTHING,
    DISKSAVE,    // Save a file to disk, from editor or replay
    JOIN,        // Someone joins the network

    PANEL,       // Choice of skill on the panel
    PANEL_EMPTY, // Trying to select a skill that's empty or nonpresent
    ASSIGN,      // Assignment of a skill to a lix
    CLOCK,       // Once per second played when the clock is low on time

    LETS_GO,     // Lets-go sound played after starting a level
    HATCH_OPEN,  // Entrance hatches open
    HATCH_CLOSE, // Entrance hatches close
    OBLIVION,    // Feep: lix walks/falls out of the level area
    FIRE,        // Lix catches on fire and burns to death
    WATER,       // Glug-glug: lix falls into water
    GOAL,        // Any lix enters the player's own goal
    GOAL_BAD,    // Own lix enters an opponent's goal
    YIPPIE,      // Single player: Enough lixes saved
    NUKE,        // Nuke triggered
    OVERTIME,    // Beginning of overtime. DING!

    OUCH,        // Tumbler hits the ground and becomes a stunner
    SPLAT,       // Lix splats because of high drop distance
    OHNO,        // L1-style exploder begins oh-no animation
    POP,         // L1-/L2-Exploder explodes
    BRICK,       // Builder/Platformer lays down his last three bricks
    STEEL,       // Ground remover hits steel and stops
    JUMPER,      // Jumper assignment
    CLIMBER,     // Jumper sticks against the wall and starts to climb
    BATTER_MISS, // Batter doesn't hit anything
    BATTER_HIT,  // Batter hits something

    AWARD_1,     // Player is first in multiplayer
    AWARD_2,     // Player is second or ties for first place, no super tie.
    AWARD_3,     // Player is not last, but no award_1/2, or super tie.
    AWARD_4,     // Player is last or among last, no super tie.

    MAX          // no sound, only the total number of sounds
};



void initialize()
{
    // assumes Allegro has been initialized, but audio hasn't been initialized
    if (! al_install_audio()) {
        Log.log("Allegro 5 can't install audio");
    }
    if (! al_init_acodec_addon()) {
        Log.log("Allegro 5 can't install codecs");
    }
    if (! al_reserve_samples(8)) {
        Log.log("Allegro 5 can't reserve 8 samples.");
    }

    Sample load(in string str)
    {
        return new Sample(new Filename(dirDataSound.rootful ~ str));
    }

    samples[Sound.DISKSAVE]    = load("disksave.ogg");
    samples[Sound.JOIN]        = load("join.ogg");

    samples[Sound.PANEL]       = load("panel.ogg");
    samples[Sound.PANEL_EMPTY] = load("panel_em.ogg");
    samples[Sound.ASSIGN]      = load("assign.ogg");
    samples[Sound.CLOCK]       = load("clock.ogg");

    samples[Sound.LETS_GO]     = load("lets_go.ogg");
    samples[Sound.HATCH_OPEN]  = load("hatch.ogg");
    samples[Sound.HATCH_CLOSE] = load("hatch.ogg");
    samples[Sound.OBLIVION]    = load("oblivion.ogg");
    samples[Sound.FIRE]        = load("fire.ogg");
    samples[Sound.WATER]       = load("water.ogg");
    samples[Sound.GOAL]        = load("goal.ogg");
    samples[Sound.GOAL_BAD]    = load("goal_bad.ogg");
    samples[Sound.YIPPIE]      = load("yippie.ogg");
    samples[Sound.NUKE]        = load("nuke.ogg");
    samples[Sound.OVERTIME]    = load("overtime.ogg");

    samples[Sound.OUCH]        = load("ouch.ogg");
    samples[Sound.SPLAT]       = load("splat.ogg");
    samples[Sound.OHNO]        = null; // load("ohno.ogg");
    samples[Sound.POP]         = load("pop.ogg");
    samples[Sound.BRICK]       = load("brick.ogg");
    samples[Sound.STEEL]       = load("steel.ogg");
    samples[Sound.JUMPER]      = null; // load("jumper.ogg");
    samples[Sound.CLIMBER]     = load("climber.ogg");
    samples[Sound.BATTER_MISS] = load("bat_miss.ogg");
    samples[Sound.BATTER_HIT]  = load("bat_hit.ogg");

    samples[Sound.AWARD_1]     = load("award_1.ogg");
    samples[Sound.AWARD_2]     = load("award_2.ogg");
    samples[Sound.AWARD_3]     = load("award_3.ogg");
    samples[Sound.AWARD_4]     = load("award_4.ogg");
}



void deinitialize()
{
    al_stop_samples();

    foreach (ref Sample sample; samples) {
        if (sample is null) continue;
        sample.stop();
        destroy(sample);
        sample = null;
    }

    al_uninstall_audio();
}




void play_loud(in Sound id)
{
    assert (samples[id] !is null);
    samples[id].set_loud();
}



void play_quiet(in Sound id)
{
    assert (samples[id] !is null);
    samples[id].set_quiet();
}



void play_loud_if(in Sound id, in bool loud)
{
    if (loud) samples[id].set_loud();
    else      samples[id].set_quiet();
}



void draw()
{
    foreach (ref sample; samples) {
        if (sample !is null) sample.draw();
    }
}



private Sample[Sound.MAX] samples;

private class Sample {

    this();
    this(in Filename);
    // ~this(); -- exists, see below

    const(Filename) get_filename() const { return filename; }
    bool get_unique() const        { return unique; }
    void set_unique(in bool b = true) { unique = b; }
    void set_loud  (in bool b = true) { loud   = b; }
    void set_quiet (in bool b = true) { quiet  = b; }

    void draw();
    void stop();

private:

    alias ALLEGRO_SAMPLE*   AlSamp;
    alias ALLEGRO_SAMPLE_ID PlayId;

    const(Filename) filename;
    AlSamp  sample;
    PlayId  play_id;
    bool    unique;        // if true, kill old sound before playing again
    bool    loud;          // if true, scheduled to be played normally
    bool    quiet;         // if true, scheduled to be played quietly
    bool    last_was_loud;



public:

this()
{
    filename = null;
    unique = true;
}



this(in Filename fn)
{
    filename = fn;
    unique = true;
    sample = al_load_sample(fn.rootfulZ);
    if (! sample) {
        if (! fn.file_exists())
            Log.logf("Missing sound file `%s'", fn.rootful);
        else {
            Log.logf("Can't decode sound file `%s'.", fn.rootful);
            log_ogg_error_if_necessary();
        }
    }
}



private void
log_ogg_error_if_necessary()
{
    static bool was_logged = false;
    if (! was_logged) {
        was_logged = true;
        Log.log("  Make sure this is really an .ogg file. If it is,");
        Log.log("  check if Allegro 5 has been compiled with .ogg support.");
    }
}



~this()
{
    if (sample) al_destroy_sample(sample);
    sample = null;
}



// draw plays each sample if it was scheduled by setting (loud) or (quiet)
void draw()
{
    if (! sample) return;

    // the user setting allows sound volumes between 0 and 20.
    // The setting 10 corresponds to Allegro 5's default volume of 1.0.
    // Allegro 5 can work with higher settings than 1.0.
    float our_volume() { return 1.0f * soundVolume / 10; }

    if (unique && (loud || (quiet && !last_was_loud))) {
        stop();
    }
    if (loud) {
        last_was_loud = true;
        auto b = al_play_sample(sample, our_volume(),
         ALLEGRO_AUDIO_PAN_NONE,
         1.0f, // speed factor
         ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE, &play_id);
    }
    else if (quiet) {
        last_was_loud = false;
        al_play_sample(sample, 0.25f * our_volume(),
         ALLEGRO_AUDIO_PAN_NONE,
         1.0f, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE, &play_id);
    }
    // reset the scheduling variables
    loud  = false;
    quiet = false;
}



void stop()
{
    static PlayId null_id;
    if (play_id != null_id) al_stop_sample(&play_id);
}

}
// end class Sample
