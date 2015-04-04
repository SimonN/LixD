module basics.help;

import std.array;
import std.string;
import std.utf;

import basics.alleg5; // al_get_text_width
import graphic.textout : AlFont;

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



string
backspace(in string str)
{
    if (str.empty) return null;
    else return str[0 .. str.length - std.utf.strideBack(str, str.length)];
}



string
shorten_with_dots(string str, AlFont font, in float pixlen)
{
    int textwidth(string local_str)
    {
        return al_get_text_width(font, local_str.toStringz());
    }
    if (textwidth(str) < pixlen) return str;

    // if no return yet, now we can assume that dots must be added
    while (! str.empty && textwidth(str ~ "...") >= pixlen)
        str = backspace(str);
    return str ~= "...";
}



string
user_name_escape_for_filename(in string str)
{
    // DTODO
    return str;
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
