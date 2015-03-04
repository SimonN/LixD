module file.filename;

import std.string;
import std.array; // property empty

// Some methods return normal D strings, which are immutable(char)[], i.e.,
// arrays. D arrays are passed as pointers to start and end.
// Some methods return immutable(char)* instead. These return pointers to
// null-terminated C-style strings. Choice of return type is designed based
// on the expected usage: null-terminated strings are for Allegro functions.

class Filename {

    this(string s);

    static void set_root_dir(string str) { if (! root) root = str.idup; }

    bool opEquals   (const Filename) const;
    int  opCmp      (const Filename) const;
    bool is_child_of(const Filename) const;

    string get_rootful()                const { return root ~ rootless;     }
    string get_rootless()               const { return rootless;            }
    string get_extension()              const { return extension;           }
    string get_rootless_no_extension()  const { return rootless_no_ext;     }
    string get_file()                   const { return file;                }
    string get_file_no_ext_no_pre_ext() const { return file_no_exts;        }
    string get_dir_rootful()            const { return root ~ dir_rootless; }
    string get_dir_rootless()           const { return dir_rootless;        }
    char   get_pre_extension()          const { return pre_extension;       }
    bool   has_image_extension()        const;

    private alias immutable(char)* Ch;
    Ch get_rootful_z()     const { return get_rootful().toStringz;     }
    Ch get_dir_rootful_z() const { return get_dir_rootful().toStringz; }

private:

    static string root;

    // We don't have the variables rootful and dir_rootful anymore.
    // Module basics.globals instatiates Filename objects before main() runs,
    // which will produce an error when compiling the non-static constructor
    // this() with { rootful = root ~ rootless; } in it: The static var
    // cannot be read at compile time. Since the call to set_root_dir() will
    // be at a later time than these instantiations, the current solution is
    // to concatenate upon each call to get_[dir_]rootful[_z]() with root.

    string rootless = "";
    string extension = "";
    string rootless_no_ext = "";
    string file = "";
    string file_no_exts = "";
    string dir_rootless = "";

    char pre_extension;



public:

this(string s)
{
    // All strings start empty, for the pre_extension we clarify:
    pre_extension = '\0';

    // Possible root dirs are "./" and "../". We erase everything from the
    // start of the filename that is '.' or '/' and call that rootless.
    int sos = 0; // start_of_rootless
    while (sos < s.length && (s[sos] == '.' || s[sos] == '/')) ++sos;
    rootless = s[sos .. $];

    // Determine the extension, this is done by finding the last '.'
    long last_dot = rootless.length - 1L;
    int extension_length = 0;
    while (last_dot >= 0 && rootless[last_dot] != '.') {
        --last_dot;
        ++extension_length;
    }
    // Now, (last_dot == -1) holds iff there is no dot in the filename.
    // Don't mistake a pre-extension (1 uppercase letter) for an extension.
    if (last_dot >= 0 && (extension_length >= 2
        || (extension_length >= 1 &&
            ! (rootless[last_dot + 1] >= 'A' && rootless[last_dot + 1] <= 'Z')
        ))) {
        extension       = rootless[last_dot .. $];
        rootless_no_ext = rootless[0 .. last_dot];
    }
    else {
        // extension stays empty
        rootless_no_ext = rootless;
    }
    // Determine the pre-extension or leave it at '\0'.
    if (last_dot >= 2 && rootless[last_dot - 2] == '.'
        && (rootless[last_dot - 1] >= 'A' && rootless[last_dot - 1] <= 'Z'))
        pre_extension = rootless[last_dot - 1];

    // Determine the file. This is done similar as finding the extension.
    long last_slash = rootless.length - 1L;
    while (last_slash >= 0 && rootless[last_slash] != '/') --last_slash;
    if (last_slash >= 0) {
        file         = rootless[last_slash + 1 .. $];
        dir_rootless = rootless[0 .. last_slash + 1];
    }
    else {
        // file stays empty
        dir_rootless = rootless;
    }

    // For file_no_exts, find the first dot in file
    file_no_exts = this.file;
    for (int i = 0; i < file.length; ++i) {
        if (file[i] == '.') {
            file_no_exts = file[0 .. i];
            break;
        }
    }
}



bool opEquals(const Filename rhs) const
{
    return (rootless == rhs.rootless);
}



int opCmp(const Filename rhs) const
{
    // I roll my own here instead of using std::string::operator <, since
    // I use the convention throughout the program that file-less directory
    // names end with '/'. The directory "abc-def/" is therefore smaller than
    // "abc/", since '-' < '/' in ASCII, but we want lexicographical sorting
    // in the program's directory listings. Thus, this function here lets
    // '/' behave as being smaller than anything.
    const size_t la = rootless.length;
    const size_t lb = rhs.rootless.length;
    for (size_t i = 0; (i < la && i < lb); ++i) {
        immutable auto a = rootless[i];
        immutable auto b = rhs.rootless[i];
        if      (a == '/' && b == '/') continue;
        else if (a == '/') return -1;
        else if (b == '/') return 1;
        else if (a < b)    return -1;
        else if (b < a)    return 1;
    }
    // If we get here, one string is an initial segment of the other.
    // The shorter string shall be smaller.
    return la > lb ?  1
         : la < lb ? -1 : 0;
}



bool is_child_of(const Filename parent) const
{
    return parent.file.empty
        && parent.rootless == rootless[0 .. parent.rootless.length];
}



bool has_image_extension() const
{
    return extension == ".png"
     ||    extension == ".bmp"
     ||    extension == ".tga"
     ||    extension == ".pcx";
}

}
// end class
