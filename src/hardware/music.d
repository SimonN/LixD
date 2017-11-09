module hardware.music;

// Call hardware.sound.initialize() before you call this module's drawMusic.

import std.algorithm;
import std.range;

import basics.alleg5;
import basics.globals;
import file.filename;
import file.io;
import file.log;
import hardware.sound : logAllegroSupportsFormat, dbToGain;

static import basics.user;

// Suggest that the given music be played. If the filename is null or the
// file doesn't exist on disk, a random music plays instead.
// If the file is unplayable, stop all music and don't play anything.
void suggestMusic(in Filename fn)
{
    _sched = fn;
    _wantRandom = false;
}

void suggestRandomMusic()
{
    _sched = null;
    _wantRandom = true;
}

void stopMusic()
{
    if (_music)
        al_destroy_audio_stream(_music);
    _music = null;
    _last = null;
}

bool isMusicPlaying() { return !! _music; }
void reapplyVolumeMusic() { setGain(_last); }
void drawMusic() { loadMusicFromDisk(scheduledMusic); }
void deinitialize() { stopMusic(); }



///////////////////////////////////////////////////////////////////////////////
private: /////////////////////////////////////////////////////////////: private
///////////////////////////////////////////////////////////////////////////////



ALLEGRO_AUDIO_STREAM *_music;
MutFilename _last; // full filename including extension
MutFilename _sched; // can be a filename stub that must be extended
bool _wantRandom;

bool isAcceptableMusicExtension(in string ext) pure @nogc
{
    if (ext == filenameExtConfig)
        return false;
    return true;
}

Filename scheduledMusic()
{
    if (! basics.user.musicEnabled.value)
        return null;
    if (! _wantRandom && ! goodConcreteScheduled)
        return null;
    MutFilename ret = _sched;
    if (_wantRandom || ret && ! ret.fileExists)
        ret = resolveBySearching();
    if (ret && ! ret.fileExists) {
        logf("Missing music file `%s'.", ret.rootless);
        if (_sched == ret)
            _sched = null;
    }
    return ret;
}

bool goodConcreteScheduled()
{
    if (! _sched || _last && _last.rootless.startsWith(_sched.rootless))
        _sched = null;
    return _sched !is null;
}

Filename resolveBySearching()
{
    import std.random;
    auto files = dirDataMusic.findTree()
        .filter!(fn => fn.extension.isAcceptableMusicExtension
            && ! (_last && fn.rootless.startsWith(_last.rootless)));
    if (_sched) {
        auto cool = files
            .filter!(fn => fn.rootless.startsWith(_sched.rootless));
        if (! cool.empty)
            return cool.front;
        else
            _sched = null; // loadMusicFromDisk will set _last accordingly
    }
    if (files.empty)
        return null;
    auto notMenuMusic = files.filter!(fn =>
        fn.rootlessNoExt != fileMusicMenu.rootlessNoExt);
    if (notMenuMusic.empty)
        return files.drop(uniform(0, files.walkLength)).front;
    return notMenuMusic.drop(uniform(0, notMenuMusic.walkLength)).front;
}

void loadMusicFromDisk(in Filename fn)
{
    if (! fn)
        return;
    if (_music)
        al_destroy_audio_stream(_music);
    _music = al_load_audio_stream(fn.stringzForReading, 3, 1024);
    if (_music) {
        al_set_audio_stream_playmode(_music,
            ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP);
        al_attach_audio_stream_to_mixer(_music, al_get_default_mixer());
        setGain(fn);
    }
    else {
        logf("Unplayable music `%s'.", fn.rootless);
        logAllegroSupportsFormat();
    }
    _last = _music ? fn : null;
    _sched = null;
    _wantRandom = false;
}

void setGain(in Filename fn)
{
    if (! fn || basics.user.musicEnabled.value == false) {
        auto remember = _last;
        stopMusic(); // resets _last, but we need _last for next setGain() call
        _last = remember;
        return;
    }
    if (_last && ! _music) {
        loadMusicFromDisk(_last);
        return; // because loadMusicFromDisk calls setGain anyway
    }
    int dBFromFile = 0;
    try fillVectorFromFile(basics.globals.fileMusicGain)
            .find!(line => line.text1.length > 2
                        && fn.rootless.canFind(line.text1))
            .takeOne
            .each!(line => dBFromFile = line.nr1);
    catch (Exception)
        { } // gain file not found is OK, play everything at normal volume
    al_set_audio_stream_gain(_music,
        dbToGain(dBFromFile + basics.user.musicDecibels));
}
