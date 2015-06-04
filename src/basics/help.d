module basics.help;

import std.array;
import std.conv;
import std.math;
import std.string;
import std.utf;


// The percent operator can return a negative number, e.g. -5 % 3 == -2.
// When the desired result here is 1, not -2, use positive_mod().
int positive_mod(in int nr, in int modulo)
{
    if (modulo <= 0) return 0;
    immutable int normal_mod = nr % modulo;
    if (normal_mod >= 0) return normal_mod;
    else                 return normal_mod + modulo;
}



int even(in int x) {
    if (x % 2 == 0) return x;
    else            return x - 1;
}



// Phobos has rounding, but tiebreaks only either to the even integer,
// or away from zero. I want to tiebreak to the larger integer.
int
round_int(F)(in F f)
    if (is (F : float))
{
    return (f + 0.5f).floor.to!int;
}



string
backspace(in string str)
{
    if (str.empty) return null;
    else return str[0 .. str.length - std.utf.strideBack(str, str.length)];
}



string
user_name_escape_for_filename(in string str)
{
    // DTODO
    return str;
}



int
len(T)(in T[] arr)
{
    return arr.length.to!int;
}



void
destroy_array(T)(ref T arr)
{
    foreach (ref var; arr) {
        destroy(var);
        var = null;
    }
    destroy(arr);
    arr = null;
}
