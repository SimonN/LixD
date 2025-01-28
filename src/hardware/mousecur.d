module hardware.mousecur;

/*
 * This is only for the drawable mouse cursor.
 *
 * To read mouse input, look at the module hardware.mouse instead.
 *
 * There are two Stamps: The main cursor and the sidekick graphic.
 * The sidekick graphic exists throughout, even if it's usually in its
 * empty frame (0, 0).
 */

import basics.rect;
import file.log;
import graphic.cutbit;
import graphic.internal;
static import hardware.mouse;

public MouseCursor mouseCursor;

struct MouseCursor {
private:
    Shape _shape;
    Arrows _arrows;
    Sidekick _sidekick;

public:
    enum Shape : int {
        crosshair,
        openSquare,
        trashcan,
    }

    enum Arrows : int {
        none,
        left,
        right,
        scroll,
    }

    enum Sidekick : int {
        none,
        scissors,
        insert,
    }

    void want(in Shape s) pure nothrow @safe @nogc { _shape = s; }
    void want(in Arrows a) pure nothrow @safe @nogc { _arrows = a; }
    void want(in Sidekick s) pure nothrow @safe @nogc { _sidekick = s; }

    void wantPlainCrosshair() pure nothrow @safe @nogc
    {
        want(Shape.crosshair);
        want(Arrows.none);
        want(Sidekick.none);
    }

    void draw()
    {
        const(Cutbit) mainCursor = InternalImage.mouseMain.toCutbit;
        const(Cutbit) sideCursor = InternalImage.mouseSidekick.toCutbit;
        immutable mainP = Point(
            hardware.mouse.mouseX - mainCursor.xl/2 + 1,
            hardware.mouse.mouseY - mainCursor.yl/2 + 1);
        immutable sideP = mainP + mainCursor.len + Point(1, -sideCursor.yl);
        mainCursor.drawToCurrentAlbitNotTorbit(mainP, mainXf, mainYf);
        sideCursor.drawToCurrentAlbitNotTorbit(sideP, _sidekick, 0);
    }

private:
    int mainXf() const pure nothrow @safe @nogc
    {
        final switch (_shape) {
            case Shape.crosshair: return _arrows;
            case Shape.openSquare: return _arrows;
            case Shape.trashcan: return 1;
        }
    }

    int mainYf() const pure nothrow @safe @nogc
    {
        return _shape; // Happens to work. Change to switch (_shape) if not.
    }
}
