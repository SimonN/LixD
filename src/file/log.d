module file.log;

import std.stdio;

class Log {

    static void log(string str) { writeln(str); }

private:

    @disable this() {}

}
