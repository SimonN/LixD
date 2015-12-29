module basics.alleg5;

import std.conv;
import std.string;
import std.uni;
import std.utf;

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
    auto zone = Zone(profiler, "alleg5: create VRAM bitmap");
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

struct Blender
{
    private alias Bo = ALLEGRO_BLEND_OPERATIONS;
    private alias Bm = ALLEGRO_BLEND_MODE;

    this(Bo o, Bm s, Bm d)
    {
        al_set_blender(o, s, d);
    }

    this(Bo o, Bm s, Bm d, Bo ao, Bm as, Bm ad)
    {
        al_set_separate_blender(o, s, d, ao, as, ad);
    }

    ~this()
    {
        // restore default blending mode
        al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD,
                       ALLEGRO_BLEND_MODE.ALLEGRO_ONE,
                       ALLEGRO_BLEND_MODE.ALLEGRO_INVERSE_ALPHA);
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



// ############################################################################

string hotkeyNiceBrackets(in int hotkey)
{
    Zone z = Zone(profiler, "hotkeyNiceBrackets");
    if (hotkey <= 0 || ! al_is_keyboard_installed())
        return null;
    return "[" ~ hotkeyNiceShort(hotkey) ~ "]";
}

string hotkeyNiceShort(in int hotkey)
{
    string s = hotkeyNiceLong(hotkey);
    return (s.length > 3) ? s[0 .. 3] : s;
}

string hotkeyNiceLong(in int hotkey)
{
    if (hotkey <= 0 || ! al_is_keyboard_installed())
        return null;
    string s = al_keycode_to_name(hotkey).to!string;
    if (! s.length)
        return null;
    auto c = std.utf.decodeFront(s); // this cuts it off from s
    return (std.uni.toUpper(c) ~ s.to!dstring).to!string;
}
