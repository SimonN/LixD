module gui.option.sound;

import std.random;
import core.stdc.string : memmove;

import basics.help;
import file.language;
import file.option;
import glo = basics.globals;
import gui;
import gui.option;
import hardware.sound;
import hardware.music;

class VolumePreviewingOption : Option {
private:
    BoolOption _wantAtAll;
    NumPickOption _dbfs;
    DecibelExamplePlayer _examplePlayer;

public:
    this(Geom g, // For both options together. We'll create two geoms within.
        in float xOffsetOfNumberOption,
        UserOption!bool aWantAtAll,
        UserOption!int aDbfs,
        DecibelExamplePlayer aExamplePlayer)
    {
        super(g);
        _wantAtAll = new BoolOption(new Geom(0, 0,
            xOffsetOfNumberOption, ylg), aWantAtAll);
        _dbfs = new NumPickOption(new Geom(xOffsetOfNumberOption, 0,
            xlg - xOffsetOfNumberOption, ylg), ourNumPickCfg(), aDbfs);
        addChildren(_wantAtAll, _dbfs);
        _examplePlayer = aExamplePlayer;
    }

    bool execute() const { return _wantAtAll.execute || _dbfs.execute; }

    override void loadValue()
    {
        _wantAtAll.loadValue();
        _dbfs.loadValue();
    }

    override void saveValue()
    {
        _wantAtAll.saveValue();
        _dbfs.saveValue();
    }

    override Lang lang() const
    {
        return _dbfs.isMouseHere ? _dbfs.lang : _wantAtAll.lang;
    }

    override void calcSelf()
    {
        if (execute) {
            if (_wantAtAll.isChecked)
                _examplePlayer.produceExampleWithDbfs(_dbfs.value);
            else
                _examplePlayer.produceSilence();
        }
    }

private:
    static auto ourNumPickCfg() pure nothrow @safe @nogc
    {
        auto ret = NumPickConfig();
        ret.digits = 3;
        ret.min = -50;
        ret.max = 20;
        ret.allowWrap = false; // Going from -50 to +20 is loud and clips.
        ret.signAlways = true;
        ret.whiteZero = true;
        return ret;
    }
}

interface DecibelExamplePlayer {
    void produceExampleWithDbfs(in int dbfs);
    void produceSilence();
}

class SoundEffectExamplePlayer : DecibelExamplePlayer {
private:
    Sound[] _queue; // front sounds have the highest pirority.

public:
    this() {
        _queue = randomShuffle([
            Sound.assignByClick, // Not assignByReplay, that's 2 dB quieter.
            Sound.LETS_GO,
            Sound.HATCH_OPEN,
            Sound.OBLIVION,
            Sound.FIRE,
            Sound.WATER,
            Sound.GOAL,
            Sound.CANT_WIN,
            Sound.YIPPIE,
            Sound.NUKE,
            Sound.OUCH,
            Sound.SPLAT,
            Sound.POP,
            Sound.BRICK,
            Sound.STEEL,
            Sound.CLIMBER,
            Sound.BATTER_MISS,
            Sound.BATTER_HIT
        ]);
    }

    void produceExampleWithDbfs(in int dbfs)
    {
        immutable int i = uniform(0, 4);
        immutable Sound chosen = _queue[i];
        /*
         * i = chosen =      2
         * _queue now:   0 1 2 3 4 5 6 7
         * Want to move:       3 4 5 6 7 (the hindmost _queue.len - i - 1)
         * To here:          3 4 5 6 7
         * Then insert:                2
         */
        memmove(_queue.ptr + i, _queue.ptr + i + 1,
            Sound.sizeof * (_queue.len - i - 1));
        _queue[$ - 1] = chosen;
        hardware.sound.playWithCustomDBFS(chosen, dbfs);
    }

    void produceSilence() {} // It's okay to keep fading sounds. Don't cut.
}

class MusicExamplePlayer : DecibelExamplePlayer {
public:
    void produceExampleWithDbfs(in int dbfs)
    {
        playMusic(Music(glo.fileMusicMenu, true, dbfs));
    }

    void produceSilence()
    {
        stopMusic();
    }
}
