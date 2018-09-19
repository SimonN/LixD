module hardware.scrshot;

import std.format;

import basics.alleg5;
import basics.globals : dirExport;
import file.filename;
import hardware.display;
import hardware.sound;

/*
 * Call, e.g., with "screenshot" to generate ./export/screenshot-0001.png
 */
void takeScreenshot(string prefix)
{
    assert (display);
    al_save_bitmap(
        prefix.nonexistantFile().stringForWriting.toStringz,
        al_get_backbuffer(display));
    playQuiet(Sound.DISKSAVE);
}

private Filename nonexistantFile(in string prefix)
{
    foreach (int i; 0 .. 10000) {
        Filename ret = new VfsFilename(format!"%s%s-%04d.png"(
            dirExport.rootless, prefix, i));
        if (! ret.fileExists)
            return ret;
    }
    throw new Exception("You already have 10,000 screenshots named `"
        ~ prefix ~ "-####.png'. Delete some of them to make room!");
}
