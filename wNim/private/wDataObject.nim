#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## A wDataObject represents data that can be copied to or from the clipboard,
## or dragged and dropped. For now, only text, files list, and bitmap are
## supported.
#
## :Seealso:
##   `wWindow <wWindow.html>`_
##   `wDragDropEvent <wDragDropEvent.html>`_
#
## :Effects:
##   ==============================  =============================================================
##   Drag-Drop Effects               Description
##   ==============================  =============================================================
##   wDragNone                       Drop target cannot accept the data.
##   wDragCopy                       Drop results in a copy.
##   wDragMove                       Drag source should remove the data.
##   wDragLink                       Drag source should create a link to the original data.
##   ==============================  =============================================================

const
  wDragNone* = DROPEFFECT_NONE # 0
  wDragCopy* = DROPEFFECT_COPY # 1
  wDragMove* = DROPEFFECT_MOVE # 2
  wDragLink* = DROPEFFECT_LINK # 4
  wDragError* = 8
  wDragCancel* = 16

type
  wDataObjectError* = object of wError
    ## An error raised when wDataObject creation or operation failure.

proc error(self: wDataObject) {.inline.} =
  raise newException(wDataObjectError, "wDataObject creation failure")

proc isText*(self: wDataObject): bool {.validate.} =
  ## Checks the data is text or not.
  var format = FORMATETC(
    cfFormat: CF_UNICODETEXT,
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_HGLOBAL)

  if mObj.QueryGetData(&format) == S_OK:
    return true

  format.cfFormat = CF_TEXT
  if mObj.QueryGetData(&format) == S_OK:
    return true

proc getText*(self: wDataObject): string {.validate.} =
  ## Gets the data in text format.
  var ret: string
  defer: result = ret

  var format = FORMATETC(
    cfFormat: CF_UNICODETEXT,
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_HGLOBAL)

  var isUnicode = true
  var medium: STGMEDIUM
  if mObj.GetData(&format, &medium) != S_OK:
    format.cfFormat = CF_TEXT
    isUnicode = false
    if mObj.GetData(&format, &medium) != S_OK:
      return

  if medium.tymed == TYMED_HGLOBAL:
    if isUnicode:
      let pData = cast[ptr WCHAR](GlobalLock(medium.u.hGlobal))
      ret = $pData
    else:
      let pData = cast[ptr char](GlobalLock(medium.u.hGlobal))
      ret = $pData
    GlobalUnlock(medium.u.hGlobal)

  ReleaseStgMedium(&medium)

proc isFiles*(self: wDataObject): bool {.validate.} =
  ## Checks the data is files list or not.
  var format = FORMATETC(
    cfFormat: CF_HDROP,
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_HGLOBAL)

  if mObj.QueryGetData(&format) == S_OK:
    # only return true if there are some files.
    var medium: STGMEDIUM
    if mObj.GetData(&format, &medium) == S_OK:
      if medium.tymed == TYMED_HGLOBAL:
        let count = DragQueryFile(medium.u.hGlobal, -1, nil, 0)
        if count >= 1:
          return true

iterator getFiles*(self: wDataObject): string {.validate.} =
  ## Iterate each file in this file list.
  var format = FORMATETC(
    cfFormat: CF_HDROP,
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_HGLOBAL)

  var medium: STGMEDIUM
  if mObj.GetData(&format, &medium) == S_OK:
    if medium.tymed == TYMED_HGLOBAL:
      var buffer = T(65536)
      let count = DragQueryFile(medium.u.hGlobal, -1, nil, 0)
      for i in 0..<count:
        let length = DragQueryFile(medium.u.hGlobal, UINT i, &buffer, 65536)
        yield $buffer.substr(0, length - 1)

    ReleaseStgMedium(&medium)

proc getFiles*(self: wDataObject): seq[string] {.validate, inline.} =
  ## Gets the files list as seq.
  result = @[]
  for file in getFiles():
    result.add file

proc isBitmap*(self: wDataObject): bool {.validate.} =
  ## Checks the data is bitmap or not.
  var format = FORMATETC(
    cfFormat: CF_BITMAP,
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_GDI)

  if mObj.QueryGetData(&format) == S_OK:
    return true

proc getBitmap*(self: wDataObject): wBitmap {.validate.} =
  ## Gets the data in bitmap format.
  var format = FORMATETC(
    cfFormat: CF_BITMAP,
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_GDI)

  var medium: STGMEDIUM
  if mObj.GetData(&format, &medium) == S_OK:
    if medium.tymed == TYMED_GDI:
      result = Bmp(medium.u.hBitmap, copy=true)

    ReleaseStgMedium(&medium)

proc doDragDrop*(self: wDataObject, flags: int = wDragCopy or wDragMove or
    wDragLink): int {.validate, discardable.} =
  ## Starts the drag-and-drop operation which will terminate when the user
  ## releases the mouse. The result will be one of drag-drop effect,
  ## wDragCancel, or wDragError.

  # SHDoDragDrop better than DoDragDrop on:
  # 1. It provides a generic drag image.
  # 2. The Shell creates a drop source object for you.
  #    (According to MSDN, vista later, howevere, Windows XP also works)
  when not defined(wnimdoc):
    # I don't know why the docgen don't like following code, the proc will disappear
    var effect: DWORD
    result = case SHDoDragDrop(0, mObj, nil, flags, &effect)
    of DRAGDROP_S_DROP:
      effect
    of DRAGDROP_S_CANCEL:
      wDragCancel
    else:
      wDragError

proc delete*(self: wDataObject) {.validate.} =
  ## Nim's garbage collector will delete this object by default.
  ## However, sometimes you maybe want do that by yourself.
  ## Moreover, if the data object is still on the clipboard, delete
  ## it will force to flush it.
  if OleIsCurrentClipboard(mObj):
    OleFlushClipboard()

  if mReleasable and mObj != nil:
    mObj.Release()

  mObj = nil
  mBmp = nil

proc final*(self: wDataObject) {.validate.} =
  ## Default finalizer for wDataObject.
  delete()

proc init*(self: wDataObject, dataObj: ptr IDataObject) {.validate, inline.} =
  ## Initializer.
  mObj = dataObj
  mReleasable = false

proc DataObject*(dataObj: ptr IDataObject): wDataObject {.inline.} =
  ## Constructor.
  new(result, final)
  result.init(dataObj)

type
  SHCreateFileDataObjectType = proc (pidlFolder: PCIDLIST_ABSOLUTE,
    cidl: UINT, apidl: PCUITEMID_CHILD_ARRAY, pDataInner: ptr IDataObject,
    ppDataObj: ptr ptr IDataObject): HRESULT {.stdcall.}

var
  SHCreateFileDataObject {.threadvar.}: SHCreateFileDataObjectType

proc ensureSHCreateFileDataObject() =
  # Windows XP don't support SHCreateDataObject.
  # And SHCreateFileDataObject support CF_HDROP format.

  if SHCreateFileDataObject == nil:
    let lib = LoadLibrary("shell32.dll")
    SHCreateFileDataObject = cast[SHCreateFileDataObjectType](GetProcAddress(lib,
      cast[LPCSTR](740)))

proc init*(self: wDataObject, text: string) {.validate.} =
  ## Initializer.
  ensureSHCreateFileDataObject()
  if SHCreateFileDataObject(nil, 0, nil, nil, &mObj) != S_OK: error()

  # if SHCreateDataObject(nil, 0, nil, nil, &IID_IDataObject, &mObj) != S_OK:
  #   error()

  mReleasable = true

  var format = FORMATETC(
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_HGLOBAL)

  var medium = STGMEDIUM(tymed: TYMED_HGLOBAL)

  let
    wstr = +$text
    pWstr = GlobalAlloc(GPTR, SIZE_T wstr.len * 2 + 2)
    mstr = -$text
    pMstr = GlobalAlloc(GPTR, SIZE_T mstr.len + 1)

  if pWstr == 0 or pMstr == 0: error()
  cast[ptr WCHAR](pWstr) <<< wstr
  cast[ptr char](pMstr) <<< mstr

  format.cfFormat = CF_UNICODETEXT
  medium.u.hGlobal = pWstr
  if mObj.SetData(&format, &medium, TRUE) != S_OK: error()

  format.cfFormat = CF_TEXT
  medium.u.hGlobal = pMstr
  if mObj.SetData(&format, &medium, TRUE) != S_OK: error()

proc DataObject*(text: string): wDataObject {.inline.} =
  ## Constructor from text.
  new(result, final)
  result.init(text)

proc init*(self: wDataObject, files: openarray[string]) {.validate.} =
  ## Initializer.
  if files.len == 0: error()
  ensureSHCreateFileDataObject()

  var pidlDesk: PIDLIST_ABSOLUTE
  if SHGetSpecialFolderLocation(0, CSIDL_DESKTOP, &pidlDesk) != S_OK: error()
  defer: CoTaskMemFree(pidlDesk)

  var apidl = newSeqOfCap[PIDLIST_ABSOLUTE](files.len)
  var buffer = T(65536)
  for file in files:
    if GetFullPathName(file, 65536, &buffer, nil) == 0: error()
    var il = ILCreateFromPath(buffer)
    if il == nil: error()
    apidl.add(il)

  if SHCreateFileDataObject(pidlDesk, files.len, &apidl[0], nil, &mObj) != S_OK: error()
  mReleasable = true

  for il in apidl:
    ILFree(il)

proc DataObject*(files: openarray[string]): wDataObject {.inline.} =
  ## Constructor from files. The path must exist.
  new(result, final)
  result.init(files)

proc init*(self: wDataObject, bmp: wBitmap) {.validate.} =
  ## Initializer.
  wValidate(bmp)
  ensureSHCreateFileDataObject()
  if SHCreateFileDataObject(nil, 0, nil, nil, &mObj) != S_OK: error()
  mReleasable = true
  mBmp = Bmp(bmp)

  var format = FORMATETC(
    cfFormat: CF_BITMAP,
    dwAspect: DVASPECT_CONTENT,
    lindex: -1,
    tymed: TYMED_GDI)

  var medium = STGMEDIUM(tymed: TYMED_GDI)
  medium.u.hBitmap = mBmp.mHandle
  if mObj.SetData(&format, &medium, TRUE) != S_OK: error()

proc DataObject*(bmp: wBitmap): wDataObject {.inline.} =
  ## Constructor from bitmap.
  wValidate(bmp)
  new(result, final)
  result.init(bmp)

proc init*(self: wDataObject, dataObj: wDataObject) {.validate.} =
  ## Initializer.
  wValidate(dataObj)
  if dataObj.isText():
    init(dataObj.getText())
  elif dataObj.isFiles():
    init(dataObj.getFiles())
  elif dataObj.isBitmap():
    # don't add self it become wBitmap.init
    self.init(dataObj.getBitmap())
  else:
    error()

proc DataObject*(dataObj: wDataObject): wDataObject {.inline.} =
  ## Copy constructor.
  wValidate(dataObj)
  new(result, final)
  result.init(dataObj)







