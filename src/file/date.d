module file.date;

import std.string;
import std.c.time;

class Date {

    static Date now();
    this(string);

    bool opEquals(const Date rhs) const;
    int  opCmp   (const Date rhs) const;

private:

    private this() { }

    int year;
    int month;
    int day;
    int hour;
    int minute;
    int second;



public:

static Date now()
{
    long my_null = 0;
    time_t timestamp = time(&my_null);
	tm*    loctime   = localtime(&timestamp);

    Date ret   = new Date();
	ret.year   = loctime.tm_year + 1900;
	ret.month  = loctime.tm_mon  +    1;
    ret.day    = loctime.tm_mday;
    ret.hour   = loctime.tm_hour;
    ret.minute = loctime.tm_min;
    ret.second = loctime.tm_sec;

    return ret;
}



this(string s)
{
    year = month = day = hour = minute = second = 0;
    int what = 0;
    foreach (char c; s) {
        immutable int digit = c - '0';
        if (what >= 14) break;
        if (c >= '0' && c <= '9') switch (what++) {
            case  0: year   += digit * 1000; break;
            case  1: year   += digit * 100;  break;
            case  2: year   += digit * 10;   break;
            case  3: year   += digit;        break;
            case  4: month  += digit * 10;   break;
            case  5: month  += digit;        break;
            case  6: day    += digit * 10;   break;
            case  7: day    += digit;        break;

            case  8: hour   += digit * 10;   break;
            case  9: hour   += digit;        break;
            case 10: minute += digit * 10;   break;
            case 11: minute += digit;        break;
            case 12: second += digit * 10;   break;
            case 13: second += digit;        break;
            default:                         break;
        }
    }
}



override string toString() const
{
    return format("%04d-%02d-%02d %02d:%02d:%02d",
        year, month, day, hour, minute, second);
}



bool opEquals(const Date rhs) const
{
    return year   == rhs.year
     &&    month  == rhs.month
     &&    day    == rhs.day
     &&    hour   == rhs.hour
     &&    minute == rhs.minute
     &&    second == rhs.second;
}



int opCmp(const Date rhs) const
{
    return year   < rhs.year   ? -1 : year   > rhs.year   ? 1
     :     month  < rhs.month  ? -1 : month  > rhs.month  ? 1
     :     day    < rhs.day    ? -1 : day    > rhs.day    ? 1
     :     hour   < rhs.hour   ? -1 : hour   > rhs.hour   ? 1
     :     minute < rhs.minute ? -1 : minute > rhs.minute ? 1
     :     second < rhs.second ? -1 : second > rhs.second ? 1
     : 0;
}

}
// end class
