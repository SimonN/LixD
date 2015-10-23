module basics.alleg5;

import std.string;

import hardware.tharsis;

public import allegro5.allegro;
public import allegro5.allegro_acodec;
public import allegro5.allegro_audio;
public import allegro5.allegro_color;
public import allegro5.allegro_font;
public import allegro5.allegro_image;
public import allegro5.allegro_primitives;
public import allegro5.allegro_ttf;

alias ALLEGRO_BITMAP* Albit;
alias ALLEGRO_COLOR   AlCol;
alias ALLEGRO_FONT*   AlFont;

ALLEGRO_TIMER*        timer;

int defaultNewBitmapFlags;



private @property int flags_vram()
{
    return (defaultNewBitmapFlags & ~ ALLEGRO_MEMORY_BITMAP)
        | ALLEGRO_VIDEO_BITMAP;
}

private @property int flags_memory()
{
    return (defaultNewBitmapFlags & ~ ALLEGRO_VIDEO_BITMAP)
        | ALLEGRO_MEMORY_BITMAP;
}

Albit albitCreate(in int xl, in int yl)
{
    return albitCreateWithFlags(xl, yl, flags_vram);
}

Albit albitMemoryCreate(in int xl, in int yl)
{
    return albitCreateWithFlags(xl, yl, flags_memory);
}

private Albit albitCreateWithFlags(in int xl, in int yl, in int flags)
{
    al_set_new_bitmap_flags(flags);
    scope (exit) al_set_new_bitmap_flags(defaultNewBitmapFlags);

    Albit ret = al_create_bitmap(xl, yl);
    assert (ret);
    assert (al_get_bitmap_width (ret) == xl);
    assert (al_get_bitmap_height(ret) == yl);

    return ret;
}

Albit albitLoadFromFile(string fn)
{
    al_set_new_bitmap_flags(flags_vram);
    scope (exit)
        al_set_new_bitmap_flags(defaultNewBitmapFlags);
    return al_load_bitmap(fn.toStringz());
}

Albit albitMemoryLoadFromFile(string fn)
{
    al_set_new_bitmap_flags(flags_memory);
    scope (exit)
        al_set_new_bitmap_flags(defaultNewBitmapFlags);
    return al_load_bitmap(fn.toStringz());
}



// The following structs implement RAII.

struct DrawingTarget
{
    Albit oldTarget;

    this(Albit b)
    {
        assert (b, "can't target null bitmap");
        // al_get_target_bitmap() is very fast
        oldTarget = al_get_target_bitmap();
        if (oldTarget == b) {
            // Don't call the expensive al_set_target_bitmap().
            // Do nothing now in this(), and nothing either in ~this().
            oldTarget = null;
            return;
        }
        else
            with (Zone(profiler, "DrawingTarget.al_set_target_bitmap()"))
                al_set_target_bitmap(b);
    }

    ~this()
    {
        if (oldTarget)
            al_set_target_bitmap(oldTarget);
    }
}



struct LockReadWrite
{
    Albit albit;
    ALLEGRO_LOCKED_REGION* region;

    this(Albit b)
    {
        assert (b !is null, "can't lock a null bitmap");
        with (Zone(profiler, "al_lock_bitmap() readwrite")) {
            albit = b;
            region = al_lock_bitmap(albit,
                ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY,
                ALLEGRO_LOCK_READWRITE);
            assert (region, "error locking a bitmap, even though not null");
        }
    }

    ~this()
    {
        if (albit)
            with (Zone(profiler, "al_unlock_bitmap() readwrite"))
                al_unlock_bitmap(albit);
    }

}



struct LockReadOnly
{
    const(Albit) albit;
    ALLEGRO_LOCKED_REGION* region;

    this(const(Albit) b)
    {
        assert (b !is null, "can't lock a null bitmap");
        albit = b;
        region = al_lock_bitmap(cast (Albit) albit,
            ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY,
            ALLEGRO_LOCK_READONLY);
        assert (region, "error locking const(Albit), even though not null");
    }

    ~this()
    {
        if (albit)
            al_unlock_bitmap(cast (Albit) albit);
    }
}
