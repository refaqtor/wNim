#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## A combobox is like a combination of an edit control and a listbox.
##
## Notice: a combobox may recieve events propagated from its child text
## control. (wEvent_Text, wEvent_TextUpdate, wEvent_TextMaxlen etc.)
## In these case, event.window should be the child text control, not combobox
## itself.
#
## :Appearance:
##   .. image:: images/wComboBox.png
#
## :Superclass:
##   `wControl <wControl.html>`_
#
## :Styles:
##   ==============================  =============================================================
##   Styles                          Description
##   ==============================  =============================================================
##   wCbSimple                       Creates a combobox with a permanently displayed list.
##   wCbDropDown                     Creates a combobox with a drop-down list.
##   wCbReadOnly                     Allows the user to choose from the list but doesn't allow to enter a value.
##   wCbSort                         Sorts the entries in the list alphabetically.
##   wCbNeededScroll                 Only create a vertical scrollbar if needed.
##   wCbAlwaysScroll                 Always show a vertical scrollbar.
##   wCbAutoHScroll                  Automatically scrolls the text in an edit control to the right when the user types a character at the end of the line.
##   ==============================  =============================================================
#
## :Events:
##   `wCommandEvent <wCommandEvent.html>`_
##   ==============================   =============================================================
##   wCommandEvent                    Description
##   ==============================   =============================================================
##   wEvent_ComboBox                  When an item on the list is selected, calling getValue() returns the new value of selection.
##   wEvent_ComboBoxCloseUp           When the list box of the combo box disappears.
##   wEvent_ComboBoxDropDown          When the list box part of the combo box is shown.
##   wEvent_Text                      When the text changes.
##   wEvent_TextUpdate                When the control is about to redraw itself.
##   wEvent_TextMaxlen                When the user tries to enter more text into the control than the limit.
##   wEvent_TextEnter                 When pressing Enter key.
##   wEvent_CommandSetFocus           When the control receives the keyboard focus.
##   wEvent_CommandKillFocus          When the control loses the keyboard focus.
##   wEvent_CommandLeftDoubleClick    Double-clicked the left mouse button within the control.
##   ===============================  =============================================================

const
  # ComboBox styles
  wCbSimple* = CBS_SIMPLE # 01
  wCbDropDown* = CBS_DROPDOWN # 02
  wCbReadOnly* = CBS_DROPDOWNLIST # 03
  wCbStyleMask = 0b11
  wCbSort* = CBS_SORT
  # A combobox never have a horizontal scroll bar.(Testing under win10)
  # Others see wListBox.nim
  wCbNeededScroll* = WS_VSCROLL
  wCbAlwaysScroll* = WS_VSCROLL or CBS_DISABLENOSCROLL
  wCbAutoHScroll* = CBS_AUTOHSCROLL

proc len*(self: wComboBox): int {.validate, inline.} =
  ## Returns the number of items in the control.
  result = int SendMessage(mHwnd, CB_GETCOUNT, 0, 0)

proc getCount*(self: wComboBox): int {.validate, property, inline.} =
  ## Returns the number of items in the control.
  result = len()

proc getText*(self: wComboBox, index: int): string =
  ## Returns the text of the item with the given index.
  # use getText instead of getString, otherwise property become "string" keyword.
  let maxLen = int SendMessage(mHwnd, CB_GETLBTEXTLEN, index, 0)
  if maxLen == CB_ERR: return ""

  var buffer = T(maxLen + 2)
  buffer.setLen(SendMessage(mHwnd, CB_GETLBTEXT, index, &buffer))
  result = $buffer

proc `[]`*(self: wComboBox, index: int): string {.validate, inline.} =
  ## Returns the text of the item with the given index.
  ## Raise error if index out of bounds.
  result = getText(index)
  if result.len == 0:
    raise newException(IndexError, "index out of bounds")

iterator items*(self: wComboBox): string {.validate, inline.} =
  ## Iterate each item in this combo box.
  for i in 0..<len():
    yield getText(i)

iterator pairs*(self: wComboBox): (int, string) {.validate, inline.} =
  ## Iterates over each item in this combo box. Yields ``(index, [index])`` pairs.
  var i = 0
  for item in self:
    yield (i, item)
    inc i

proc insert*(self: wComboBox, pos: int, text: string) {.validate, inline.} =
  ## Inserts the given string before the specified position.
  ## Notice that the inserted item won't be sorted even the list box has wCbSort style.
  ## If pos is -1, the string is added to the end of the list.
  SendMessage(mHwnd, CB_INSERTSTRING, pos, &T(text))

proc insert*(self: wComboBox, pos: int, list: openarray[string]) {.validate, inline.} =
  ## Inserts multiple strings in the same time.
  for i, text in list:
    insert(if pos < 0: pos else: i + pos, text)

proc append*(self: wComboBox, text: string) {.validate, inline.} =
  ## Appends the given string to the end. If the combo box has the wCbSort style,
  ## the string is inserted into the list and the list is sorted.
  SendMessage(mHwnd, CB_ADDSTRING, 0, &T(text))

proc append*(self: wComboBox, list: openarray[string]) {.validate, inline.} =
  ## ## Appends multiple strings in the same time.
  for text in list:
    append(text)

proc delete*(self: wComboBox, index: int) {.validate, inline.} =
  ## Delete a string in the combo box.
  if index >= 0: SendMessage(mHwnd, CB_DELETESTRING, index, 0)

proc delete*(self: wComboBox, text: string)  {.validate, inline.} =
  ## Search and delete the specified string in the combo box.
  delete(find(text))

proc clear*(self: wComboBox)  {.validate, inline.} =
  ## Remove all items from a combo box.
  SendMessage(mHwnd, CB_RESETCONTENT, 0, 0)

proc findText*(self: wComboBox, text: string): int {.validate, inline.} =
  ## Finds an item whose label matches the given text.
  result = find(text)

proc getSelection*(self: wComboBox): int {.validate, property, inline.} =
  ## Returns the index of the selected item or wNOT_FOUND(-1) if no item is selected.
  result = int SendMessage(mHwnd, CB_GETCURSEL, 0, 0)

proc select*(self: wComboBox, index: int) {.validate, inline.} =
  ## Sets the selection to the given index or removes the selection entirely if index == wNOT_FOUND(-1).
  SendMessage(mHwnd, CB_SETCURSEL, index, 0)

proc setSelection*(self: wComboBox, index: int) {.validate, property, inline.} =
  ## The same as select().
  select(index)

proc setText*(self: wComboBox, index: int, text: string) {.validate, property.} =
  ## Changes the text of the specified combobox item.
  # use setText instead of setString, otherwise property become "string" keyword.
  if index >= 0:
    let reselect = (getSelection() == index)
    delete(index)
    insert(index, text)
    if reselect:
      select(index)

proc changeValue*(self: wComboBox, text: string) {.validate, property.} =
  ## Sets the text for the combobox text field.
  ## Notice that this proc won't generate wEvent_Text event.
  let kind = GetWindowLongPtr(mHwnd, GWL_STYLE) and wCbStyleMask
  if kind == wCbReadOnly:
    select(find(text)) # if result is -1, selection is removed
  else:
    setLabel(text)

proc setValue*(self: wComboBox, text: string) {.validate, property, inline.} =
  ## Sets the text for the combobox text field.
  ## Notice that this proc will generate wEvent_Text event.
  changeValue(text)
  self.processMessage(wEvent_Text, 0, 0)

proc getValue*(self: wComboBox): string {.validate, property, inline.} =
  ## Gets the text for the combobox text field.
  result = getLabel()

proc isListEmpty*(self: wComboBox): bool {.validate,  inline.} =
  ## Returns true if the list of combobox choices is empty.
  result = (len() == 0)

proc isTextEmpty*(self: wComboBox): bool {.validate,  inline.} =
  ## Returns true if the text of the combobox is empty.
  result = GetWindowTextLength(mHwnd) == 0

proc popup*(self: wComboBox) {.validate,  inline.} =
  ## Shows the list box portion of the combo box.
  SendMessage(mHwnd, CB_SHOWDROPDOWN, TRUE, 0)

proc dismiss*(self: wComboBox) {.validate,  inline.} =
  ## Hides the list box portion of the combo box.
  SendMessage(mHwnd, CB_SHOWDROPDOWN, FALSE, 0)

proc getEditControl*(self: wComboBox): wTextCtrl {.validate, property, inline.} =
  ## Returns the text control part of this combobox, or nil if no such control.
  result = mEdit

proc getTextCtrl*(self: wComboBox): wTextCtrl {.validate, property, inline.} =
  ## Returns the text control part of this combobox, or nil if no such control.
  ## The same as getEditControl().
  result = getEditControl()

proc getListControl*(self: wComboBox): wWindow {.validate, property, inline.} =
  ## Returns the list control part of this combobox, or nil if no such control.
  ## Notice that the result is wWindow for event handler only, not a wListBox.
  result = mList

proc countSize(self: wComboBox, minItem: int, rate: float): wSize =
  const maxItem = 10
  let
    lineHeight = getLineControlDefaultHeight(mFont.mHandle)
    kind = GetWindowLongPtr(mHwnd, GWL_STYLE) and wCbStyleMask
    count = len()

  var cbi = COMBOBOXINFO(cbSize: sizeof(COMBOBOXINFO))
  GetComboBoxInfo(mHwnd, cbi)

  proc countWidth(rate: float): int =
    result = lineHeight # minimum width
    for text in self.items():
      let size = getTextFontSize(text, mFont.mHandle)
      result = max(result, int(size.width.float * rate) + 8)

  if kind == wCbSimple:
    let itemHeight = int SendMessage(mHwnd, CB_GETITEMHEIGHT, 0, 0)
    result.width = countWidth(rate)
    result.height = lineHeight + min(max(count, minItem), maxItem) * itemHeight + 4 # not too tall, not too small

    let style = GetWindowLongPtr(cbi.hwndList, GWL_STYLE)
    if (style and WS_VSCROLL) != 0 and ((style and LBS_DISABLENOSCROLL) != 0 or count > maxItem):
      result.width += GetSystemMetrics(SM_CXVSCROLL)

  else:
    result.width = countWidth(rate) + (cbi.rcButton.right - cbi.rcButton.left) + 2
    result.height = getWindowRect(sizeOnly=true).height

method getDefaultSize*(self: wComboBox): wSize =
  ## Returns the default size for the control.
  # width of longest item + 30% x an integral number of items (3 items minimum)
  result = countSize(3, 1.3)

method getBestSize*(self: wComboBox): wSize =
  ## Returns the best acceptable minimal size for the control.
  result = countSize(1, 1.0)

method trigger(self: wComboBox) =
  for i in 0..<mInitCount:
    let text = mInitData[i]
    SendMessage(mHwnd, CB_ADDSTRING, 0, &T(text))

method release(self: wComboBox) =
  mParent.systemDisconnect(mCommandConn)

proc final*(self: wComboBox) =
  ## Default finalizer for wComboBox.
  discard

proc init*(self: wComboBox, parent: wWindow, id = wDefaultID,
    value: string = "", pos = wDefaultPoint, size = wDefaultSize,
    choices: openarray[string] = [], style: wStyle = wCbDropDown) {.validate.} =
  ## Initializer.
  wValidate(parent)
  mInitData = cast[ptr UncheckedArray[string]](choices)
  mInitCount = choices.len

  # wCbDropDown as default style
  var style = style
  if (style and wCbStyleMask) == 0:
    style = style or wCbDropDown

  # only wCbSimple can use CBS_NOINTEGRALHEIGHT, otherwise drop down menu will disappear
  if (style and wCbStyleMask) == wCbSimple:
    style = style or CBS_NOINTEGRALHEIGHT

  self.wControl.init(className=WC_COMBOBOX, parent=parent, id=id, pos=pos, size=size,
    style=style or WS_TABSTOP or WS_VISIBLE or WS_CHILD)

  # subclass child windows (edit and listbox) to handle the message in wNim's way
  # todo: the returned subclassed object is wWindow. let it become wTextCtrl and wListBox?
  # for wCbReadOnly, mHwnd == cbi.hwndItem, there is no child edit control
  var cbi = COMBOBOXINFO(cbSize: sizeof(COMBOBOXINFO))
  GetComboBoxInfo(mHwnd, cbi)

  if cbi.hwndItem != mHwnd:
    mEdit = TextCtrl(cbi.hwndItem)
    # we need send the navigation events to this wComboBox
    # so that navigation key can works under subclassed window
    mEdit.hardConnect(WM_CHAR) do (event: wEvent):
      if event.keyCode == VK_RETURN:
        # try to send wEvent_TextEnter first.
        # If someone handle this, block the default behavior.
        # for wCbSimple, the default enter behavior is set cursor to beginning
        if self.processMessage(wEvent_TextEnter, 0, 0):
          return

      if not self.processMessage(WM_CHAR, event.mWparam, event.mLparam, event.mResult):
        event.skip

    mEdit.hardConnect(WM_KEYDOWN) do (event: wEvent):
      if not self.processMessage(WM_KEYDOWN, event.mWparam, event.mLparam, event.mResult):
        event.skip

    mEdit.hardConnect(WM_SYSCHAR) do (event: wEvent):
      if not self.processMessage(WM_SYSCHAR, event.mWparam, event.mLparam, event.mResult):
        event.skip

  if cbi.hwndList != mHwnd:
    mList = Window(cbi.hwndList)
    # don't need hook navigation events because list window by defult won't get focus

  setValue(value)

  mCommandConn = parent.systemConnect(WM_COMMAND) do (event: wEvent):
    if event.mLparam == mHwnd:
      let cmdEvent = case HIWORD(event.mWparam)
        of CBN_SELENDOK:
          # the system set the edit control value AFTER this event
          # however, we need let getValue() return a correct value.
          let n = self.getSelection()
          if n >= 0:
            self.setLabel(self.getText(n))
          wEvent_ComboBox

        of CBN_CLOSEUP: wEvent_ComboBoxCloseUp
        of CBN_DROPDOWN: wEvent_ComboBoxDropDown
        of CBN_SETFOCUS: wEvent_CommandSetFocus
        of CBN_KILLFOCUS: wEvent_CommandKillFocus
        of CBN_DBLCLK: wEvent_CommandLeftDoubleClick
        else: 0

      if cmdEvent != 0:
        self.processMessage(cmdEvent, event.mWparam, event.mLparam)

  hardConnect(wEvent_Navigation) do (event: wEvent):
    if event.keyCode in {wKey_Up, wKey_Down, wKey_Left, wKey_Right}:
      event.veto

proc ComboBox*(parent: wWindow, id = wDefaultID, value: string = "",
    pos = wDefaultPoint, size = wDefaultSize, choices: openarray[string] = [],
    style: wStyle = wCbDropDown): wComboBox {.inline, discardable.} =
  ## Constructor, creating and showing a combobox.
  wValidate(parent)
  new(result, final)
  result.init(parent, id, value, pos, size, choices, style)
