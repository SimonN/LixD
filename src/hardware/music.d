module hardware.music;

/*
 * Call hardware.sound.initialize() before you call this module's drawMusic.
 *
 * All functions in hardware.music are safe to call even when audio hasn't
 * yet been initiailized or audio initialization has failed. You merely won't
 * hear anything, but it's no error.
 */

import std.algorithm;
import std.range;

import basics.alleg5;
import glo = basics.globals;
import file.filename;
import file.io;
import file.log;
import opt = file.option.allopts;
import hardware.sound;

struct Music {
    Filename fn; // Should never be null.
    bool atAll; // if false, don't play the music and ignore other fields.
    int dbfs; // if atAll, play the music at this dB from full scale.
}

Music theMusicFor(in Filename fn) nothrow @safe @nogc
{
    return Music(fn, opt.musicEnabled.value, opt.musicDecibels.value);
}

Music theMenuMusic() nothrow @safe @nogc
{
    return theMusicFor(glo.fileMusicMenu);
}

Music someRandomMusic()
{
    return theMusicFor(someRandomFilenameFromTheMusicDir);
}

// Suggest that the given music be played. If the filename is null or the
// file doesn't exist on disk, a random music plays instead.
// If the file is unplayable, stop all music and don't play anything.
void playMusic(in Music m)
{
    ensurePlaying(m);
}

void stopMusic()
{
    if (! _music) {
        return;
    }
    assert (isAudioInitialized(), "we should land here only if we have"
        ~ " already called sound.tryInitialize before and it succeeded");
    al_destroy_audio_stream(_music);
    _music = null;
    _current = null;
}

bool isMusicPlaying() { return _music !is null; }
void deinitialize() { stopMusic(); }



///////////////////////////////////////////////////////////////////////////////
private: /////////////////////////////////////////////////////////////: private
///////////////////////////////////////////////////////////////////////////////



ALLEGRO_AUDIO_STREAM *_music = null; // Null if and only if ! _playing.atAll.
MutFilename _current; // Null if _music is null.
int _currentDbfs;

void ensurePlaying(in Music wanted)
{
    if (! wanted.atAll || ! tryInitialize) {
        stopMusic();
        return;
    }
    if (_current is null || _current.rootlessNoExt != wanted.fn.rootlessNoExt){
        playFromBeginning(wanted.fn.thisOrRandomIfIsIsBad);
        forceGain(wanted.dbfs);
        return;
    }
    if (_currentDbfs != wanted.dbfs) {
        forceGain(wanted.dbfs);
    }
}

Filename thisOrRandomIfIsIsBad(in Filename sug)
{
    if (sug is null) {
        return someRandomFilenameFromTheMusicDir();
    }
    /*
     * Re-find (sug) in a full-tree search.
     * Reason: (sug) might be extensionless, e.g., the menu music constant
     * or a music hint from a level. Output here: Always an extensionful fn.
     */
    auto files = glo.dirDataMusic.findTree()
        .filter!(fn => fn.rootlessNoExt == sug.rootlessNoExt);
    return files.empty ? someRandomFilenameFromTheMusicDir() : files.front;
}

bool isGoodRandomChoice(in Filename next)
{
    if (next is null || next.rootlessNoExt == glo.fileMusicMenu.rootlessNoExt){
        return false;
    }
    return _current is null || next.rootlessNoExt != _current.rootlessNoExt;
}

// Choose a random non-menu music from this. No suggestion.
// But avoid the currently-playing music.
Filename someRandomFilenameFromTheMusicDir()
{
    auto files = glo.dirDataMusic.findTree();
    if (files.empty) {
        return null;
    }
    import std.random : uniform;
    auto good = files.save.filter!isGoodRandomChoice;
    return good.empty
        ? files.drop(uniform(0, files.save.walkLength)).front
        : good.drop(uniform(0, good.save.walkLength)).front;
}

void playFromBeginning(in Filename next)
{
    stopMusic();
    if (next is null)
        return;
    assert (isAudioInitialized(), "we should land here only if we have"
        ~ " already called sound.tryInitialize before and it succeeded");
    _music = al_load_audio_stream(next.stringForReading.toStringz, 3, 1024);
    if (_music) {
        _current = next;
        al_set_audio_stream_playmode(_music,
            ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP);
        al_attach_audio_stream_to_mixer(_music, al_get_default_mixer());
    }
    else {
        _current = null;
        logfMusicOnce("Unplayable music `%s'.", _current);
        logAllegroSupportsFormat();
    }
}

void forceGain(in int wantedDbfs)
{
    if (! _music) {
        return;
    }
    assert (isAudioInitialized(), "we should land here only if we have"
        ~ " already called sound.tryInitialize before and it succeeded");
    al_set_audio_stream_gain(_music, dbToGain(wantedDbfs));
    _currentDbfs = wantedDbfs;
}

/*
 * formatStr should have exactly one argument %s and no other arguments.
 * We will call logf exactly when we haven't called it for that file yet.
 * We suppose that we only ever have to log one message per file, even if
 * there are several messages that hardware.music can log.
 */
void logfMusicOnce(in string formatStr, Filename fn)
{
    static bool[Filename] alreadyLogged;
    if (! fn || fn in alreadyLogged)
        return;
    alreadyLogged[fn] = true;
    logf(formatStr, fn.rootless);
}
