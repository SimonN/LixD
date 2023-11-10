module hardware.keyenum;

import basics.alleg5;

// Assignable as hotkeys
enum keyMMB       = ALLEGRO_KEY_MAX;
enum keyRMB       = ALLEGRO_KEY_MAX + 1;
enum keyWheelUp   = ALLEGRO_KEY_MAX + 2;
enum keyWheelDown = ALLEGRO_KEY_MAX + 3;

// Constant for hardware.keyboard. Keep this as max(above names) + 1.
enum hardwareKeyboardArrLen = ALLEGRO_KEY_MAX + 4;
