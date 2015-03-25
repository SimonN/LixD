module basics.help;

import std.array;
import std.utf;

// The percent operator can return a negative number, e.g. -5 % 3 == -2.
// When the desired result here is 1, not -2, use positive_mod().
int positive_mod(in int nr, in int modulo)
{
    if (modulo <= 0) return 0;
    else return (nr % modulo + modulo) % modulo;
}



int even(in int x) {
    if (x % 2 == 0) return x;
    else            return x - 1;
}



string backspace(string str)
{
    if (str.empty) return null;
    else return str[0 .. str.length - std.utf.strideBack(str, str.length)];
}



string user_name_escape_for_filename(in string str)
{
    // DTODO
    return str;
}
