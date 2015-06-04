module file.filename;

import std.algorithm;
import std.string;
import std.array; // property empty
import std.conv; // to!long for string length

import basics.help;

// Some methods return normal D strings, which are immutable(char)[], i.e.,
// arrays. D arrays are passed as pointers to start and end.
// Some methods return immutable(char)* instead. These return pointers to
// null-terminated C-style strings. Choice of return type is designed based
// on the expected usage: null-terminated strings are for Allegro functions.

class Filename {

/*  pure this(in string);
 *  pure this(in Filename);
 */
    static void set_root_dir(string str) { if (! root) root = str.idup; }

/*  bool opEquals   (in Filename) const;
 *  int  opCmp      (in Filename) const;
 *  bool is_child_of(in Filename) const;
 */
    @property string rootful()            const { return root ~ _rootless;   }
    @property string rootless()           const { return _rootless;          }
    @property string extension()          const { return _extension;         }
    @property string rootless_no_ext()    const { return _rootless_no_ext;   }
    @property string file()               const { return _file;              }
    @property string file_no_ext_no_pre() const { return _file_no_exts;      }
    @property string dir_rootful()        const { return root~_dir_rootless; }
    @property string dir_rootless()       const { return _dir_rootless;      }
    @property string dir_innermost()      const { return _dir_innermost;     }
    @property char   pre_extension()      const { return _pre_extension;     }
//  bool   has_image_extension()        const;

    private alias immutable(char)* Ch;
    @property Ch rootful_z()     const { return rootful.toStringz;     }
    @property Ch dir_rootful_z() const { return dir_rootful.toStringz; }

private:

    static string root = "./";

    // We don't have the variables rootful and dir_rootful anymore.
    // Module basics.globals instatiates Filename objects before main() runs,
    // which will produce an error when compiling the non-static constructor
    // this() with { rootful = root ~ rootless; } in it: The static var
    // cannot be read at compile time. Since the call to set_root_dir() will
    // be at a later time than these instantiations, the current solution is
    // to concatenate upon each call to get_[dir_]rootful[_z]() with root.

    immutable string _rootless;
    immutable string _extension;
    immutable string _rootless_no_ext;
    immutable string _file;
    immutable string _file_no_exts;
    immutable string _dir_rootless;
    immutable string _dir_innermost;

    immutable char _pre_extension;



public:

pure this(in string s)
{
    assert (s.length < int.max);

    // All strings start empty, pre_extension is '\0'

    // Possible root dirs are "./" and "../". We erase everything from the
    // start of the filename that is '.' or '/' and call that rootless.
    int sos = 0; // start_of_rootless
    while (sos < s.length && (s[sos] == '.' || s[sos] == '/')) ++sos;
    _rootless = s[sos .. $];

    // Determine the extension, this is done by finding the last '.'
    int last_dot = _rootless.len - 1;
    int extension_length = 0;
    while (last_dot >= 0 && _rootless[last_dot] != '.') {
        --last_dot;
        ++extension_length;
    }
    // Now, (last_dot == -1) holds iff there is no dot in the filename.
    // Don't mistake a pre-extension (1 uppercase letter) for an extension.
    if (last_dot >= 0 && (extension_length >= 2
        || (extension_length >= 1 &&
            ! (_rootless[last_dot + 1] >= 'A'
            && _rootless[last_dot + 1] <= 'Z')
        ))) {
        _extension       = _rootless[last_dot .. $];
        _rootless_no_ext = _rootless[0 .. last_dot];
    }
    else {
        // extension stays empty
        _rootless_no_ext = _rootless;
    }
    // Determine the pre-extension or leave it at '\0'.
    if (last_dot >= 2 && _rootless[last_dot - 2] == '.'
        && (_rootless[last_dot - 1] >= 'A'
        &&  _rootless[last_dot - 1] <= 'Z'))
        _pre_extension = _rootless[last_dot - 1];

    // Determine the file. This is done similar as finding the extension.
    int last_slash = _rootless.len - 1;
    while (last_slash >= 0 && _rootless[last_slash] != '/')
        --last_slash;
    if (last_slash >= 0) {
        _file         = _rootless[last_slash + 1 .. $];
        _dir_rootless = _rootless[0 .. last_slash + 1];
    }
    else {
        _file         = "";
        _dir_rootless = _rootless;
    }

    // find the innermost dir, based on the now-set dir_rootless.
    // sls = "second-last slash"
    int sls = _dir_rootless.len - 1;
    // don't treat the final slash as the second-to-last slash
    if (sls >= 0 && _dir_rootless[sls] == '/')
        --sls;
    while (sls >= 0 && _dir_rootless[sls] != '/')
        --sls;
    // sls can be -1, or somewhere in the file. Start behind this.
    // Contain the trailing slash of the directory.
    _dir_innermost = _dir_rootless[sls + 1 .. $];

    // For file_no_exts, find the first dot in file
    int first_dot = 0;
    for (; first_dot < _file.length; ++first_dot) {
        if (_file[first_dot] == '.') break;
    }
    _file_no_exts = _file[0 .. first_dot];
}



pure this(in Filename fn)
{
    _rootless        = fn._rootless;
    _extension       = fn._extension;
    _rootless_no_ext = fn._rootless_no_ext;
    _file            = fn._file;
    _file_no_exts    = fn._file_no_exts;
    _dir_rootless    = fn._dir_rootless;
    _dir_innermost   = fn._dir_innermost;

    _pre_extension   = fn._pre_extension;
}



override bool
opEquals(Object rhs_obj) const
{
    const(Filename) rhs = cast (const Filename) rhs_obj;
    return rhs && this._rootless == rhs._rootless;
}



int opCmp(in Filename rhs) const
{
    // I roll my own here instead of using std::string::operator <, since
    // I use the convention throughout the program that file-less directory
    // names end with '/'. The directory "abc-def/" is therefore smaller than
    // "abc/", since '-' < '/' in ASCII, but we want lexicographical sorting
    // in the program's directory listings. Thus, this function here lets
    // '/' behave as being smaller than anything.
    const size_t la = _rootless.length;
    const size_t lb = rhs._rootless.length;
    for (size_t i = 0; (i < la && i < lb); ++i) {
        immutable auto a = _rootless[i];
        immutable auto b = rhs._rootless[i];
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



bool is_child_of(in Filename parent) const
{
    return parent._file.empty
        && parent._rootless.length <= _rootless.length
        && parent._rootless == _rootless[0 .. parent._rootless.length];
}



bool has_image_extension() const
{
    return [ ".png", ".bmp", ".tga", ".pcx",
             ".PNG", ".BMP", ".TGA", ".PCX" ].find(_extension) != null;
}

}
// end class
