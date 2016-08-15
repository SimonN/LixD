module hardware.sound;

import basics.alleg5;
import basics.globals;
import basics.user;
import file.filename;
import file.log;
import hardware.tharsis;

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
    SCISSORS,    // Snipping scissors when a replay is interrupted

    OUCH,        // Tumbler hits the ground and becomes a stunner
    SPLAT,       // Lix splats because of high drop distance
    POP,         // L1-/L2-Exploder explodes
    BRICK,       // Builder/Platformer lays down his last three bricks
    STEEL,       // Ground remover hits steel and stops
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
    version (tharsisprofiling)
        auto zone = Zone(profiler, "sound initialization");
    // assumes Allegro has been initialized, but audio hasn't been initialized
    if (! al_install_audio())
        log("Allegro 5 can't install audio");
    if (! al_init_acodec_addon())
        log("Allegro 5 can't install codecs");
    if (! al_reserve_samples(8))
        log("Allegro 5 can't reserve 8 samples.");

    Sample loadLazily(in string str)
    {
        return new Sample(new VfsFilename(dirDataSound.rootless ~ str));
    }

    samples[Sound.DISKSAVE]    = loadLazily("disksave.ogg");
    samples[Sound.JOIN]        = loadLazily("join.ogg");

    samples[Sound.PANEL]       = loadLazily("panel.ogg");
    samples[Sound.PANEL_EMPTY] = loadLazily("panel_em.ogg");
    samples[Sound.ASSIGN]      = loadLazily("assign.ogg");
    samples[Sound.CLOCK]       = loadLazily("clock.ogg");

    samples[Sound.LETS_GO]     = loadLazily("lets_go.ogg");
    samples[Sound.HATCH_OPEN]  = loadLazily("hatch.ogg");
    samples[Sound.HATCH_CLOSE] = loadLazily("hatch.ogg");
    samples[Sound.OBLIVION]    = loadLazily("oblivion.ogg");
    samples[Sound.FIRE]        = loadLazily("fire.ogg");
    samples[Sound.WATER]       = loadLazily("water.ogg");
    samples[Sound.GOAL]        = loadLazily("goal.ogg");
    samples[Sound.GOAL_BAD]    = loadLazily("goal_bad.ogg");
    samples[Sound.YIPPIE]      = loadLazily("yippie.ogg");
    samples[Sound.NUKE]        = loadLazily("nuke.ogg");
    samples[Sound.OVERTIME]    = loadLazily("overtime.ogg");
    samples[Sound.SCISSORS]    = loadLazily("scissors.ogg");

    samples[Sound.OUCH]        = loadLazily("ouch.ogg");
    samples[Sound.SPLAT]       = loadLazily("splat.ogg");
    samples[Sound.POP]         = loadLazily("pop.ogg");
    samples[Sound.BRICK]       = loadLazily("brick.ogg");
    samples[Sound.STEEL]       = loadLazily("steel.ogg");
    samples[Sound.CLIMBER]     = loadLazily("climber.ogg");
    samples[Sound.BATTER_MISS] = loadLazily("bat_miss.ogg");
    samples[Sound.BATTER_HIT]  = loadLazily("bat_hit.ogg");

    samples[Sound.AWARD_1]     = loadLazily("award_1.ogg");
    samples[Sound.AWARD_2]     = loadLazily("award_2.ogg");
    samples[Sound.AWARD_3]     = loadLazily("award_3.ogg");
    samples[Sound.AWARD_4]     = loadLazily("award_4.ogg");
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

void playLoud (in Sound id) { if (samples[id]) samples[id].scheduleLoud();  }
void playQuiet(in Sound id) { if (samples[id]) samples[id].scheduleQuiet(); }

void playLoudIf(in Sound id, in bool loud)
{
    if (loud) samples[id].scheduleLoud();
    else      samples[id].scheduleQuiet();
}

// Call this once per main loop, after scheduling sounds with playLoud et al.
void draw()
{
    foreach (sample; samples)
        if (sample)
            sample.draw();
}

private Sample[Sound.MAX] samples;

private class Sample {
private:
    alias ALLEGRO_SAMPLE*   AlSamp;
    alias ALLEGRO_SAMPLE_ID PlayId;

    Filename _filename;
    AlSamp _sample; // may be null if file was missing or bad file
    PlayId _playID;
    bool   _loud; // if true, scheduled to be played normally
    bool   _quiet; // if true, scheduled to be played quietly
    bool   _lastWasLoud;
    bool   _loadedFromDisk;

public:
    const(Filename) filename() const { return _filename; }
    void scheduleLoud (in bool b = true) { _loud  = b; }
    void scheduleQuiet(in bool b = true) { _quiet = b; }

    this(in Filename fn) { _filename = fn; }

    ~this()
    {
        if (_sample)
            al_destroy_sample(_sample);
        _sample = null;
        _loadedFromDisk = false;
    }

    // draw plays each sample if it was scheduled by setting (loud) or (quiet)
    void draw()
    {
        if (_loud || (_quiet && !_lastWasLoud))
            stop();
        if ((_loud || _quiet) && basics.user.soundVolume.value > 0) {
            _lastWasLoud = _loud;
            loadFromDisk();
            if (! _sample)
                return;
            al_play_sample(_sample,
                // The user setting allows sound volumes between 0 and 20.
                // Setting 10 corresponds to Allegro 5's default volume of 1.0.
                // Allegro 5 can work with higher settings than 1.0.
                (_loud ? 0.1f : 0.025f) * soundVolume,
                ALLEGRO_AUDIO_PAN_NONE, 1.0f, // speed factor
                ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE, &_playID);
        }
        // reset the scheduling variables
        _loud  = false;
        _quiet = false;
    }

    void stop()
    {
        static PlayId _nullID;
        if (_playID != _nullID)
            al_stop_sample(&_playID);
    }

private:
    void loadFromDisk()
    {
        if (_loadedFromDisk)
            return;
        _loadedFromDisk = true;
        assert (! _sample);
        _sample = al_load_sample(_filename.stringzForReading);
        if (! _sample) {
            if (! _filename.fileExists()) {
                logf("Missing sound file `%s'", _filename.rootless);
            }
            else {
                logf("Can't decode sound file `%s'.", _filename.rootless);
                static bool oggErrorLogged = false;
                if (! oggErrorLogged) {
                    oggErrorLogged = true;
                    log("    -> Make sure this is really an .ogg file. If it is,");
                    log("    -> check if Allegro 5 has been compiled with .ogg support.");
    }   }   }   }
}
// end class Sample
