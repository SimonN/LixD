module file.filename;

import std.string;

class Filename {

    this(string);

    immutable(char)* get_rootful() const { return rootful.toStringz; }

    string get_rootless() const { return rootless; }

private:

    string rootful;
    string rootless;



public:

this(string str)
{
    // DTODO: implement class
    rootful = rootless = str;
}

}
// end class
