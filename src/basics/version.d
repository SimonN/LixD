module basics.versioning;

import std.string;

// convention: use year - 1000 to distinguish from C++/A4 Lix
private int  ver        = concat(1015, 03, 04, 00);
private int  ver_min    = concat(1015, 03, 04, 00);
private bool ver_stable = false;

int    get_version()       { return ver;        }
int    get_min_version()   { return ver_min;    }
bool   is_version_stable() { return ver_stable; }

string get_version_string()     { return version_to_string(ver);     }
string get_min_version_string() { return version_to_string(ver_min); }
string version_to_string(int v);



string version_to_string(int v)
{
    assert (v >= 0);
    int subday = v % 100;
    int day    = v / 100 % 100;
    int month  = v / 100 / 100 % 100;
    int year   = v / 100 / 100 / 100;

    if (subday) return format("%04d-%02d-%02d-%02", year, month, day, subday);
    else        return format("%04d-%02d-%02d",     year, month, day);
}



private int concat(int year, int month, int day, int subday)
{
    return year  * 100 * 100 * 100
     +     month * 100 * 100
     +     day   * 100
     +     subday;
}
