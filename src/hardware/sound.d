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
 *  void play       (in Sound, in Loudness);
 *  void playLoud   (in Sound);
 *  void playQuiet  (in Sound);
 *  void playLoudIf(in Sound, in bool);
 *
 *  void draw();
 *
 *      Draws all scheduled sounds. Drawing a sound == play it with the
 *      library function.
 */

enum Loudness { loud, quiet }

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
        log("Allegro 5 can't install audio");
    }
    if (! al_init_acodec_addon()) {
        log("Allegro 5 can't install codecs");
    }
    if (! al_reserve_samples(8)) {
        log("Allegro 5 can't reserve 8 samples.");
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



void play(in Sound id, in Loudness loudness)
{
    final switch (loudness) {
        case Loudness.loud:  playLoud(id);  break;
        case Loudness.quiet: playQuiet(id); break;
    }
}



void playLoud(in Sound id)
{
    assert (samples[id] !is null);
    samples[id].scheduleLoud();
}



void playQuiet(in Sound id)
{
    assert (samples[id] !is null);
    samples[id].scheduleQuiet();
}



void playLoudIf(in Sound id, in bool loud)
{
    if (loud) samples[id].scheduleLoud();
    else      samples[id].scheduleQuiet();
}



void draw()
{
    foreach (ref sample; samples)
        if (sample !is null)
            sample.draw();
}



private Sample[Sound.MAX] samples;

private class Sample {

/*  this();
 *  this(in Filename);
 *  ~this();
 *
 *  void draw();
 *  void stop();
 */
    const(Filename) filename() const { return _filename; }
    @property bool unique() const    { return _unique;     }
    @property bool unique(in bool b) { return _unique = b; }
    void scheduleLoud (in bool b = true) { _loud  = b; }
    void scheduleQuiet(in bool b = true) { _quiet = b; }

private:

    alias ALLEGRO_SAMPLE*   AlSamp;
    alias ALLEGRO_SAMPLE_ID PlayId;

    const(Filename) _filename;
    AlSamp _sample;
    PlayId _playID;
    bool   _unique;        // if true, kill old sound before playing again
    bool   _loud;          // if true, scheduled to be played normally
    bool   _quiet;         // if true, scheduled to be played quietly
    bool   _lastWasLoud;



public:

this()
{
    _filename = null;
    _unique = true;
}



this(in Filename fn)
{
    _filename = fn;
    _unique = true;
    _sample = al_load_sample(fn.rootfulZ);
    if (! _sample) {
        if (! fn.fileExists()) {
            logf("Missing sound file `%s'", fn.rootful);
        }
        else {
            logf("Can't decode sound file `%s'.", fn.rootful);
            logOggErrorIfNecessary();
        }
    }
}



private void
logOggErrorIfNecessary()
{
    static bool wasLogged = false;
    if (! wasLogged) {
        wasLogged = true;
        log("    -> Make sure this is really an .ogg file. If it is,");
        log("    -> check if Allegro 5 has been compiled with .ogg support.");
    }
}



~this()
{
    if (_sample) al_destroy_sample(_sample);
    _sample = null;
}



// draw plays each sample if it was scheduled by setting (loud) or (quiet)
void draw()
{
    if (! _sample)
        return;

    // the user setting allows sound volumes between 0 and 20.
    // The setting 10 corresponds to Allegro 5's default volume of 1.0.
    // Allegro 5 can work with higher settings than 1.0.
    float ourVolume() { return 1.0f * soundVolume / 10; }

    if (_unique && (_loud || (_quiet && !_lastWasLoud))) {
        stop();
    }
    if (_loud) {
        _lastWasLoud = true;
        auto b = al_play_sample(_sample, ourVolume(),
         ALLEGRO_AUDIO_PAN_NONE,
         1.0f, // speed factor
         ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE, &_playID);
    }
    else if (_quiet) {
        _lastWasLoud = false;
        al_play_sample(_sample, 0.25f * ourVolume(),
         ALLEGRO_AUDIO_PAN_NONE,
         1.0f, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE, &_playID);
    }
    // reset the scheduling variables
    _loud  = false;
    _quiet = false;
}



void stop()
{
    static PlayId _nullID;
    if (_playID != _nullID) al_stop_sample(&_playID);
}

}
// end class Sample
