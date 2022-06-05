module menu.lobby.topleft;

/*
 * The top-left area of the lobby after a successful connection:
 *
 * +-----------------+ +--+
 * | All players     | |  | Your color
 * |                 | |  |
 * |                 | |  |
 * +-----------------+ +--+
 * +------------+ +-------+
 * |   Ready    | | Handi |
 * +------------+ +-------+
 */

import optional;

import file.language;
import file.option.allopts;
import graphic.internal;
import gui;
import menu.lobby.colpick;
import menu.lobby.handicap;
import menu.lobby.lists;
import net.profile;

class TopLeftUI : Element {
private:
    PeerList _peerList;
    ColorSelector _colPick;
    TextButton _declareReady;
    BitmapButton _handiButton;
    Optional!HandicapPicker _handiPicker; // only exists when window is open

    /*
     * The profile that the user chose for himself using the color picker,
     * the handicap button, and the ready button. Doesn't depend on the
     * player list. The player list merely reflects what the server told us.
     * But _chosenProfile is what we want to tell the server.
     *
     * After ctor, this profile is still Profile.init,
     * but we expect the caller to this.choose() something quickly enough.
     */
    Profile _chosenProfile;
    bool _externalReasonsAllowUsToDeclareReady;
    bool _execute;

public:
    this(Geom g)
    {
        super(g);
        _peerList = new PeerList(
            new Geom(0, 0, xlg - 60f, ylg - 40f, From.TOP_LEFT));
        addChild(_peerList);
        _colPick = new ColorSelector(
            new Geom(0, 0, 40, (ylg - 40f) * 5f/6f, From.TOP_RIGHT));
        addChild(_colPick);

        immutable float butXl = xlg / 2f - 10f;
        assert (butXl > 80, "This will be pretty narrow.");
        _declareReady = new TextButton(
            new Geom(0, 0, butXl, 20, From.BOTTOM_LEFT),
            Lang.winLobbyReady.transl);
        _declareReady.hotkey = keyMenuOkay;
        _handiButton = new BitmapButton(new Geom(0, _colPick.ylg,
            _colPick.xlg, _peerList.ylg - _colPick.ylg, From.TOP_RIGHT),
            InternalImage.lobbySpec.toCutbit);
        _handiButton.xf = 1;
        addChildren(_declareReady, _handiButton);
    }

    bool execute() const pure nothrow @safe @nogc
    {
        return _execute;
    }

    Profile chosenProfile() const pure nothrow @safe @nogc
    {
        return _chosenProfile;
    }

    void showInList(in Profile[] players)
    {
        _peerList.recreateButtonsFor(players);
    }

    void choose(in Profile wanted)
    {
        _chosenProfile = wanted;
        matchChosenProfile();
    }

    void allowToDeclareReady(in bool b)
    {
        _externalReasonsAllowUsToDeclareReady = b;
        matchChosenProfile();
    }

    // Call this from outside when outsiders have more information than we.
    void destroyHandicapWindow()
    {
        foreach (window; _handiPicker) {
            gui.rmFocus(window);
        }
        _handiPicker = none;
    }

protected:
    override void calcSelf()
    {
        _execute = false;
        if (_colPick.execute) {
            unreadyTheChosenProfile();
            _chosenProfile.style = _colPick.chosenStyle;
            matchChosenProfile();
            _execute = true;
        }
        if (_declareReady.execute) {
            _chosenProfile.feeling = _declareReady.on
                ? Profile.Feeling.thinking : Profile.Feeling.ready;
            matchChosenProfile();
            _execute = true;
        }
        if (_handiButton.execute && _handiPicker.empty) {
            auto window = new HandicapPicker(_chosenProfile.handicap);
            gui.addFocus(window);
            _handiPicker = window;
        }
    }

    override void workSelf()
    {
        /*
         * calc() will happen before work() in the same frame, see gui.root.
         * Thus, no need to reset _execute to false at start of workSelf().
         */
        foreach (window; _handiPicker) {
            if (window.exitWith == OkayCancel.ExitWith.nothingYet) {
                continue;
            }
            if (window.exitWith == OkayCancel.ExitWith.okay
                && _chosenProfile.handicap != window.chosenHandicap
            ) {
                unreadyTheChosenProfile();
                _chosenProfile.handicap = window.chosenHandicap;
                matchChosenProfile();
                _execute = true;
            }
            destroyHandicapWindow();
        }
    }

    override void undrawSelf()
    {
        /*
         * undraw() does not recurse through children. Reason: You're supposed
         * to undraw all children by undrawing yourself, thereby covering all
         * space that children would have covered. That's wrong in our case:
         *
         * +--------+ PeerList's frame reaches outside our Geom,
         * |+-------+------+ thus, we have to undraw both the
         * ||       |      | PeerList and ourselves separately.
         * ++-------+      |
         *  |         this |
         *  +--------------+
         */
        _peerList.undraw();
        super.undrawSelf();
    }

private:
    void matchChosenProfile()
    {
        _colPick.choose(_chosenProfile);
        _declareReady.on = _chosenProfile.feeling == Profile.Feeling.ready;
        _declareReady.shown = ! _colPick.isObserving
            && _externalReasonsAllowUsToDeclareReady;
        _handiButton.shown = ! _colPick.isObserving;
    }

    void unreadyTheChosenProfile()
    {
        _chosenProfile.feeling = _colPick.isObserving
            ? Profile.Feeling.observing : Profile.Feeling.thinking;
    }
}
