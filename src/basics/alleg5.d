module basics.alleg5;

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
alias ALLEGRO_COLOR   AlCol;
alias ALLEGRO_FONT*   AlFont;

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

@property long timerTicks()
{
    return _timer ? al_get_timer_count(_timer) : 0;
}

Albit albitCreate(in int xl, in int yl)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "alleg5: create VRAM bitmap");
    return albitCreateWithFlags(xl, yl, _defaultNewBitmapFlags);
}

Albit albitMemoryCreate(in int xl, in int yl)
{
    return albitCreateWithFlags(xl, yl,
        _defaultNewBitmapFlags
        & ~ ALLEGRO_VIDEO_BITMAP
        |   ALLEGRO_MEMORY_BITMAP);
}

// This should be used only in assertions.
bool isTargetBitmap(in Albit b)
{
    return al_get_target_bitmap() == b;
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

alias LockReadWrite = LockTemplate!(ALLEGRO_LOCK_READWRITE);
alias LockReadOnly  = LockTemplate!(ALLEGRO_LOCK_READONLY);
alias LockWriteOnly = LockTemplate!(ALLEGRO_LOCK_WRITEONLY);

struct LockTemplate(alias flags)
{
    Albit albit;
    ALLEGRO_LOCKED_REGION* region;

    this(Albit b)
    {
        assert (b !is null, "can't lock a null bitmap");
        albit = b;
        region = al_lock_bitmap(albit,
            ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY, flags);
        assert (region, "error locking a bitmap, even though not null");
    }

    ~this()
    {
        if (albit)
            al_unlock_bitmap(albit);
    }
    @disable this();
    @disable this(this);
}

// ############################################################################

ALLEGRO_TIMER* _timer = null;
private int _defaultNewBitmapFlags;

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
    assert (ret);
    assert (al_get_bitmap_width (ret) == xl);
    assert (al_get_bitmap_height(ret) == yl);

    return ret;
}
