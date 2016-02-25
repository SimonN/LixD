module file.date;

import core.stdc.time;
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
        int _year, _month, _day, _hour, _minute, _second;
        int what = 0;
        foreach (const c; s) {
            immutable int digit = c - '0';
            if (what >= 14) break;
            if (c >= '0' && c <= '9') switch (what++) {
                case  0: _year   += digit * 1000; break;
                case  1: _year   += digit * 100;  break;
                case  2: _year   += digit * 10;   break;
                case  3: _year   += digit;        break;
                case  4: _month  += digit * 10;   break;
                case  5: _month  += digit;        break;
                case  6: _day    += digit * 10;   break;
                case  7: _day    += digit;        break;

                case  8: _hour   += digit * 10;   break;
                case  9: _hour   += digit;        break;
                case 10: _minute += digit * 10;   break;
                case 11: _minute += digit;        break;
                case 12: _second += digit * 10;   break;
                case 13: _second += digit;        break;
                default:                          break;
            }
        }
        year   = _year;
        month  = _month;
        day    = _day;
        hour   = _hour;
        minute = _minute;
        second = _second;
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
