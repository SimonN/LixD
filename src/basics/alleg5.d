module basics.alleg5;

import std.conv;
import std.math;
import basics.globals;
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
alias ALLEGRO_COLOR   Alcol;
alias const(ALLEGRO_FONT)* Alfont;

class OutOfVramException : Exception
{
    this(in int xl, in int yl, in int flags)
    {
        import std.format;
            super(format!("Out of video memory. Can't create bitmap"
                        ~ " of size %dx%d with flags %d.")(xl, yl, flags));
    }
}

void initializeInteractive()
{
    initOrThrow();
    _defaultNewBitmapFlags = al_get_new_bitmap_flags()
        & ~ ALLEGRO_MEMORY_BITMAP | ALLEGRO_VIDEO_BITMAP;
    _timer = al_create_timer(1.0 / basics.globals.ticksPerSecond);
    assert (_timer);
    al_start_timer(_timer);
}

void initializeNoninteractive()
{
    initOrThrow();
    // We have no display to tie bitmaps to. We require RAM bitmaps.
    _defaultNewBitmapFlags = al_get_new_bitmap_flags()
        & ~ ALLEGRO_VIDEO_BITMAP | ALLEGRO_MEMORY_BITMAP;
}

void deinitialize()
{
    if (_timer) {
        al_stop_timer(_timer);
        al_destroy_timer(_timer);
        _timer = null;
    }
    al_uninstall_system();
}

// ############################################################################

@property nothrow @nogc {
    long timerTicks() { return _timer ? al_get_timer_count(_timer) : 0; }
    int totalPixelsAllocated() { return _totalPixelsAllocated; }
    int vramAllocatedInMB() { return _totalPixelsAllocated / 1024 * 4 / 1024; }
}

string allegroDLLVersion()
{
    static string ret = "";
    if (ret == "") {
        import std.format;
        ret = format!"%d.%d.%d.%d"(al_get_allegro_version() >> 24,
            (al_get_allegro_version() >> 16) & 255,
            (al_get_allegro_version() >> 8) & 255,
            al_get_allegro_version() & 255);
    }
    return ret;
}

Albit albitCreate(in int xl, in int yl)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "alleg5: create VRAM bitmap");
    return albitCreateWithFlags(xl, yl, _defaultNewBitmapFlags);
}

void albitDestroy(Albit bmp)
{
    assert (bmp);
    if (! al_is_sub_bitmap(bmp))
        _totalPixelsAllocated -= vramConsumption(bmp);
    // I can't assert _totalPixelsAllocated >= 0 because that would crash
    // during program shutdown with invalid memory operation in druntime.
    // When I exit the game, I don't dispose VRAM, I let the OS do that.
    al_destroy_bitmap(bmp);
}

Albit albitMemoryCreate(in int xl, in int yl)
{
    return albitCreateWithFlags(xl, yl,
        _defaultNewBitmapFlags
        & ~ ALLEGRO_VIDEO_BITMAP
        |   ALLEGRO_MEMORY_BITMAP);
}

Albit albitCreateSmoothlyScalable(in int xl, in int yl)
{
    return albitCreateWithFlags(xl, yl,
        _defaultNewBitmapFlags | ALLEGRO_MIN_LINEAR | ALLEGRO_MAG_LINEAR);
}

/*
 * Wrappers around Allegro's missing const-correctness.
 * If this gets ever added in DAllgero5 {
 *      Search the source for DALLEGCONST and remove the casts.
 *      Change the following wrapper functions into aliases.
 * }
 */
@nogc nothrow {
    int xl(in Albit b) { return al_get_bitmap_width (cast (Albit) b); }
    int yl(in Albit b) { return al_get_bitmap_height(cast (Albit) b); }

    // This should be used only in assertions.
    bool isTargetBitmap(in Albit b) { return al_get_target_bitmap() == b; }
}

// The following structs implement RAII.
struct TargetBitmap
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
            al_set_target_bitmap(b);
    }

    ~this()
    {
        if (oldTarget)
            al_set_target_bitmap(oldTarget);
    }
    @disable this();
    @disable this(this);
}

struct Blender
{
    @disable this();
    @disable this(this);
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

Blender BlenderMinus()
{
    // Basher/miner/digger masks are realized with opaque white
    // (alpha = 1.0) where a deletion should occur on the land, and
    // transparent (alpha = 0.0) where no deletion should happen.
    // Therefore, choose a nonstandard blender that does:
    // target is opaque => deduct source alpha
    // target is transp => leave as-is, can't deduct any more alpha anyway
    return Blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_DEST_MINUS_SRC,
        ALLEGRO_BLEND_MODE.ALLEGRO_ONE, // subtract all of the source...
        ALLEGRO_BLEND_MODE.ALLEGRO_ONE); // ...from the target
}

Blender BlenderCopy()
{
    // Copy the source to the target, including alpha, unmodified
    return Blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD,
        ALLEGRO_BLEND_MODE.ALLEGRO_ONE, ALLEGRO_BLEND_MODE.ALLEGRO_ZERO);
}

alias LockReadWrite = LockTemplate!(ALLEGRO_LOCK_READWRITE);
alias LockReadOnly  = LockTemplate!(ALLEGRO_LOCK_READONLY);
alias LockWriteOnly = LockTemplate!(ALLEGRO_LOCK_WRITEONLY);

struct LockTemplate(alias flags) {
private:
    static if (flags == ALLEGRO_LOCK_READONLY)
        const(Albit) albit;
    else
        Albit albit;
    ALLEGRO_LOCKED_REGION* region;

public:
    this(typeof(this.albit) b)
    {
        assert (b !is null, "can't lock a null bitmap");
        albit = b;
        region = al_lock_bitmap(cast (Albit) albit,
            ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY, flags);
        assert (region, "error locking a bitmap, even though not null");
    }

    ~this()
    {
        if (albit)
            al_unlock_bitmap(cast (Albit) albit);
    }
    @disable this();
    @disable this(this);
}

// ############################################################################

ALLEGRO_TIMER* _timer = null;
private int _defaultNewBitmapFlags;
private int _totalPixelsAllocated;

private void initOrThrow()
{
    if (! al_init())
        throw new Exception("Failed to initialize Allegro 5.
            See `./doc/build/allegro5.txt' for troubleshooting.");
}

private Albit albitCreateWithFlags(in int xl, in int yl, in int flags)
{
    al_set_new_bitmap_flags(flags);
    scope (exit)
        al_set_new_bitmap_flags(_defaultNewBitmapFlags);

    Albit ret = al_create_bitmap(xl, yl);
    if (! ret)
        throw new OutOfVramException(xl, yl, flags);

    assert (al_get_bitmap_width (ret) == xl);
    assert (al_get_bitmap_height(ret) == yl);
    _totalPixelsAllocated += vramConsumption(ret);
    return ret;
}

// This is a ballpark estimation. It can underestimate the VRAM used or
// reserved by the gfx driver. Monitor the VRAM externally for exact numbers.
private int vramConsumption(Albit bmp)
{
    assert (bmp);
    immutable xl = al_get_bitmap_width(bmp);
    immutable yl = al_get_bitmap_height(bmp);

    int f(float n) { return 2^^(n.log2.ceil.to!int); }
    return f(xl * yl);
}
