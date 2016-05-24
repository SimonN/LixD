module basics.user;

/* User settings read from the user config file. This file differs from the
 * global config file, see globconf.d. Whenever the user file doesn't exist,
 * the default values from static this() are used.
 */

import std.typecons; // rebindable
import std.algorithm; // sort filenames before outputting them
import std.conv;
import std.file; // mkdirRecurse
import std.stdio;

import enumap;

import basics.alleg5;
import basics.globals;
import basics.globconf;
import basics.help;
import basics.nettypes;
import file.filename;
import file.date;
import file.io;
import file.log; // when writing to disk fails
import lix.enums;
import hardware.keynames;
import hardware.keyset;

/*  static this();
 *  void load();
 *  void save();
 *  const(Result) getLevelResult         (Filename);
 *  void          setLevelResultCarefully(Filename, Result, in int);
 */

private Result[Filename] results;

MutFilename fileLanguage;
int optionGroup = 0;

@property bool languageIsEnglish()
{
    Filename fn = fileLanguage;
    return fn == basics.globals.fileLanguageEnglish;
}

bool replayCancel      = true;
int  replayCancelAt    = 30;
int  mouseSpeed        = basics.globals.mouseStandardDivisor;
int  scrollSpeedEdge   = basics.globals.mouseStandardDivisor / 2;
int  scrollSpeedClick  = basics.globals.mouseStandardDivisor / 2;
bool avoidBuilderQueuing   = true;
bool avoidBatterToExploder = false;

int  soundVolume       = 10;

bool screenWindowed    = false;
int  screenWindowedX   = 640;
int  screenWindowedY   = 480;

bool arrowsReplay      = true;
bool arrowsNetwork     = true;
bool paintTorusSeams   = true;
bool ingameTooltips    = true;
bool showButtonHotkeys = true;

int  guiColorRed      = 0x60;
int  guiColorGreen    = 0x80;
int  guiColorBlue     = 0xB0;

bool editorHexLevelSize  = false;
int  editorGridSelected  = 1;
int  editorGridCustom    = 8;

bool replayAutoSolutions = true;
bool replayAutoMulti     = true;

MutFilename singleLastLevel;
MutFilename networkLastLevel;
MutFilename replayLastLevel;

Style    networkLastStyle = Style.red;

MutFilename editorLastDirTerrain;
MutFilename editorLastDirSteel;
MutFilename editorLastDirHatch;
MutFilename editorLastDirGoal;
MutFilename editorLastDirDeco;
MutFilename editorLastDirHazard;

@property const(Ac[14]) skillSort() { return _skillSort; }

private Ac[14] _skillSort = [
    Ac.walker,
    Ac.jumper,
    Ac.runner,
    Ac.climber,
    Ac.floater,
    Ac.batter,
    Ac.exploder,
    Ac.blocker,
    Ac.cuber,
    Ac.builder,
    Ac.platformer,
    Ac.basher,
    Ac.miner,
    Ac.digger
];

KeySet keyForceLeft       = KeySet(ALLEGRO_KEY_S);
KeySet keyForceRight      = KeySet(ALLEGRO_KEY_F);
KeySet keyScroll          = KeySet(hardware.keynames.keyRMB);
KeySet keyPriorityInvert  = KeySet(hardware.keynames.keyRMB);
KeySet keyPause1          = KeySet(ALLEGRO_KEY_SPACE);
KeySet keyPause2          = KeySet(hardware.keynames.keyMMB);
KeySet keyFrameBackMany   = KeySet(ALLEGRO_KEY_1);
KeySet keyFrameBackOne    = KeySet(ALLEGRO_KEY_2);
KeySet keyFrameAheadOne   = KeySet(ALLEGRO_KEY_3);
KeySet keyFrameAheadMany  = KeySet(ALLEGRO_KEY_6);
KeySet keySpeedFast       = KeySet(ALLEGRO_KEY_4);
KeySet keySpeedTurbo      = KeySet(ALLEGRO_KEY_5);
KeySet keyRestart         = KeySet(ALLEGRO_KEY_F1);
KeySet keyStateLoad       = KeySet(ALLEGRO_KEY_F2);
KeySet keyStateSave       = KeySet(ALLEGRO_KEY_F3);
KeySet keyZoomIn          = KeySet(hardware.keynames.keyWheelUp);
KeySet keyZoomOut         = KeySet(hardware.keynames.keyWheelDown);
KeySet keyNuke            = KeySet(ALLEGRO_KEY_F12);
KeySet keySpecTribe       = KeySet(ALLEGRO_KEY_TAB);
KeySet keyChat            = KeySet(ALLEGRO_KEY_ENTER);
KeySet keyGameExit        = KeySet(ALLEGRO_KEY_ESCAPE);

KeySet keyMenuOkay        = KeySet(ALLEGRO_KEY_SPACE);
KeySet keyMenuEdit        = KeySet(ALLEGRO_KEY_F);
KeySet keyMenuExport      = KeySet(ALLEGRO_KEY_R);
KeySet keyMenuDelete      = KeySet(ALLEGRO_KEY_G);
KeySet keyMenuUpDir       = KeySet(ALLEGRO_KEY_A);
KeySet keyMenuUpBy1       = KeySet(ALLEGRO_KEY_S);
KeySet keyMenuUpBy5       = KeySet(ALLEGRO_KEY_W);
KeySet keyMenuDownBy1     = KeySet(ALLEGRO_KEY_D);
KeySet keyMenuDownBy5     = KeySet(ALLEGRO_KEY_E);
KeySet keyMenuExit        = KeySet(ALLEGRO_KEY_ESCAPE);
KeySet keyMenuMainSingle  = KeySet(ALLEGRO_KEY_F);
KeySet keyMenuMainNetwork = KeySet(ALLEGRO_KEY_D);
KeySet keyMenuMainReplays = KeySet(ALLEGRO_KEY_S);
KeySet keyMenuMainOptions = KeySet(ALLEGRO_KEY_A);

KeySet keyEditorLeft        = KeySet(ALLEGRO_KEY_S);
KeySet keyEditorRight       = KeySet(ALLEGRO_KEY_F);
KeySet keyEditorUp          = KeySet(ALLEGRO_KEY_E);
KeySet keyEditorDown        = KeySet(ALLEGRO_KEY_D);
KeySet keyEditorCopy        = KeySet(ALLEGRO_KEY_A);
KeySet keyEditorDelete      = KeySet(ALLEGRO_KEY_G);
KeySet keyEditorGrid        = KeySet(ALLEGRO_KEY_C);
KeySet keyEditorSelectAll   = KeySet(ALLEGRO_KEY_ALT);
KeySet keyEditorSelectFrame = KeySet(ALLEGRO_KEY_LSHIFT);
KeySet keyEditorSelectAdd   = KeySet(ALLEGRO_KEY_V);
KeySet keyEditorBackground  = KeySet(ALLEGRO_KEY_T);
KeySet keyEditorForeground  = KeySet(ALLEGRO_KEY_B);
KeySet keyEditorMirror      = KeySet(ALLEGRO_KEY_W);
KeySet keyEditorRotate      = KeySet(ALLEGRO_KEY_R);
KeySet keyEditorDark        = KeySet(ALLEGRO_KEY_N);
KeySet keyEditorAddTerrain  = KeySet(ALLEGRO_KEY_SPACE);
KeySet keyEditorAddSteel    = KeySet(ALLEGRO_KEY_TAB);
KeySet keyEditorAddHatch    = KeySet(ALLEGRO_KEY_1);
KeySet keyEditorAddGoal     = KeySet(ALLEGRO_KEY_2);
KeySet keyEditorAddDeco     = KeySet(ALLEGRO_KEY_3);
KeySet keyEditorAddHazard   = KeySet(ALLEGRO_KEY_4);
KeySet keyEditorExit        = KeySet(ALLEGRO_KEY_ESCAPE);
KeySet keyEditorMenuConstants = KeySet(ALLEGRO_KEY_Q);
KeySet keyEditorMenuTopology  = KeySet(ALLEGRO_KEY_5);
KeySet keyEditorMenuLooks     = KeySet();
KeySet keyEditorMenuSkills    = KeySet(ALLEGRO_KEY_X);

Enumap!(Ac, KeySet) keySkill;

static this()
{
    fileLanguage            = fileLanguageEnglish;

    keySkill[Ac.walker]     = KeySet(ALLEGRO_KEY_D);
    keySkill[Ac.runner]     = KeySet(ALLEGRO_KEY_LSHIFT);
    keySkill[Ac.basher]     = KeySet(ALLEGRO_KEY_E);
    keySkill[Ac.builder]    = KeySet(ALLEGRO_KEY_A);
    keySkill[Ac.platformer] = KeySet(ALLEGRO_KEY_T);
    keySkill[Ac.digger]     = KeySet(ALLEGRO_KEY_W);
    keySkill[Ac.miner]      = KeySet(ALLEGRO_KEY_G);
    keySkill[Ac.blocker]    = KeySet(ALLEGRO_KEY_X);
    keySkill[Ac.cuber]      = KeySet(ALLEGRO_KEY_X);
    keySkill[Ac.exploder]   = KeySet(ALLEGRO_KEY_V);

    keySkill[Ac.climber]    = KeySet(ALLEGRO_KEY_B);
    keySkill[Ac.floater]    = KeySet(ALLEGRO_KEY_Q);
    keySkill[Ac.jumper]     = KeySet(ALLEGRO_KEY_R);
    keySkill[Ac.batter]     = KeySet(ALLEGRO_KEY_C);

    singleLastLevel  = dirLevelsSingle;
    networkLastLevel = dirLevelsNetwork;
    replayLastLevel  = dirReplays;

    editorLastDirTerrain = dirImages;
    editorLastDirSteel   = dirImages;
    editorLastDirHatch   = dirImages;
    editorLastDirGoal    = dirImages;
    editorLastDirDeco    = dirImages;
    editorLastDirHazard  = dirImages;
}

// ############################################################################

class Result {
    const(Date) built;
    int    lixSaved;
    int    skillsUsed;
    Update updatesUsed;

    this (const(Date) bu)
    {
        built = bu;
    }

    int opEquals(in Result rhs) const
    {
        return built       == rhs.built
            && lixSaved    == rhs.lixSaved
            && skillsUsed  == rhs.skillsUsed
            && updatesUsed == rhs.updatesUsed;
    }

    // Returns < 0 on a worse rhs result, > 0 for a better rhs result.
    // The user wouldn't want to replace an old solving result with
    // a new-built-using non-solving result.
    // To check in results into the database of solved levels, use
    // setLevelResult() from this module.
    int opCmp(in Result rhs) const
    {
        if (lixSaved != rhs.lixSaved)
            return lixSaved - rhs.lixSaved; // more lix saved is better
        if (skillsUsed != rhs.skillsUsed)
            return rhs.skillsUsed - skillsUsed; // fewer skills used is better
        if (updatesUsed != rhs.updatesUsed)
            return rhs.updatesUsed - updatesUsed; // less time taken is better
        return built.opCmp(rhs.built); // newer result better
    }

    unittest {
        Result a = new Result(Date.now());
        Result b = new Result(Date.now());
        a.lixSaved = 4;
        b.lixSaved = 5;
        assert (b > a);
        b.lixSaved = 4;
        assert (a >= b);
        b.updatesUsed = 1;
        assert (a > b);
    }
}

const(Result) getLevelResult(in Filename fn)
{
    Result* ret = (rebindable!(const Filename)(fn) in results);
    return ret ? (*ret) : null;
}

void setLevelResult(
    in Filename _fn,
    Result r,
) {
    auto fn = rebindable!(const Filename)(_fn);
    auto savedResult = (fn in results);
    if (savedResult is null
        || savedResult.built != r.built
        || *savedResult < r)
        results[fn] = r;
}

// ############################################################################

private Filename userFileName()
{
    return new Filename(dirDataUser.dirRootful
     ~ basics.help.escapeStringForFilename(userName)
     ~ filenameExtConfig);
}


void load()
{
    if (userName == null) {
        // This happens upon first start after installation.
        // Don't try to load anything, and don't log anything.
        return;
    }

    while (basics.globconf.userName.length > playerNameMaxLength) {
        userName = basics.help.backspace(userName);
    }

    IoLine[] lines;

    try {
        lines = fillVectorFromFile(userFileName());
    }
    catch (Exception e) {
        log("Can't load user configuration for `" ~ userName ~ "':");
        log("    -> " ~ e.msg);
        log("    -> Falling back to the unescaped filename `"
            ~ userName ~ filenameExtConfig ~ "'.");
        try {
            lines = fillVectorFromFile(new Filename(
                dirDataUser.dirRootful ~ userName ~ filenameExtConfig));
        }
        catch (Exception e) {
            log("    -> " ~ e.msg);
            log("    -> " ~ "Falling back to the default user configuration.");
            lines = null;
        }
    }

    results = null;

    foreach (i; lines) switch (i.type) {

    case '$':
        if      (i.text1 == userLanguage            ) fileLanguage     = new Filename(i.text2);

        else if (i.text1 == userSingleLastLevel     ) singleLastLevel  = new Filename(i.text2);
        else if (i.text1 == userNetworkLastLevel    ) networkLastLevel = new Filename(i.text2);
        else if (i.text1 == userReplayLastLevel     ) replayLastLevel  = new Filename(i.text2);

        else if (i.text1 == userEditorLastDirTerrain) editorLastDirTerrain = new Filename(i.text2);
        else if (i.text1 == userEditorLastDirSteel  ) editorLastDirSteel   = new Filename(i.text2);
        else if (i.text1 == userEditorLastDirHatch  ) editorLastDirHatch   = new Filename(i.text2);
        else if (i.text1 == userEditorLastDirGoal   ) editorLastDirGoal    = new Filename(i.text2);
        else if (i.text1 == userEditorLastDirDeco   ) editorLastDirDeco    = new Filename(i.text2);
        else if (i.text1 == userEditorLastDirHazard ) editorLastDirHazard  = new Filename(i.text2);
        break;

    case '#':
        if      (i.text1 == userOptionGroup         ) optionGroup          = i.nr1;

        else if (i.text1 == userMouseSpeed          ) mouseSpeed           = i.nr1;
        else if (i.text1 == userScrollSpeedEdge     ) scrollSpeedEdge      = i.nr1;
        else if (i.text1 == userScrollSpeedClick    ) scrollSpeedClick     = i.nr1;
        else if (i.text1 == userReplayCancel        ) replayCancel         = i.nr1 > 0;
        else if (i.text1 == userReplayCancelAt      ) replayCancelAt       = i.nr1;
        else if (i.text1 == userAvoidBuilderQueuing ) avoidBuilderQueuing  = i.nr1 > 0;
        else if (i.text1 == userAvoidBatterToExploder) avoidBatterToExploder = i.nr1 > 0;

        else if (i.text1 == userScreenWindowed) screenWindowed = i.nr1 > 0;
        else if (i.text1 == userScreenWindowedX) screenWindowedX = i.nr1;
        else if (i.text1 == userScreenWindowedY) screenWindowedY = i.nr1;
        else if (i.text1 == userArrowsReplay  ) arrowsReplay   = i.nr1 > 0;
        else if (i.text1 == userArrowsNetwork ) arrowsNetwork  = i.nr1 > 0;
        else if (i.text1 == userPaintTorusSeams ) paintTorusSeams = i.nr1 > 0;
        else if (i.text1 == userIngameTooltips) ingameTooltips = i.nr1 > 0;
        else if (i.text1 == userShowButtonHotkeys) showButtonHotkeys = i.nr1 > 0;
        else if (i.text1 == userGuiColorRed   ) guiColorRed    = i.nr1;
        else if (i.text1 == userGuiColorGreen ) guiColorGreen  = i.nr1;
        else if (i.text1 == userGuiColorBlue  ) guiColorBlue   = i.nr1;
        else if (i.text1 == userSoundVolume   ) soundVolume    = i.nr1;

        else if (i.text1 == userReplayAutoSolutions) replayAutoSolutions = i.nr1 > 0;
        else if (i.text1 == userReplayAutoMulti    ) replayAutoMulti     = i.nr1 > 0;

        else if (i.text1 == userEditorHexLevelSize) editorHexLevelSize = i.nr1 > 0;
        else if (i.text1 == userEditorGridSelected) editorGridSelected = i.nr1;
        else if (i.text1 == userEditorGridCustom  ) editorGridCustom   = i.nr1;

        else if (i.text1 == userNetworkLastStyle) {
            try networkLastStyle = to!Style(i.nr1);
            catch (ConvException e)           networkLastStyle = Style.red;
            if (networkLastStyle < Style.red) networkLastStyle = Style.red;
        }

        else if (i.text1 == userKeyForceLeft     ) keyForceLeft      = KeySet(i.nr1);
        else if (i.text1 == userKeyForceRight    ) keyForceRight     = KeySet(i.nr1);
        else if (i.text1 == userKeyScroll        ) keyScroll         = KeySet(i.nr1);
        else if (i.text1 == userKeyPriorityInvert) keyPriorityInvert = KeySet(i.nr1);
        else if (i.text1 == userKeyPause1        ) keyPause1         = KeySet(i.nr1);
        else if (i.text1 == userKeyPause2        ) keyPause2         = KeySet(i.nr1);
        else if (i.text1 == userKeyFrameBackMany ) keyFrameBackMany  = KeySet(i.nr1);
        else if (i.text1 == userKeyFrameBackOne  ) keyFrameBackOne   = KeySet(i.nr1);
        else if (i.text1 == userKeyFrameAheadOne ) keyFrameAheadOne  = KeySet(i.nr1);
        else if (i.text1 == userKeyFrameAheadMany) keyFrameAheadMany = KeySet(i.nr1);
        else if (i.text1 == userKeySpeedFast     ) keySpeedFast      = KeySet(i.nr1);
        else if (i.text1 == userKeySpeedTurbo    ) keySpeedTurbo     = KeySet(i.nr1);
        else if (i.text1 == userKeyRestart       ) keyRestart        = KeySet(i.nr1);
        else if (i.text1 == userKeyStateLoad     ) keyStateLoad      = KeySet(i.nr1);
        else if (i.text1 == userKeyStateSave     ) keyStateSave      = KeySet(i.nr1);
        else if (i.text1 == userKeyZoomIn        ) keyZoomIn         = KeySet(i.nr1);
        else if (i.text1 == userKeyZoomOut       ) keyZoomOut        = KeySet(i.nr1);
        else if (i.text1 == userKeyNuke          ) keyNuke           = KeySet(i.nr1);
        else if (i.text1 == userKeySpecTribe     ) keySpecTribe      = KeySet(i.nr1);
        else if (i.text1 == userKeyChat          ) keyChat           = KeySet(i.nr1);
        else if (i.text1 == userKeyGameExit      ) keyGameExit       = KeySet(i.nr1);

        else if (i.text1 == userKeyMenuOkay       ) keyMenuOkay        = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuEdit       ) keyMenuEdit        = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuExport     ) keyMenuExport      = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuDelete     ) keyMenuDelete      = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuUpDir      ) keyMenuUpDir       = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuUpBy1      ) keyMenuUpBy1       = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuUpBy5      ) keyMenuUpBy5       = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuDownBy1    ) keyMenuDownBy1     = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuDownBy5    ) keyMenuDownBy5     = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuExit       ) keyMenuExit        = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuMainSingle ) keyMenuMainSingle  = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuMainNetwork) keyMenuMainNetwork = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuMainReplays) keyMenuMainReplays = KeySet(i.nr1);
        else if (i.text1 == userKeyMenuMainOptions) keyMenuMainOptions = KeySet(i.nr1);

        else if (i.text1 == userKeyEditorLeft       ) keyEditorLeft        = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorRight      ) keyEditorRight       = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorUp         ) keyEditorUp          = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorDown       ) keyEditorDown        = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorCopy       ) keyEditorCopy        = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorDelete     ) keyEditorDelete      = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorGrid       ) keyEditorGrid        = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorSelectAll  ) keyEditorSelectAll   = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorSelectFrame) keyEditorSelectFrame = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorSelectAdd  ) keyEditorSelectAdd   = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorBackground ) keyEditorBackground  = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorForeground ) keyEditorForeground  = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorMirror     ) keyEditorMirror      = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorRotate     ) keyEditorRotate      = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorDark       ) keyEditorDark        = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorAddTerrain ) keyEditorAddTerrain  = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorAddSteel   ) keyEditorAddSteel    = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorAddHatch   ) keyEditorAddHatch    = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorAddGoal    ) keyEditorAddGoal     = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorAddDeco    ) keyEditorAddDeco     = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorAddHazard  ) keyEditorAddHazard   = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorMenuConstants) keyEditorMenuConstants = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorMenuTopology ) keyEditorMenuTopology  = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorMenuLooks    ) keyEditorMenuLooks     = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorMenuSkills   ) keyEditorMenuSkills    = KeySet(i.nr1);
        else if (i.text1 == userKeyEditorExit         ) keyEditorExit          = KeySet(i.nr1);

        else {
            Ac ac = stringToAc(i.text1);
            if (ac != Ac.max) keySkill[ac] = KeySet(i.nr1);
        }
        break;

    case '<': {
        auto fn = rebindable!(const Filename)(new Filename(i.text1));
        Result read = new Result(new Date(i.text2));
        read.lixSaved    = i.nr1;
        read.skillsUsed  = i.nr2;
        read.updatesUsed = Update(i.nr3);
        Result* old = (fn in results);
        if (! old || *old < read)
            results[fn] = read;
        break; }

    default:
        break;

    }
}



nothrow void save()
{
    if (userName == null) {
        log("User name is empty. User configuration will not be saved.");
        return;
    }
    else if (userName.escapeStringForFilename == null) {
        log("Can't save user configuration for user `" ~ "':");
        log("    -> None of these characters are allowed in filenames.");
    }
    try {
        auto ufn = userFileName();
        mkdirRecurse(ufn.dirRootful);
        std.stdio.File f = File(ufn.rootful, "w");

        void fwr(in IoLine line)
        {
            f.writeln(line);
            f.flush();
        }

        void fwrKey(in string name, in KeySet set)
        {
            fwr(IoLine.Hash(name, set.kludgeFirstEntry));
        }

        fwr(IoLine.Dollar(userLanguage, fileLanguage.rootless));
        fwr(IoLine.Hash(userOptionGroup, optionGroup));
        f.writeln();

        fwr(IoLine.Hash(userMouseSpeed,             mouseSpeed));
        fwr(IoLine.Hash(userScrollSpeedEdge,        scrollSpeedEdge));
        fwr(IoLine.Hash(userScrollSpeedClick,       scrollSpeedClick));
        fwr(IoLine.Hash(userReplayCancel,           replayCancel));
        fwr(IoLine.Hash(userReplayCancelAt,         replayCancelAt));
        fwr(IoLine.Hash(userAvoidBuilderQueuing,    avoidBuilderQueuing));
        fwr(IoLine.Hash(userAvoidBatterToExploder,  avoidBatterToExploder));
        f.writeln();

        fwr(IoLine.Hash(userScreenWindowed,         screenWindowed));
        fwr(IoLine.Hash(userScreenWindowedX,        screenWindowedX));
        fwr(IoLine.Hash(userScreenWindowedY,        screenWindowedY));
        fwr(IoLine.Hash(userArrowsReplay,           arrowsReplay));
        fwr(IoLine.Hash(userArrowsNetwork,          arrowsNetwork));
        fwr(IoLine.Hash(userPaintTorusSeams,        paintTorusSeams));
        fwr(IoLine.Hash(userIngameTooltips,         ingameTooltips));
        fwr(IoLine.Hash(userShowButtonHotkeys,      showButtonHotkeys));
        fwr(IoLine.Hash(userGuiColorRed,            guiColorRed));
        fwr(IoLine.Hash(userGuiColorGreen,          guiColorGreen));
        fwr(IoLine.Hash(userGuiColorBlue,           guiColorBlue));
        f.writeln();

        fwr(IoLine.Hash(userSoundVolume,            soundVolume));
        f.writeln();

        fwr(IoLine.Hash(userReplayAutoSolutions,    replayAutoSolutions));
        fwr(IoLine.Hash(userReplayAutoMulti,        replayAutoMulti));
        f.writeln();

        fwr(IoLine.Hash(userEditorHexLevelSize,     editorHexLevelSize));
        fwr(IoLine.Hash(userEditorGridSelected,     editorGridSelected));
        fwr(IoLine.Hash(userEditorGridCustom,       editorGridCustom));
        f.writeln();

        fwr(IoLine.Dollar(userSingleLastLevel,        singleLastLevel.rootless));
        fwr(IoLine.Dollar(userNetworkLastLevel,       networkLastLevel.rootless));
        fwr(IoLine.Dollar(userReplayLastLevel,        replayLastLevel.rootless));
        fwr(IoLine.Hash(userNetworkLastStyle,         networkLastStyle));
        f.writeln();

        fwr(IoLine.Dollar(userEditorLastDirTerrain, editorLastDirTerrain.rootless));
        fwr(IoLine.Dollar(userEditorLastDirSteel,   editorLastDirSteel.rootless));
        fwr(IoLine.Dollar(userEditorLastDirHatch,   editorLastDirHatch.rootless));
        fwr(IoLine.Dollar(userEditorLastDirGoal,    editorLastDirGoal.rootless));
        fwr(IoLine.Dollar(userEditorLastDirDeco,    editorLastDirDeco.rootless));
        fwr(IoLine.Dollar(userEditorLastDirHazard,  editorLastDirHazard.rootless));
        f.writeln();

        fwrKey(userKeyForceLeft,      keyForceLeft);
        fwrKey(userKeyForceRight,     keyForceRight);
        fwrKey(userKeyScroll,         keyScroll);
        fwrKey(userKeyPriorityInvert, keyPriorityInvert);
        fwrKey(userKeyPause1,         keyPause1);
        fwrKey(userKeyPause2,         keyPause2);
        fwrKey(userKeyFrameBackMany,  keyFrameBackMany);
        fwrKey(userKeyFrameBackOne,   keyFrameBackOne);
        fwrKey(userKeyFrameAheadOne,  keyFrameAheadOne);
        fwrKey(userKeyFrameAheadMany, keyFrameAheadMany);
        fwrKey(userKeySpeedFast,      keySpeedFast);
        fwrKey(userKeySpeedTurbo,     keySpeedTurbo);
        fwrKey(userKeyRestart,        keyRestart);
        fwrKey(userKeyStateLoad,      keyStateLoad);
        fwrKey(userKeyStateSave,      keyStateSave);
        fwrKey(userKeyZoomIn,         keyZoomIn);
        fwrKey(userKeyZoomOut,        keyZoomOut);
        fwrKey(userKeyNuke,           keyNuke);
        fwrKey(userKeySpecTribe,      keySpecTribe);
        fwrKey(userKeyChat,           keyChat);
        fwrKey(userKeyGameExit,       keyGameExit);

        foreach (Ac ac, KeySet mappedKey; keySkill)
            if (! mappedKey.empty)
                fwrKey(acToString(ac), mappedKey);
        f.writeln();

        fwrKey(userKeyMenuOkay,          keyMenuOkay);
        fwrKey(userKeyMenuEdit,          keyMenuEdit);
        fwrKey(userKeyMenuExport,        keyMenuExport);
        fwrKey(userKeyMenuDelete,        keyMenuDelete);
        fwrKey(userKeyMenuUpDir,         keyMenuUpDir);
        fwrKey(userKeyMenuUpBy1,         keyMenuUpBy1);
        fwrKey(userKeyMenuUpBy5,         keyMenuUpBy5);
        fwrKey(userKeyMenuDownBy1,       keyMenuDownBy1);
        fwrKey(userKeyMenuDownBy5,       keyMenuDownBy5);
        fwrKey(userKeyMenuExit,          keyMenuExit);
        fwrKey(userKeyMenuMainSingle,    keyMenuMainSingle);
        fwrKey(userKeyMenuMainNetwork,   keyMenuMainNetwork);
        fwrKey(userKeyMenuMainReplays,   keyMenuMainReplays);
        fwrKey(userKeyMenuMainOptions,   keyMenuMainOptions);
        f.writeln();

        fwrKey(userKeyEditorLeft,        keyEditorLeft);
        fwrKey(userKeyEditorRight,       keyEditorRight);
        fwrKey(userKeyEditorUp,          keyEditorUp);
        fwrKey(userKeyEditorDown,        keyEditorDown);
        fwrKey(userKeyEditorCopy,        keyEditorCopy);
        fwrKey(userKeyEditorDelete,      keyEditorDelete);
        fwrKey(userKeyEditorGrid,        keyEditorGrid);
        fwrKey(userKeyEditorSelectAll,   keyEditorSelectAll);
        fwrKey(userKeyEditorSelectFrame, keyEditorSelectFrame);
        fwrKey(userKeyEditorSelectAdd,   keyEditorSelectAdd);
        fwrKey(userKeyEditorBackground,  keyEditorBackground);
        fwrKey(userKeyEditorForeground,  keyEditorForeground);
        fwrKey(userKeyEditorMirror,      keyEditorMirror);
        fwrKey(userKeyEditorRotate,      keyEditorRotate);
        fwrKey(userKeyEditorDark,        keyEditorDark);
        fwrKey(userKeyEditorAddTerrain,  keyEditorAddTerrain);
        fwrKey(userKeyEditorAddSteel,    keyEditorAddSteel);
        fwrKey(userKeyEditorAddHatch,    keyEditorAddHatch);
        fwrKey(userKeyEditorAddGoal,     keyEditorAddGoal);
        fwrKey(userKeyEditorAddDeco,     keyEditorAddDeco);
        fwrKey(userKeyEditorAddHazard,   keyEditorAddHazard);
        fwrKey(userKeyEditorMenuConstants, keyEditorMenuConstants);
        fwrKey(userKeyEditorMenuTopology,  keyEditorMenuTopology);
        fwrKey(userKeyEditorMenuLooks,     keyEditorMenuLooks);
        fwrKey(userKeyEditorMenuSkills,    keyEditorMenuSkills);
        fwrKey(userKeyEditorExit,          keyEditorExit);

        f.writeln();
        foreach (key, r; results)
            fwr(IoLine.Angle(key.rootless,
                r.lixSaved, r.skillsUsed, r.updatesUsed, r.built.toString));
    }
    catch (Exception e) {
        log("Can't save user configuration for `" ~ userName ~ "':");
        log("    -> " ~ e.msg);
    }
}
