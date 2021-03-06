#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                (c) Copyright 2017-2018 Ward
#
#====================================================================

when defined(cpu64):
  {.link: "wNim64.res".}
else:
  {.link: "wNim32.res".}

import wNim

proc passwordDialog(owner: wWindow): string =
  var password = ""
  let dialog = Frame(owner=owner, size=(320, 200), style = wCaption or wSystemMenu)
  let panel = Panel(dialog)
  let statictext = StaticText(panel, label="Please enter the password:", pos=(10, 10))
  let textctrl = TextCtrl(panel, pos=(20, 50), size=(270, 30),
    style=wBorderSunken or wTePassword)
  let buttonOk = Button(panel, label="&OK", size=(90, 30), pos=(100, 120))
  let buttonCancel = Button(panel, label="&Cancel", size=(90, 30), pos=(200, 120))

  const ok = staticRead(r"images\ok.ico")
  const cancel = staticRead(r"images\cancel.ico")

  buttonOk.setDefault()
  buttonOk.setBitmap(Bmp(ok))
  buttonCancel.setBitmap(Bmp(cancel))
  dialog.icon = Icon(ok)

  dialog.wEvent_Close do ():
    dialog.endModal()

  buttonOk.wEvent_Button do ():
    password = textctrl.value
    dialog.close()

  buttonCancel.wEvent_Button do ():
    dialog.close()

  dialog.shortcut(wAccelNormal, wKey_Esc) do ():
    buttonCancel.click()

  dialog.center()
  dialog.showModal()
  dialog.delete()

  result = password

when isMainModule:
  type
    MenuID = enum
      idOpen = wIdUser
      idExit
      idButton

  let app = App()
  let frame = Frame(title="wNim PasswordDialog", size=(480, 320))
  frame.icon = Icon("", 0) # load icon from exe file.

  let statusbar = StatusBar(frame)
  let button = Button(frame, label="Open Dialog")
  let menubar = MenuBar(frame)
  let menu = Menu(menubar, "&File")
  menu.append(idOpen, "&Open", "Open the dialog.")
  menu.appendSeparator()
  menu.append(idExit, "E&xit", "Exit the program.")

  button.wEvent_Button do ():
    let password = passwordDialog(frame)
    if password.len != 0:
      MessageDialog(frame, password, "Password", wOk or wIconInformation).show()

  frame.idOpen do ():
    button.click()

  frame.idExit do ():
    frame.close()

  frame.center()
  frame.show()
  app.mainLoop()
