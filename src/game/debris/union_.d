module game.debris.union_;

/*
 * See file package.d for explanation.
 */

import std.algorithm;
import std.conv;
import std.math; // fmod, to rotate pickaxes
import std.random;
import std.typecons;

import basics.rect;
import file.filename;
import game.debris.base;
import game.debris.derived;
import graphic.color;
import graphic.internal;
import graphic.torbit;
import net.ac;
import net.style;

// Not classes. I'd like to avoid GC for many flying pixels.
// This is a struct with an untagged union for any single DebrisBase object.
struct Debris {
private:
    enum int objLen = max(
        __traits(classInstanceSize, TimedLifeDebris),
        __traits(classInstanceSize, Arrow),
        __traits(classInstanceSize, ExplosionCenter),
        __traits(classInstanceSize, ImplosionCenter),
        __traits(classInstanceSize, Pickaxe),
    );
    static assert (objLen > __traits(classInstanceSize, DebrisBase));
    void[objLen] object = void;

public:
    inout(TimedLifeDebris) asClass() inout
    {
        return cast (inout(TimedLifeDebris)) &object;
    }

    @property int timeToLive() const { return asClass.timeToLive(); }
    void calc() { asClass.calc(); }
    void draw() { asClass.draw(); }
}

template newDebris(Class)
    if (is (Class : TimedLifeDebris))
{
    Debris ctor(Args...)(Args args)
    {
        Debris d;
        emplace!(Class, Args)(d.object, args);
        return d;
    }
}
