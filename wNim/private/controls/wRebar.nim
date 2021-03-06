#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## A rebar control can contain one or more bands, and each band can have a
## gripper bar, a bitmap, a text label, and one child control.
## As you dynamically reposition a rebar control band, the rebar control manages
## the size and position of the child window assigned to that band.
#
## :Superclass:
##   `wControl <wControl.html>`_

const
  wRbBandBorder* = RBS_BANDBORDERS
  wRbDoubleClickToggle* = RBS_DBLCLKTOGGLE

proc setImageList*(self: wRebar, imageList: wImageList) {.validate, property.} =
  ## Sets the image list associated with the rebar.
  if imageList != nil:
    var rebarInfo = REBARINFO(cbSize: sizeof(REBARINFO), fMask: RBIM_IMAGELIST,
      himl: imageList.mHandle)
    SendMessage(mHwnd, RB_SETBARINFO, 0, &rebarInfo)

  mImageList = imageList

proc getImageList*(self: wRebar): wImageList {.validate, property, inline.} =
  ## Returns the specified image list.
  result = mImageList

proc getCount*(self: wRebar): int {.validate, property, inline.} =
  ## Returns the number of controls in the rebar.
  result = int SendMessage(mHwnd, RB_GETBANDCOUNT, 0, 0)

proc addControl*(self: wRebar, control: wControl, image = -1, label = "") {.validate.} =
  ## Adds a control to the rebar.
  wValidate(control)

  var rbBand = REBARBANDINFO(cbSize: sizeof(REBARBANDINFO))
  rbBand.fMask = RBBIM_STYLE or RBBIM_CHILD or RBBIM_CHILDSIZE or
    RBBIM_SIZE or RBBIM_IMAGE
  rbBand.fStyle = RBBS_CHILDEDGE or RBBS_GRIPPERALWAYS
  rbBand.hwndChild = control.mHwnd
  rbBand.iImage = image

  if control of wToolBar:
    var toolbar = wToolBar(control)
    var toolSize = toolbar.getToolSize()
    rbBand.cxMinChild = toolbar.getToolsCount() * toolSize.width
    rbBand.cyMinChild = toolSize.height

  else:
    let size = control.getBestSize()
    rbBand.cxMinChild = size.width
    rbBand.cyMinChild = size.height

  rbBand.cx = rbBand.cxMinChild
  rbBand.cyChild = rbBand.cyMinChild

  if label.len != 0:
    rbBand.fMask = rbBand.fMask or RBBIM_TEXT
    rbBand.lpText = T(label)

  SendMessage(mHwnd, RB_INSERTBAND, -1, &rbBand)

proc len*(self: wRebar): int {.validate, inline.} =
  ## Returns the number of controls in the rebar.
  result = getCount()

method processNotify(self: wRebar, code: INT, id: UINT_PTR, lParam: LPARAM,
    ret: var LRESULT): bool =

  case code
  of RBN_BEGINDRAG:
    mDragging = true

  of RBN_ENDDRAG:
    mDragging = false

  # of RBN_LAYOUTCHANGED:
  #   # Notice the parent the client size is changed. Here must be wEvent_Size
  #   # instead of WM_SIZE, otherwise, it will enter infinite loop.
  #   let rect = mParent.getWindowRect(sizeOnly=true)
  #   mParent.processMessage(wEvent_Size, SIZE_RESTORED,
  #     MAKELPARAM(rect.width, rect.height))

  of RBN_AUTOSIZE:
    if mDragging:
      # Notice the parent the client size is changed. Here must be wEvent_Size
      # instead of WM_SIZE, otherwise, it will enter infinite loop.
      let rect = mParent.getWindowRect(sizeOnly=true)
      mParent.processMessage(wEvent_Size, SIZE_RESTORED,
        MAKELPARAM(rect.width, rect.height))

  else:
    return procCall wControl(self).processNotify(code, id, lParam, ret)


method release(self: wRebar) =
  mImageList = nil
  mParent.systemDisconnect(mSizeConn)

proc final*(self: wRebar) =
  ## Default finalizer for wRebar.
  discard

proc init*(self: wRebar, parent: wWindow, id = wDefaultID,
    imageList: wImageList = nil, style: wStyle = 0) {.validate.} =
  ## Initializer.
  wValidate(parent)
  mControls = @[]

  self.wControl.init(className=REBARCLASSNAME, parent=parent, id=id,
    style=style or WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or
    RBS_VARHEIGHT or CCS_NODIVIDER or RBS_AUTOSIZE)

  parent.mRebar = self

  mSizeConn = parent.systemConnect(WM_SIZE) do (event: wEvent):
    self.setSize(parent.size.width, wDefault)

proc Rebar*(parent: wWindow, id = wDefaultID, imageList: wImageList = nil,
    style: wStyle = 0): wRebar {.inline, discardable.} =
  ## Constructs a rebar.
  wValidate(parent)
  new(result, final)
  result.init(parent, id, imageList, style)
