#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## This class encapsulates the system bitmap. Notice: because there is
## a naming clash problem, wBitmap's constructor is named as Bmp().
## This is the only exception in wNim's naming convention.
#
## :Superclass:
##   `wGdiObject <wGdiObject.html>`_
#
## :Seealso:
##   `wDC <wDC.html>`_
##   `wPredefined <wPredefined.html>`_

type
  wBitmapError* = object of wGdiObjectError
    ## An error raised when wBitmap creation failure.

proc error(self: wBitmap) {.inline.} =
  raise newException(wBitmapError, "wBitmap creation failure")

proc final(self: wBitmap) =
  ## Default finalizer for wBitmap.
  delete()

proc init*(self: wBitmap, width, height: int, depth: int = 0) {.validate.} =
  ## Initializer.
  assert depth == 0 or depth == 24 or depth == 32
  self.wGdiObject.init()

  mWidth = width
  mHeight = height
  mDepth = depth

  if depth == 0:
    let hdc = GetDC(0)
    mDepth = GetDeviceCaps(hdc, PLANES) * GetDeviceCaps(hdc, BITSPIXEL)
    mHandle = CreateCompatibleBitmap(hdc, width, height)
    ReleaseDC(0, hdc)
  else:
    mDepth = depth
    mHandle = CreateBitmap(width, height, 1, depth, nil)

  if mHandle == 0: error()

proc Bmp*(width: int, height: int, depth: int = 0): wBitmap {.inline.} =
  ## Creates a new bitmap. A depth of 0 indicates the depth of the current screen.
  new(result, final)
  result.init(width, height, depth)

proc init*(self: wBitmap, size: wSize, depth: int = 0) {.validate.} =
  ## Initializer.
  init(size.width, size.height, depth)

proc Bmp*(size: wSize, depth: int = 0): wBitmap =
  ## Creates a new bitmap. A depth of 0 indicates the depth of the current screen.
  new(result, final)
  result.init(size, depth)

proc init*(self: wBitmap, gdipbmp: ptr GpBitmap) {.validate.} =
  self.wGdiObject.init()
  ## Initializer.
  # Here GdiplusStartupInput() should already called.
  if GdipCreateHBITMAPFromBitmap(gdipbmp, addr mHandle, 0) != Ok:
    error()

  mDepth = 32
  var width, height: UINT
  GdipGetImageWidth(gdipbmp, &width)
  GdipGetImageHeight(gdipbmp, &height)
  mWidth = width
  mHeight = height

proc Bmp*(gdipbmp: ptr GpBitmap): wBitmap {.inline.} =
  ## Creates a bitmap from a gdiplus bitmap handle.
  new(result, final)
  result.init(gdipbmp)

proc init*(self: wBitmap, image: wImage) {.validate.} =
  ## Initializer.
  wValidate(image)
  init(image.mGdipBmp)

proc Bmp*(image: wImage): wBitmap {.inline.} =
  ## Creates a bitmap object from the given wImage object.
  wValidate(image)
  new(result, final)
  result.init(image)

proc init*(self: wBitmap, filename: string) {.validate.} =
  ## Initializer.
  wValidate(filename)
  try:
    init(Image(filename))
  except:
    error()

proc Bmp*(filename: string): wBitmap {.inline.} =
  ## Creates a bitmap object from a image file.
  wValidate(filename)
  new(result, final)
  result.init(filename)

proc init*(self: wBitmap, data: ptr byte, length: int) {.validate.} =
  ## Initializer.
  try:
    init(Image(data, length))
  except:
    error()

proc Bmp*(data: ptr byte, length: int): wBitmap {.inline.} =
  ## Creates a bitmap object from raw image data.
  wValidate(data)
  new(result, final)
  result.init(data, length)

proc init*(self: wBitmap, handle: HBITMAP, copy = true) {.validate.} =
  ## Initializer.
  var bm: BITMAP
  if GetObject(handle, sizeof(BITMAP), &bm) == 0:
    error()

  if copy:
    init(bm.bmWidth, bm.bmHeight, 32)
    var
      hdcSrc = CreateCompatibleDC(0)
      hdcDst = CreateCompatibleDC(0)
      prevSrc = SelectObject(hdcSrc, handle)
      prevDst = SelectObject(hdcDst, mHandle)

    defer:
      SelectObject(hdcSrc, prevSrc)
      SelectObject(hdcDst, prevDst)
      DeleteDC(hdcSrc)
      DeleteDC(hdcDst)

    BitBlt(hdcDst, 0, 0, bm.bmWidth, bm.bmHeight, hdcSrc, 0, 0, SRCCOPY)

  else:
    self.wGdiObject.init()
    mHandle = handle
    mWidth = bm.bmWidth
    mHeight = bm.bmHeight
    mDepth = int bm.bmBitsPixel

proc Bmp*(handle: HBITMAP, copy = true): wBitmap {.inline.} =
  ## Creates a bitmap from a system bitmap handle.
  ## If copy is false, this only wrap it to wBitmap object.
  ## Notice this means the handle will be destroyed by wBitmap when it is destroyed.
  new(result, final)
  result.init(handle, copy)

proc init*(self: wBitmap, bmp: wBitmap) {.validate.} =
  ## Initializer.
  wValidate(bmp)
  init(bmp.mHandle, copy=true)

proc Bmp*(bmp: wBitmap): wBitmap {.inline.} =
  ## Copy constructor
  wValidate(bmp)
  new(result, final)
  result.init(bmp)

proc getSize*(self: wBitmap): wSize {.validate, property, inline.} =
  ## Returns the size of the bitmap in pixels.
  result = (mWidth, mHeight)

proc getWidth*(self: wBitmap): int {.validate, property, inline.} =
  ## Gets the width of the bitmap in pixels.
  result = mWidth

proc getHeight*(self: wBitmap): int {.validate, property, inline.} =
  ## Gets the height of the bitmap in pixels.
  result = mHeight

proc getDepth*(self: wBitmap): int {.validate, property, inline.} =
  ## Gets the color depth of the bitmap.
  result = mDepth
