module net.server.meta;

/*
 * Metaprogramming helpers to auto-implement classes that derive from
 * Outbox/Inbox and merely forward the calls to other Outboxes/Inboxes.
 */

import std.algorithm;
import std.array;
import net.server.outbox;

/*
 * Input: (void(in A a, in B b, C c))
 * Output: in A a, in B b, C c
 */
template ParamTypesAndNames(T, string func)
{
    enum string ParamTypesAndNames
        = typeof(__traits(getOverloads, T, func))
        .stringof[6 .. $-2];
    /*
     * Here, I assumed that all methods have return type void.
     * I cut off "(void(" and the final "))".
     * I thus leave: "in PlNr receiv, Arg1 arg1, Arg2 arg2"
     */
}

/*
 * Input: (void(in A a, in B!(X, Y, Z) b, C c))
 * Output: a, b, c
 */
template ParamNamesOnly(T, string func)
{
    enum string ParamNamesOnly
        = ParamTypesAndNames!(T, func)
        .splitterBetweenTheCommasOutsideTemplateArguments
        .map!toLastWord
        .join(", ");
}

private:

auto splitterBetweenTheCommasOutsideTemplateArguments(in string arg)
{
    struct SplitterResult {
        string tail; // The unparsed remainder.
        string fr = ""; // What front() returns. Never part of tail.

        pure nothrow @safe @nogc:
        bool empty()    { sanitize(); return tail.empty && fr.empty; }
        string front()  { sanitize(); return fr; }
        void popFront() { fr = ""; /* Next call to front() will sanitize. */ }

        void sanitize() {
            if (fr != "") {
                // Already sanitized.
                return;
            }
            int parenthesesLevel = 0;
            for (int i = 0; i < tail.length; ++i) {
                if (tail[i] == '(') {
                    ++parenthesesLevel;
                }
                else if (tail[i] == ')') {
                    --parenthesesLevel;
                }
                else if (tail[i] == ',' && parenthesesLevel == 0) {
                    fr = tail[0 .. i];
                    tail = tail[i + 1 .. $];
                    return;
                }
            }
            // No comma found.
            fr = tail;
            tail = "";
        }
    }

    return SplitterResult(arg);
}

string toLastWord(string words)
{
    while (words.findSkip(" ")) {}
    return words;
}
