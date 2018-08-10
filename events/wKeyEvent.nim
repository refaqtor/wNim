## This event object contains information about the events generated by the keyboard.
## wNim passes wKeyEvent to event handler for keyboard events, instead of wEvent.
## :Superclass:
##    wEvent
## :Events:
##    ==============================  =============================================================
##    Events                          Description
##    ==============================  =============================================================
##    wEvent_Char                     A focused Window receives a char.
##    wEvent_KeyDown                  A key was pressed.
##    wEvent_KeyUp                    A key was released.
##    wEvent_SysKeyDown               Presses the F10 key or holds down the ALT key and then presses another key.
##    wEvent_SysKeyUp                 Releases a key that was pressed while the ALT key was held down.
##    ==============================  =============================================================

const
  wEvent_Char* = WM_CHAR
  wEvent_KeyDown* = WM_KEYDOWN
  wEvent_KeyUp* = WM_KEYUP
  wEvent_SysKeyDown* = WM_SYSKEYDOWN
  wEvent_SysKeyUp* = WM_SYSKEYUP
  wEvent_KeyFirst = WM_KEYFIRST
  wEvent_KeyLast = WM_KEYLAST

proc isKeyEvent(msg: UINT): bool {.inline.} =
  msg in wEvent_KeyFirst..wEvent_KeyLast

method getKeyCode*(self: wKeyEvent): int {.property.} = result = int mWparam
  ## Returns the key code of the key that generated this event.
