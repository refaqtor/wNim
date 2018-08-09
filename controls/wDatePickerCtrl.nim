## This control allows the user to select a date.
##
## :Superclass:
##    wControl
## :Appearance:
##    .. image:: images/wDatePickerCtrl.png
## :Styles:
##    ==============================  =============================================================
##    Styles                          Description
##    ==============================  =============================================================
##    wDpSpin                         Show spin-control-like arrows to change individual date components.
##    wDpDropDown                     Show drop-down part from which the user can select a date.
##    wDpDefault                      Best supported for the current platform (currently wDpSpin under Windows).
##    wDpAllowNone                    The control allows the user to not enter any valid date at all.
##    wDpShowCentury                  Forces display of the century in the default date format.
##    ==============================  =============================================================
##
## :Events:
##    ==============================  =============================================================
##    Events                          Description
##    ==============================  =============================================================
##    wEvent_DateChanged              The selected date changed.
##    ==============================  =============================================================

const
  wDpSpin*: wStyle = DTS_UPDOWN
  wDpDropDown*: wStyle = 0
  wDpDefault*: wStyle = wDpSpin
  wDpAllowNone*: wStyle = DTS_SHOWNONE
  wDpShowCentury*: wStyle = DTS_SHORTDATECENTURYFORMAT

method getBestSize*(self: wDatePickerCtrl): wSize {.property.} =
  ## Returns the best acceptable minimal size for the window.
  var size: SIZE
  SendMessage(mHwnd, DTM_GETIDEALSIZE, 0, addr size)
  result.width = size.cx + 2
  result.height = size.cy + 2

method getDefaultSize*(self: wDatePickerCtrl): wSize {.property.} =
  ## Returns the default size for the window.
  result = getBestSize()
  result.height = getLineControlDefaultHeight(mFont.mHandle)

proc getValue*(self: wDatePickerCtrl): wTime {.validate, property.} =
  ## Returns the currently entered date.
  var st: SYSTEMTIME
  if GDT_VALID == SendMessage(mHwnd, DTM_GETSYSTEMTIME, 0, addr st):
    result = st.toTime()

proc setValue*(self: wDatePickerCtrl, time: wTime) {.validate, property.} =
  ## Changes the current value of the control.
  var st = time.toSystemTime()
  SendMessage(mHwnd, DTM_SETSYSTEMTIME, GDT_VALID, addr st)

proc getRange*(self: wDatePickerCtrl): (wTime, wTime) {.validate, property.} =
  ## If the control had been previously limited to a range of dates,
  ## returns the lower and upper bounds of this range.
  var st: array[2, SYSTEMTIME]
  let flag = SendMessage(mHwnd, DTM_GETRANGE , 0, addr st)
  result[0] = if (flag and GDTR_MIN) != 0: st[0].toTime() else: wDefaultTime
  result[1] = if (flag and GDTR_MAX) != 0: st[1].toTime() else: wDefaultTime

proc setRange*(self: wDatePickerCtrl, time1 = wDefaultTime, time2 = wDefaultTime) {.validate, property.} =
  ## Sets the valid range for the date selection.
  var st: array[2, SYSTEMTIME]
  var flag: DWORD
  if time1 != wDefaultTime:
    st[0] = time1.toSystemTime()
    flag = flag or GDTR_MIN

  if time2 != wDefaultTime:
    st[1] = time2.toSystemTime()
    flag = flag or GDTR_MAX

  SendMessage(mHwnd, DTM_SETRANGE, flag, addr st)

proc setRange*(self: wDatePickerCtrl, time: (wTime, wTime)) {.validate, property.} =
  ## Sets the valid range for the date selection.
  setRange(time[0], time[1])

proc wDatePickerCtrlNotifyHandler(self: wDatePickerCtrl, code: INT, id: UINT_PTR, lparam: LPARAM, processed: var bool): LRESULT =
  var eventType: UINT
  case code
  of DTN_DATETIMECHANGE: eventType = wEvent_DateChanged
  else: return self.wControlNotifyHandler(code, id, lparam, processed)

  result = self.mMessageHandler(self, eventType, cast[WPARAM](id), lparam, processed)

proc init(self: wDatePickerCtrl, parent: wWindow, id: wCommandID = wDefaultID,
    date: wTime = wDefaultTime, pos: wPoint = wDefaultPoint, size: wSize = wDefaultSize, style: wStyle = wDpDefault) =
  assert parent != nil

  self.wControl.init(className=DATETIMEPICK_CLASS, parent=parent, id=id, label="", pos=pos, size=size, style=style or WS_CHILD or WS_VISIBLE or WS_TABSTOP)

  if date != wDefaultTime:
    setValue(date)

  wDatePickerCtrl.setNotifyHandler(wDatePickerCtrlNotifyHandler)
  mKeyUsed = {wUSE_RIGHT, wUSE_LEFT, wUSE_UP, wUSE_DOWN}

proc DatePickerCtrl*(parent: wWindow, id: wCommandID = wDefaultID, date: wTime = wDefaultTime,
    pos: wPoint = wDefaultPoint, size: wSize = wDefaultSize, style: wStyle = wDpDefault): wDatePickerCtrl {.discardable.} =
  ## Creates the control.
  ## ==========  =================================================================================
  ## Parameters  Description
  ## ==========  =================================================================================
  ##    parent   Parent window.
  ##    id       The identifier for the control.
  ##    date     The initial value of the control, if an invalid date (such as the default value) is used, the control is set to today.
  ##    pos      Initial position.
  ##    size     Initial size. If left at default value, the control chooses its own best size.
  ##    style    The window style.
  wValidate(parent)
  new(result)
  result.init(parent=parent, id=id, date=date, pos=pos, size=size, style=style)