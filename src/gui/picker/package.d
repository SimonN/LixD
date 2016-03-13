module gui.picker;

/*
class Ls;
    Knows many files to list. Knows the current dir.
    Knows how to search for files by calling with module file.search.

abstract class Tiler : Element;
    Knows how to make file buttons.
    Knows how to make dir buttons, which may be larger than file buttons.
    Has no idea about current dir.
    There is no "next" button.
    There are many concrete Penguins to implement this:
    CombinedTiler, LevelTiler, ReplayTiler, ...

class Scrollbar : Element;
    Doesn't yet know what to control. Can control itself.

class Panda : Element;
    Has a Ls.
    Has a Scrollbar.
    Has a Penguin.
    Is as large as the scrollbar placed next to the penguin.
    Knows how to update each, based on the
    other's actions. Knows how to interpret hotkeys (up/down by 1 or 5).
*/

public import gui.picker.ls;
public import gui.picker.picker;
public import gui.picker.scrollb;
public import gui.picker.tiler;
public import gui.picker.tilerimg;
public import gui.picker.tilerlev;

alias LevelPicker = Picker!LevelTiler;
alias ImagePicker = Picker!ImageTiler;
