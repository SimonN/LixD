module basics.arch;

/*
 * To print the information in a single line, use
 *      gameNameVersionOsAndArch
 * Example:
 *      Lix 0.1.2, Windows, 64-bit
 * This is independent of any language.
 *
 * To print the information in two lines, e.g., in the main menu, print
 *      "Version" ~ " " ~ gameVersion
 *      "for"     ~ " " ~ osAndArch
 * Example:
 *      Version 0.1.2
 *      for Windows, 64-bit
 * ...and then you can translate "Version" and "for" to different languages
 * as usual via file.language. This module basics.arch doesn't translate.
 */

import net.versioning;

enum string gameNameVersionOsAndArch = "Lix " ~ gameVersionOsAndArch;
enum string gameVersionOsAndArch = gameVersion.toString ~ ", " ~ osAndArch;
enum string osAndArch = _ourOs ~ ", "
    ~ ((void*).sizeof == 4 ? "32-bit" : "64-bit");

enum string compilerThatCompiledLix = _ourCompiler;

private:

pragma (msg, "Compiling Lix ", gameVersion().toString(),
    " with ", compilerThatCompiledLix, " for ", osAndArch, "...");

version (DigitalMars) enum _ourCompiler = "DMD";
else version (GNU) enum _ourCompiler = "GDC";
else version (LDC) enum _ourCompiler = "LDC";
else version (SDC) enum _ourCompiler = "SDC";
else {
    enum _ourCompiler = "unknown compiler";
    pragma (msg, "Lix doesn't have a compiler name string for your compiler."
        ~ " This is harmless, but it will look strange in Lix's main menu."
        ~ " Add your compiler to ./src/basics/arch.d and submit a patch!");
}

version (Windows) enum _ourOs = "Windows";
else version (linux) enum _ourOs = "Linux";
else version (OSX) enum _ourOs = "macOS";
else version (iOS) enum _ourOs = "iOS";
else version (TVOS) enum _ourOs = "tvOS";
else version (WatchOS) enum _ourOs = "watchOS";
else version (FreeBSD) enum _ourOs = "FreeBSD";
else version (OpenBSD) enum _ourOs = "OpenBSD";
else version (NetBSD) enum _ourOs = "NetBSD";
else version (DragonFlyBSD) enum _ourOs = "DragonFlyBSD";
else version (BSD) enum _ourOs = "BSD";
else version (Solaris) enum _ourOs = "Solaris";
else version (AIX) enum _ourOs = "IBM AIX";
else version (Haiku) enum _ourOs = "Haiku";
else version (SkyOS) enum _ourOs = "SkyOS";
else version (SysV3) enum _ourOs = "SystemV r3";
else version (SysV4) enum _ourOs = "SystemV r4";
else version (Hurd) enum _ourOs = "Hurd";
else version (Android) enum _ourOs = "Android";
else version (Emscripten) enum _ourOs = "Emscripten";
else version (PlayStation) enum _ourOs = "PlayStation";
else version (PlayStation4) enum _ourOs = "PlayStation 4";
else version (Cygwin) enum _ourOs = "Cygwin";
else version (MinGW) enum _ourOs = "MinGW";
else version (FreeStanding) enum _ourOs = "Bare Metal";
else {
    enum _ourOs = "unknown OS";
    pragma (msg, "Lix has no operating system name string for your OS."
        ~ " This is harmless, but it will look strange in Lix's main menu."
        ~ " Add your OS name to ./src/basics/arch.d and submit a patch!"
        ~ " List of versions: https://dlang.org/spec/version.html");
}
