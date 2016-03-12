module file.filename;

import std.algorithm;
import std.array; // property empty
import std.conv; // to!long for string length
import std.string;
import std.typecons;

import basics.help;

static Filename nullFilename;
static this() { nullFilename = new Filename(""); }

alias Filename = immutable(_Filename);
alias MutFilename = Rebindable!Filename;

private class _Filename {
private:
    static string root = "./";
    // We don't have the variables rootful and dirRootful anymore.
    // Module basics.globals instatiates Filename objects before main() runs,
    // which will produce an error when compiling the non-static constructor
    // this() with { rootful = root ~ rootless; } in it: The static var
    // cannot be read at compile time. Since the call to setRootDir() will
    // be at a later time than these instantiations, the current solution is
    // to concatenate upon each call to get_[dir_]rootful[_z]() with root.
    immutable string _rootless;
    immutable string _extension;
    immutable string _rootlessNoExt;
    immutable string _file;
    immutable string _fileNoExts;
    immutable string _dirRootless;
    immutable string _dirInnermost;
    immutable char _preExtension;

public:
    static void setRootDir(string str) { if (! root) root = str.idup; }

    @property string rootful()        immutable { return root ~ _rootless;    }
    @property string rootless()       immutable { return _rootless;           }
    @property string extension()      immutable { return _extension;          }
    @property string rootlessNoExt()  immutable { return _rootlessNoExt;      }
    @property string file()           immutable { return _file;               }
    @property string fileNoExtNoPre() immutable { return _fileNoExts;         }
    @property string dirRootful()     immutable { return root ~ _dirRootless; }
    @property string dirRootless()    immutable { return _dirRootless;        }
    @property string dirInnermost()   immutable { return _dirInnermost;       }
    @property char   preExtension()   immutable { return _preExtension;       }

    // null-terminated strings are for Allegro 5's C functions
    @property rootfulZ()    immutable { return rootful.toStringz;    }
    @property dirRootfulZ() immutable { return dirRootful.toStringz; }

    pure this(in string s) immutable
    {
        assert (s.length < int.max);
        // Possible root dirs are "./" and "../". We erase everything from the
        // start of the filename that is '.' or '/' and call that rootless.
        int sos = 0; // start_of_rootless
        while (sos < s.length && (s[sos] == '.' || s[sos] == '/')) ++sos;
        _rootless = s[sos .. $];

        // Determine the extension, this is done by finding the last '.'
        int lastDot = _rootless.len - 1;
        int extensionLength = 0;
        while (lastDot >= 0 && _rootless[lastDot] != '.') {
            --lastDot;
            ++extensionLength;
        }
        // Now, (lastDot == -1) holds iff there is no dot in the filename.
        // Don't mistake a pre-extension (1 uppercase letter) for an extension.
        if (lastDot >= 0 && (extensionLength >= 2
            || (extensionLength >= 1 &&
                ! (_rootless[lastDot + 1] >= 'A'
                && _rootless[lastDot + 1] <= 'Z')
            ))) {
            _extension     = _rootless[lastDot .. $];
            _rootlessNoExt = _rootless[0 .. lastDot];
        }
        else {
            // extension stays empty
            _rootlessNoExt = _rootless;
        }
        // Determine the pre-extension or leave it at '\0'.
        if (lastDot >= 2 && _rootless[lastDot - 2] == '.'
            && (_rootless[lastDot - 1] >= 'A'
            &&  _rootless[lastDot - 1] <= 'Z')
        ) {
            _preExtension = _rootless[lastDot - 1];
        }
        else
            _preExtension = 0;

        // Determine the file. This is done similar as finding the extension.
        int lastSlash = _rootless.len - 1;
        while (lastSlash >= 0 && _rootless[lastSlash] != '/')
            --lastSlash;
        if (lastSlash >= 0) {
            _file        = _rootless[lastSlash + 1 .. $];
            _dirRootless = _rootless[0 .. lastSlash + 1];
        }
        else {
            _file         = "";
            _dirRootless = _rootless;
        }

        // find the innermost dir, based on the now-set dirRootless.
        // sls = "second-last slash"
        int sls = _dirRootless.len - 1;
        // don't treat the final slash as the second-to-last slash
        if (sls >= 0 && _dirRootless[sls] == '/')
            --sls;
        while (sls >= 0 && _dirRootless[sls] != '/')
            --sls;
        // sls can be -1, or somewhere in the file. Start behind this.
        // Contain the trailing slash of the directory.
        _dirInnermost = _dirRootless[sls + 1 .. $];

        // For fileNoExts, find the first dot in file
        int firstDot = 0;
        for (; firstDot < _file.length; ++firstDot) {
            if (_file[firstDot] == '.') break;
        }
        _fileNoExts = _file[0 .. firstDot];
    }

    override bool
    opEquals(Object rhs_obj) const
    {
        auto rhs = cast (const typeof(this)) rhs_obj;
        return rhs && this._rootless == rhs._rootless;
    }

    @trusted override size_t toHash() const nothrow
    {
        return typeid(_rootless).getHash(&_rootless);
    }

    int opCmp(immutable typeof(this) rhs) immutable
    {
        // I roll my own here instead of using std::string::operator <, since
        // I use the convention throughout the program that file-less directory
        // names end with '/'. The directory "abc-def/" is therefore smaller
        // than "abc/", since '-' < '/' in ASCII, but we want lexicographical
        // sorting in the program's directory listings.
        // Thus, this function here makes '/' smaller than anything.
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

    bool isChildOf(immutable typeof(this) parent) immutable
    {
        return parent._file.empty
            && parent._rootless.length <= _rootless.length
            && parent._rootless == _rootless[0 .. parent._rootless.length];
    }

    bool hasImageExtension() immutable
    {
        return [ ".png", ".bmp", ".tga", ".pcx",
                 ".PNG", ".BMP", ".TGA", ".PCX" ].find(_extension) != null;
    }
}
// end class
