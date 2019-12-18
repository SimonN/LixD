module game.debris.base;

/*
 * See file package.d for explanation of this hierarchy.
 */

import basics.rect;

package:

abstract class DebrisBase {
protected:
    Point foot; // Not top-left of the debris sprite! Instead relative to foot.
    int frame; // yf for flying tools, xf for the Ac on arrows

public:
    this(in Point aFoot)
    {
        foot = aFoot;
    }

    final void calc()
    {
        onCalc();
    }

    final void draw() { onDraw(); }

protected:
    void onCalc() { }
    void onDraw() { }
}

abstract class TimedLifeDebris : DebrisBase {
private:
    int _timeToLive;

public:
    this(in Point aFoot, in int ttl)
    {
        super(aFoot);
        _timeToLive = ttl;
    }

    int timeToLive() pure const @nogc nothrow { return _timeToLive; }

protected:
    void onOnCalc() { }

    final override void onCalc()
    {
        --_timeToLive;
        onOnCalc();
    }
}

abstract class GravityDebris : TimedLifeDebris {
protected:
    Point speed; // speed vector to be added to foot per frame

public:
    this(in Point aFoot, in int ttl) { super(aFoot, ttl); }

protected:
    void on3Calc() { }

    final override void onOnCalc()
    {
        foot += speed;
        if (_timeToLive % 2 == 0)
            speed += Point(0, 1);
        on3Calc();
    }
}
