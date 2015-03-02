module basics.help;

// The percent operator can return a negative number, e.g. -5 % 3 == -2.
// When the desired result here is 1, not -2, use positive_mod().
int positive_mod(int nr, int modulo)
{
    if (modulo <= 0) return 0;
    else return (nr % modulo + modulo) % modulo;
}
