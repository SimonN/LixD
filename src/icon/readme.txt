Windows executable icons for Lix
--------------------------------

Lix ships with readily-linkable icon resources. You don't have to compile
the Windows Lix executable icon yourself. But if you'd like to recompile
the icon, here are instructions.

Compile an icon to a resource file
----------------------------------

Install MinGW 32-bit and/or 64-bit to get windres. On Arch Linux, 64-bit
windres might have as executable filename `x86_64-w64-mingw32-windres`.
I will refer to this program (either 32-bit or 64-bit) as `windres`;
replace that with your windres's real name in the following command lines.

To generate `.res` files, ensure that the icon that you want is in
`src/icon/icon.ico` and that the text file `src/icon/icon.rc` contains 1 line:
`ALLEGRO_ICON ICON icon.ico`. Enter `src/icon/` and run one or both of the
following commands to compile the resource files:

    windres icon.rc --target=pe-i386 -o win32.res
    windres icon.rc --target=pe-x86-64 -o win64.res

This generates `src/icon/win32.res` or `src/icon/win64.res`. These binary
files should be kept in the source directory. When Lix gets compiled,
these already-compiled icons will not be recompiled, but they will be linked
into the Windows executable.
