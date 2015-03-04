module file.date;

import std.string;
import std.c.time;

class Date {

    this();
    this(string);

    bool opEquals(const Date rhs) const;
    int  opCmp   (const Date rhs) const;

private:

    int year;
    int month;
    int day;
    int hour;
    int minute;
    int second;



public:

this()
{
    long my_null = 0;
    time_t timestamp = time(&my_null);
	tm*    now       = localtime(&timestamp);

	year   = now.tm_year + 1900;
	month  = now.tm_mon  +    1;
    day    = now.tm_mday;
    hour   = now.tm_hour;
    minute = now.tm_min;
    second = now.tm_sec;
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



override string toString()
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
