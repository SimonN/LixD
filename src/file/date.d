module file.date;

import core.stdc.time;
import std.algorithm;
import std.conv : to;
import std.range;
import std.string;
import std.typecons;

import basics.help;

alias Date = immutable(_Date);
alias MutableDate = Rebindable!(Date);

private class _Date {
private:
    int year;
    int month;
    int day;
    int hour;
    int minute;
    int second;

public:
    static immutable(typeof(this)) now()
    {
        return new immutable typeof(this)();
    }

    this(in string s) pure immutable
    {
        auto digits = s.representation
            .filter!(c => c >= '0' && c <= '9')
            .map!(c => to!int(c - '0'));
        int takeDigits(in int start, in int howMany) {
            int ret = 0;
            foreach (int digit; digits.drop(start).take(howMany))
                ret = ret * 10 + digit;
            return ret;
        }
        year = takeDigits(0, 4);
        month = takeDigits(4, 2);
        day = takeDigits(6, 2);
        hour = takeDigits(8, 2);
        minute = takeDigits(10, 2);
        second = takeDigits(12, 2);
    }

    override string toString() const
    {
        return format("%04d-%02d-%02d %02d:%02d:%02d",
            year, month, day, hour, minute, second);
    }

    string toStringForFilename() immutable
    {
        string ret = format("%04d-%02d-%02d-%02d%02d%02d",
            year, month, day, hour, minute, second);
        assert (ret == ret.escapeStringForFilename);
        return ret;
    }

    override bool opEquals(Object rhs_obj)
    {
        auto rhs = cast (typeof(this)) rhs_obj;
        return rhs !is null
            && year   == rhs.year
            && month  == rhs.month
            && day    == rhs.day
            && hour   == rhs.hour
            && minute == rhs.minute
            && second == rhs.second;
    }

    @trusted override size_t toHash() pure nothrow
    {
        return second
            + 60 * minute
            + 60 * 60 * hour
            + 60 * 60 * 24 * day
            + 60 * 60 * 24 * 31 * month
            + 60 * 60 * 24 * 31 * 12 * (year & 0x3F);
    }

    int opCmp(immutable typeof(this) rhs) immutable
    {
        return year   < rhs.year   ? -1 : year   > rhs.year   ? 1
            :  month  < rhs.month  ? -1 : month  > rhs.month  ? 1
            :  day    < rhs.day    ? -1 : day    > rhs.day    ? 1
            :  hour   < rhs.hour   ? -1 : hour   > rhs.hour   ? 1
            :  minute < rhs.minute ? -1 : minute > rhs.minute ? 1
            :  second < rhs.second ? -1 : second > rhs.second ? 1
            :  0;
    }

private:
    private this() immutable
    {
        time_t timestamp = time(null);
        tm*    loctime   = localtime(&timestamp);
        year   = loctime.tm_year + 1900;
        month  = loctime.tm_mon  +    1;
        day    = loctime.tm_mday;
        hour   = loctime.tm_hour;
        minute = loctime.tm_min;
        second = loctime.tm_sec;
    }
}

unittest {
    string s = "2018-05-02 21:08:37";
    Date d = new Date(s);
    assert (d.year == 2018);
    assert (d.month == 05);
    assert (d.second == 37);
    assert (d.toString == s);
}
