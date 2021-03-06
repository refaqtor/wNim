#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## This class encapsulates a platform-independent image. In wNim, wImage is
## a wrap of gdiplus image object.
#
## :Seealso:
##   `wImageList <wImageList.html>`_
##   `wBitmap <wBitmap.html>`_
##   `wIcon <wIcon.html>`_
##   `wCursor <wCursor.html>`_
#
## :Consts:
##
##   The quality used in scale, rescale, transform, and retransform.
##   ==============================  =============================================================
##   Consts                          Description
##   ==============================  =============================================================
##   wImageQualityNearest            Specifies nearest-neighbor interpolation.
##   wImageQualityBilinear           Specifies high-quality, bilinear interpolation.
##   wImageQualityBicubic            Specifies high-quality, bicubic interpolation.
##   wImageQualityNormal             Specifies the default interpolation mode.
##   wImageQualityHigh               Specifies a high-quality mode.
##   wImageQualityLow                Specifies a low-quality mode.
##   ==============================  =============================================================
##
##   Used in rotateFlip as flag.
##   ==============================  =============================================================
##   Consts                          Description
##   ==============================  =============================================================
##   wImageRotateNoneFlipNone        Specifies no rotation and no flipping.
##   wImageRotateNoneFlipX           Specifies no rotation and a horizontal flip.
##   wImageRotateNoneFlipY           Specifies no rotation and a vertical flip.
##   wImageRotateNoneFlipXY          Specifies no rotation, a horizontal flip, and then a vertical flip.
##   wImageRotate90FlipNone          Specifies a 90-degree rotation without flipping.
##   wImageRotate90FlipX             Specifies a 90-degree rotation followed by a horizontal flip.
##   wImageRotate90FlipY             Specifies a 90-degree rotation followed by a vertical flip.
##   wImageRotate90FlipXY            Specifies a 90-degree rotation followed by a horizontal flip and then a vertical flip.
##   wImageRotate180FlipNone         Specifies a 180-degree rotation without flipping.
##   wImageRotate180FlipX            Specifies a 180-degree rotation followed by a horizontal flip.
##   wImageRotate180FlipY            Specifies a 180-degree rotation followed by a vertical flip.
##   wImageRotate180FlipXY           Specifies a 180-degree rotation followed by a horizontal flip and then a vertical flip.
##   wImageRotate270FlipNone         Specifies a 270-degree rotation without flipping.
##   wImageRotate270FlipX            Specifies a 270-degree rotation followed by a horizontal flip.
##   wImageRotate270FlipY            Specifies a 270-degree rotation followed by a vertical flip.
##   wImageRotate270FlipXY           Specifies a 270-degree rotation followed by a horizontal flip and then a vertical flip.
##   ==============================  =============================================================

type
  wImageError* = object of wError
    ## An error raised when wImage creation or operation failure.

const
  # Image styles and consts
  wImageQualityNearest* = interpolationModeNearestNeighbor
  wImageQualityBilinear* = interpolationModeHighQualityBilinear
  wImageQualityBicubic* = interpolationModeHighQualityBicubic
  wImageQualityNormal* = interpolationModeDefault
  wImageQualityHigh* = interpolationModeHighQuality
  wImageQualityLow* = interpolationModeLowQuality

  wImageRotateNoneFlipNone* = rotateNoneFlipNone
  wImageRotateNoneFlipX* = rotateNoneFlipX
  wImageRotateNoneFlipY* = rotateNoneFlipY
  wImageRotateNoneFlipXY* = rotateNoneFlipXY
  wImageRotate90FlipNone* = rotate90FlipNone
  wImageRotate90FlipX* = rotate90FlipX
  wImageRotate90FlipY* = rotate90FlipY
  wImageRotate90FlipXY* = rotate90FlipXY
  wImageRotate180FlipNone* = rotate180FlipNone
  wImageRotate180FlipX* = rotate180FlipX
  wImageRotate180FlipY* = rotate180FlipY
  wImageRotate180FlipXY* = rotate180FlipXY
  wImageRotate270FlipNone* = rotate270FlipNone
  wImageRotate270FlipX* = rotate270FlipX
  wImageRotate270FlipY* = rotate270FlipY
  wImageRotate270FlipXY* = rotate270FlipXY

  wIMAGE_TYPE_BMP* = "BMP"
  wIMAGE_TYPE_GIF* = "GIF"
  wIMAGE_TYPE_JPEG* = "JPG"
  wIMAGE_TYPE_PNG* = "PNG"
  wIMAGE_TYPE_TIFF* = "TIF"
  wIMAGE_TYPE_ICO* = "ICO"
  wBITMAP_TYPE_BMP* = "BMP"
  wBITMAP_TYPE_GIF* = "GIF"
  wBITMAP_TYPE_JPEG* = "JPG"
  wBITMAP_TYPE_PNG* = "PNG"
  wBITMAP_TYPE_TIFF* = "TIF"
  wBITMAP_TYPE_ICO* = "ICO"

proc error(self: wImage) {.inline.} =
  raise newException(wImageError, "wImage creation failure")

converter GpImageToGpBitmap(x: ptr GpBitmap): ptr GpImage = cast[ptr GpImage](x)

type
  SHCreateMemStreamType = proc (pInit: pointer, cbInit: UINT): ptr IStream {.stdcall.}

var
  wGdiplusToken {.threadvar.}: ULONG_PTR
  SHCreateMemStream {.threadvar.}: SHCreateMemStreamType

proc wGdipInit() =
  if wGdiplusToken == 0:
    var si = GdiplusStartupInput(GdiplusVersion: 1)
    GdiplusStartup(&wGdiplusToken, si, nil)

proc wGdipCreateStreamOnMemory(data: pointer, length: int = 0): ptr IStream =
  if SHCreateMemStream == nil:
    # Prior to Windows Vista, this function was not included in the public Shlwapi.h file,
    # nor was it exported by name from Shlwapi.dll. To use it on earlier systems,
    # you must call it directly from the Shlwapi.dll file as ordinal 12.

    let lib = LoadLibrary("shlwapi.dll")
    SHCreateMemStream = cast[SHCreateMemStreamType](GetProcAddress(lib, cast[LPCSTR](12)))

  result = SHCreateMemStream(data, length.UINT)

proc wGdipReadStream(stream: ptr IStream, data: var string) =
  var stg: STATSTG
  if stream.Stat(&stg, STATFLAG_NONAME) != S_OK: raise

  var dlibMove = LARGE_INTEGER(QuadPart: 0)
  if stream.Seek(dlibMove, STREAM_SEEK_SET, nil) != S_OK: raise

  var length = stg.cbSize.LowPart
  data = newString(length)

  var bytesRead: ULONG
  if stream.Read(&data, length, &bytesRead) != S_OK: raise
  data.setLen(bytesRead)

proc wGdipAlign(x, y: var int32, width1, height1, width2, height2: int32, align: int) =
  if (align and wCenter) == wCenter:
    x = (width1 - width2) div 2
  elif (align and wRight) != 0:
    x = width1 - width2
  elif (align and wLeft) != 0:
    x = 0

  if (align and wMiddle) == wMiddle:
    y = (height1 - height2) div 2
  elif (align and wDown) != 0:
    y = height1 - height2
  elif (align and wUp) != 0:
    y = 0

iterator wGdipEncoderExtClsids(): tuple[ext: string, clsid: CLSID] =
  var count, size: UINT
  if GdipGetImageEncodersSize(&count, &size) != Ok: raise

  var encoders = cast[ptr UncheckedArray[ImageCodecInfo]](alloc(size))
  defer: dealloc(encoders)

  if GdipGetImageEncoders(count, size, &encoders[0]) != Ok: raise
  for i in 0..<count:
    for ext in ($encoders[i].FilenameExtension).split({';'}):
      yield (ext.replace("*.", ""), encoders[i].Clsid)

iterator wGdipDecoderExt(): string =
  var count, size: UINT
  if GdipGetImageDecodersSize(&count, &size) != Ok: raise

  var decoders = cast[ptr UncheckedArray[ImageCodecInfo]](alloc(size))
  defer: dealloc(decoders)

  if GdipGetImageDecoders(count, size, &decoders[0]) != Ok: raise
  for i in 0..<count:
    for ext in ($decoders[i].FilenameExtension).split({';'}):
      yield ext.replace("*.", "")

proc wGdipGetEncoderCLSID(fileType: string): CLSID =
  for tup in wGdipEncoderExtClsids():
    if fileType.cmpIgnoreCase(tup.ext) == 0:
      return tup.clsid

  raise

proc wGdipScale(gdipbmp: ptr GpBitmap, width, height: int,
    quality: InterpolationMode): ptr GpBitmap =

  var graphic: ptr GpGraphics
  try:
    if GdipCreateBitmapFromScan0(width, height, 4 * width,
        pixelFormat32bppARGB, nil, &result) != Ok: raise
    if GdipGetImageGraphicsContext(result, &graphic) != Ok: raise
    if GdipSetInterpolationMode(graphic, quality) != Ok: raise
    if GdipDrawImageRectI(graphic, gdipbmp, 0, 0, width, height) != Ok: raise
  except:
    if result != nil:
      GdipDisposeImage(result)
      result = nil
  finally:
    if graphic != nil:
      GdipDeleteGraphics(graphic)

proc wGdipSize(gdipbmp: ptr GpBitmap, size: wSize, pos: wPoint,
    align: int = 0): ptr GpBitmap =

  var graphic: ptr GpGraphics
  try:
    var
      width = int32 size.width
      height = int32 size.height
      width2, height2: int32
      x = int32 pos.x
      y = int32 pos.y

    if GdipGetImageWidth(gdipbmp, cast[ptr UINT](&width2)) != Ok: raise
    if GdipGetImageHeight(gdipbmp, cast[ptr UINT](&height2)) != Ok: raise

    if width2 <= 0 or height2 <= 0: raise
    if align != 0: wGdipAlign(x, y, width, height, width2, height2, align)

    if GdipCreateBitmapFromScan0(width, height, 4 * width, pixelFormat32bppARGB,
      nil, &result) != Ok: raise
    if GdipGetImageGraphicsContext(result, &graphic) != Ok: raise
    if GdipDrawImageRectI(graphic, gdipbmp, x, y, width2, height2) != Ok: raise
  except:
    if result != nil:
      GdipDisposeImage(result)
      result = nil
  finally:
    if graphic != nil:
      GdipDeleteGraphics(graphic)

proc wGdipTransform(gdipbmp: ptr GpBitmap, scaleX, scaleY, angle,
    deltaX, deltaY: float, quality: InterpolationMode): ptr GpBitmap =

  var graphic: ptr GpGraphics
  try:
    var width, height: int32
    if GdipGetImageWidth(gdipbmp, cast[ptr UINT](&width)) != Ok: raise
    if GdipGetImageHeight(gdipbmp, cast[ptr UINT](&height)) != Ok: raise
    if width <= 0 or height <= 0: raise

    if GdipCreateBitmapFromScan0(width, height, 4 * width, pixelFormat32bppARGB,
      nil, &result) != Ok: raise
    if GdipGetImageGraphicsContext(result, &graphic) != Ok: raise
    if GdipSetInterpolationMode(graphic, quality) != Ok: raise

    var
      newWidth = int32(width.float * scaleX)
      newHeight = int32(height.float * scaleY)
      diffX = width - newWidth
      diffY = height - newHeight
      centerX = width / 2
      centerY = height / 2

    if GdipTranslateWorldTransform(graphic, centerX + deltaX, centerY + deltaY,
      matrixOrderPrepend) != Ok: raise
    if GdipRotateWorldTransform(graphic, angle, matrixOrderPrepend) != Ok: raise
    if GdipTranslateWorldTransform(graphic, -centerX, -centerY,
      matrixOrderPrepend) != Ok: raise
    if GdipDrawImageRectI(graphic, gdipbmp, diffX div 2, diffY div 2,
      newWidth, newHeight) != Ok: raise

  except:
    if result != nil:
      GdipDisposeImage(result)
      result = nil
  finally:
    if graphic != nil:
      GdipDeleteGraphics(graphic)

proc wGdipPaste(gdipbmp1, gdipbmp2: ptr GpBitmap, x, y: int32, align: int = 0): bool =
  var
    width1, height1, width2, height2: int32
    graphic: ptr GpGraphics
    x = x
    y = y

  if GdipGetImageWidth(gdipbmp1, cast[ptr UINT](&width1)) != Ok: return false
  if GdipGetImageHeight(gdipbmp1, cast[ptr UINT](&height1)) != Ok: return false
  if GdipGetImageWidth(gdipbmp2, cast[ptr UINT](&width2)) != Ok: return false
  if GdipGetImageHeight(gdipbmp2, cast[ptr UINT](&height2)) != Ok: return false

  if width1 <= 0 or height1 <= 0 or width2 <= 0 or height2 <= 0: return false
  if align != 0: wGdipAlign(x, y, width1, height1, width2, height2, align)

  if GdipGetImageGraphicsContext(gdipbmp1, &graphic) != Ok: return false
  defer: GdipDeleteGraphics(graphic)

  if GdipDrawImageRectI(graphic, gdipbmp2, x, y, width2, height2) != Ok: return false
  return true

proc wGdipGetQualityParameters(quality: var LONG): EncoderParameters =
  result.Count = 1
  result.Parameter[0].Guid = EncoderQuality
  result.Parameter[0].Type = encoderParameterValueTypeLong.ord
  result.Parameter[0].NumberOfValues = 1;
  result.Parameter[0].Value = &quality

proc delete*(self: wImage) {.validate.} =
  ## Nim's garbage collector will delete this object by default.
  ## However, sometimes you maybe want do that by yourself.
  if mGdipBmp != nil:
    GdipDisposeImage(mGdipBmp)
    mGdipBmp = nil

proc getHandle*(self: wImage): ptr GpBitmap {.validate, property, inline.} =
  ## Gets the real resource handle of gdiplus bitmap.
  result = mGdipBmp

proc getWidth*(self: wImage): int {.validate, property.} =
  ## Gets the width of the image in pixels.
  var width: UINT
  if GdipGetImageWidth(mGdipBmp, &width) != Ok:
    raise newException(wImageError, "wImage getWidth failure")
  result = int width

proc getHeight*(self: wImage): int {.validate, property.} =
  ## Gets the height of the image in pixels.
  var height: UINT
  if GdipGetImageHeight(mGdipBmp, &height) != Ok:
    raise newException(wImageError, "wImage getHeight failure")
  result = int height

proc getSize*(self: wImage): wSize {.validate, property, inline.} =
  ## Returns the size of the image in pixels.
  result.width = getWidth()
  result.height = getHeight()

proc getPixel*(self: wImage, x: int, y: int): ARGB {.validate, property.} =
  ## Return the ARGB value at given pixel location.
  if GdipBitmapGetPixel(mGdipBmp, x, y, &result) != Ok:
    raise newException(wImageError, "wImage getPixel failure")

proc getPixel*(self: wImage, pos: wPoint): ARGB {.validate, property.} =
  ## Return the ARGB value at given pixel location.
  result = getPixel(pos.x, pos.y)

proc setPixel*(self: wImage, x: int, y: int, color: ARGB) {.validate, property.} =
  ## Set the ARGB value at given pixel location.
  if GdipBitmapSetPixel(mGdipBmp, x, y, color) != Ok:
    raise newException(wImageError, "wImage setPixel failure")

proc setPixel*(self: wImage, pos: wPoint, color: ARGB) {.validate, property.} =
  ## Set the ARGB value at given pixel location.
  setPixel(pos.x, pos.y, color)

proc getRed*(self: wImage, x: int, y: int): byte {.validate, property.} =
  ## Returns the red intensity at the given coordinate.
  try:
    result = GetRValue(getPixel(x, y))
  except:
    raise newException(wImageError, "wImage getRed failure")

proc getRed*(self: wImage, pos: wPoint): byte {.validate, property.} =
  ## Returns the red intensity at the given coordinate.
  result = getRed(pos.x, pos.y)

proc getGreen*(self: wImage, x: int, y: int): byte {.validate, property.} =
  ## Returns the green intensity at the given coordinate.
  try:
    result = GetGValue(getPixel(x, y))
  except:
    raise newException(wImageError, "wImage getGreen failure")

proc getGreen*(self: wImage, pos: wPoint): byte {.validate, property.} =
  ## Returns the green intensity at the given coordinate.
  result = getGreen(pos.x, pos.y)

proc getBlue*(self: wImage, x: int, y: int): byte {.validate, property.} =
  ## Returns the blue intensity at the given coordinate.
  try:
    result = GetBValue(getPixel(x, y))
  except:
    raise newException(wImageError, "wImage getBlue failure")

proc getBlue*(self: wImage, pos: wPoint): byte {.validate, property.} =
  ## Returns the blue intensity at the given coordinate.
  result = getBlue(pos.x, pos.y)

proc getAlpha*(self: wImage, x: int, y: int): byte {.validate, property.} =
  ## Return alpha value at given pixel location.
  try:
    result = cast[byte](getPixel(x, y) shr 24)
  except:
    raise newException(wImageError, "wImage getAlpha failure")

proc getAlpha*(self: wImage, pos: wPoint): byte {.validate, property.} =
  ## Return alpha value at given pixel location.
  result = getAlpha(pos.x, pos.y)

iterator getEncoders*(self: wImage): string {.validate.} =
  ## Iterates over each available image encoder on system.
  # also use validate pragma to ensure wGdipInit() was called.
  try:
    for tup in wGdipEncoderExtClsids():
      yield tup.ext
  except:
    raise newException(wImageError, "wImage getEncoders failure")

iterator getDecoders*(self: wImage): string {.validate.} =
  ## Iterates over each available image decoder on system.
  # also use validate pragma to ensure wGdipInit() was called.
  try:
    for ext in wGdipDecoderExt():
      yield ext
  except:
    raise newException(wImageError, "wImage getEncoders failure")

proc saveFile*(self: wImage, filename: string, fileType = "",
    quality: range[0..100] = 90) {.validate.} =
  ## Saves an image into the file. If fileType is empty, use extension name as
  ## fileType. Use getEncoders iterator to list the supported format.
  wValidate(filename)
  try:
    var ext = fileType
    if ext.len == 0:
      let dot = filename.rfind('.')
      if dot == -1: raise

      ext = filename.substr(dot + 1)
      if ext.len == 0: raise

    var
      quality: LONG = quality
      encoderParameters = wGdipGetQualityParameters(quality)
      clsid = wGdipGetEncoderCLSID(ext)

    if GdipSaveImageToFile(mGdipBmp, +$filename, clsid, &encoderParameters) != Ok: raise

  except:
    raise newException(wImageError, "wImage saveFile failure")

proc saveData*(self: wImage, fileType: string, quality: range[0..100] = 90): string
    {.validate.} =
  ## Saves an image into binary data (stored as string).
  ## Use getEncoders iterator to list the supported format.
  wValidate(fileType)
  try:
    var
      quality: LONG = quality
      encoderParameters = wGdipGetQualityParameters(quality)
      clsid = wGdipGetEncoderCLSID(fileType)

    let stream = wGdipCreateStreamOnMemory(nil)
    defer:
      if stream != nil: stream.Release()

    if stream == nil or GdipSaveImageToStream(mGdipBmp, stream, clsid,
      &encoderParameters) != Ok: raise
    wGdipReadStream(stream, result)

  except:
    raise newException(wImageError, "wImage saveData failure")

proc final(self: wImage) =
  ## Default finalizer for wImage.
  delete()

proc init*(self: wImage, gdip: ptr GpBitmap, copy = true) {.validate.} =
  ## Initializer.
  wValidate(gdip)
  wGdipInit()
  if copy:
    if GdipCloneImage(gdip, cast[ptr ptr GpImage](&mGdipBmp)) != Ok:
      error()
  else:
    mGdipBmp = gdip

proc Image*(gdip: ptr GpBitmap, copy = true): wImage {.inline.} =
  ## Creates an image from a gdiplus bitmap handle.
  ## If copy is false, this only wrap it to wImage object.
  ## Notice this means the handle will be destroyed by wImage when it is destroyed.
  wValidate(gdip)
  new(result, final)
  result.init(gdip, copy)

proc init*(self: wImage, image: wImage) {.validate, inline.} =
  ## Initializer.
  wValidate(image)
  init(image.mGdipBmp, copy=true)

proc Image*(image: wImage): wImage {.inline.} =
  ## Creates an image from wImage object, aka. copy constructors.
  wValidate(image)
  new(result, final)
  result.init(image)

proc init*(self: wImage, bmp: wBitmap) {.validate.} =
  ## Initializer.
  wValidate(bmp)
  wGdipInit()
  if GdipCreateBitmapFromHBITMAP(bmp.mHandle, 0, &mGdipBmp) != Ok:
    error()

proc Image*(bmp: wBitmap): wImage {.inline.} =
  ## Creates an image from wBitmap object.
  wValidate(bmp)
  new(result, final)
  result.init(bmp)

proc init*(self: wImage, data: ptr byte, length: int) {.validate.} =
  ## Initializer.
  wValidate(data)
  wGdipInit()
  let stream = wGdipCreateStreamOnMemory(data, length)
  defer:
    if stream != nil: stream.Release()

  if stream == nil or GdipCreateBitmapFromStream(stream, &mGdipBmp) != Ok:
    error()

proc Image*(data: ptr byte, length: int): wImage {.inline.} =
  ## Creates an image from binary image data.
  ## Use getDecoders iterator to list the supported format.
  wValidate(data)
  new(result, final)
  result.init(data, length)

proc init*(self: wImage, str: string) {.validate.} =
  ## Initializer.
  wValidate(str)
  wGdipInit()
  if str.isVaildPath():
    if GdipCreateBitmapFromFile(str, &mGdipBmp) != Ok:
      error()
  else:
    init(cast[ptr byte](&str), str.len)

proc Image*(str: string): wImage {.inline.} =
  ## Creates an image from a file.
  ## Use getDecoders iterator to list the supported format.
  ## If str is not a valid file path, it will be regarded as the binary data in memory.
  ## For example:
  ##
  ## .. code-block:: Nim
  ##   const data = staticRead("test.png")
  ##   var image = Image(data)
  wValidate(str)
  new(result, final)
  result.init(str)

proc init*(self: wImage, width: int, height: int) {.validate.} =
  ## Initializer.
  wGdipInit()
  if GdipCreateBitmapFromScan0(width, height, 4 * width, pixelFormat32bppARGB,
      nil, &mGdipBmp) != Ok:
    error()

proc Image*(width: int, height: int): wImage {.inline.} =
  ## Creates an empty image with the given size.
  new(result, final)
  result.init(width, height)

proc init*(self: wImage, size: wSize) {.validate, inline.} =
  ## Initializer.
  init(size.width, size.height)

proc Image*(size: wSize): wImage {.inline.} =
  ## Creates an empty image with the given size.
  new(result, final)
  result.init(size)

proc scale*(self: wImage, width, height: int, quality = wImageQualityNormal): wImage
    {.validate.} =
  ## Returns a scaled version of the image.
  let newGdipbmp = wGdipScale(mGdipBmp, width, height, quality)
  if newGdipbmp.isNil: raise newException(wImageError, "wImage scale failure")
  result = Image(newGdipbmp, copy=false)

proc scale*(self: wImage, size: wSize, quality = wImageQualityNormal): wImage
    {.validate, inline.} =
  ## Returns a scaled version of the image.
  result = scale(size.width, size.height, quality)

proc rescale*(self: wImage, width, height: int, quality = wImageQualityNormal)
    {.validate, discardable.} =
  ## Changes the size of the image in-place by scaling it.
  let newGdipbmp = wGdipScale(mGdipBmp, width, height, quality)
  if newGdipbmp.isNil: raise newException(wImageError, "wImage rescale failure")
  GdipDisposeImage(mGdipBmp)
  mGdipBmp = newGdipbmp

proc rescale*(self: wImage, size: wSize, quality = wImageQualityNormal)
    {.validate, inline, discardable.} =
  ## Changes the size of the image in-place by scaling it.
  rescale(size.width, size.height, quality)

proc size*(self: wImage, size: wSize, pos: wPoint = (0, 0), align = 0): wImage
    {.validate.} =
  ## Returns a resized version of this image without scaling it.
  ## The image is pasted into a new image at the position pos or by given align.
  ## align can be combine of wRight, wCenter, wLeft, wUp, wMiddle, wDown.
  let newGdipbmp = wGdipSize(mGdipBmp, size, pos, align)
  if newGdipbmp.isNil: raise newException(wImageError, "wImage size failure")
  result = Image(newGdipbmp, copy=false)

proc size*(self: wImage, width, height: int, x, y: int = 0, align = 0): wImage
    {.validate, inline.} =
  ## Returns a resized version of this image without scaling it.
  result = size((width, height), (x, y), align)

proc resize*(self: wImage, size: wSize, pos: wPoint = (0, 0), align = 0)
    {.validate, discardable.} =
  ## Changes the size of the image in-place without scaling it.
  let newGdipbmp = wGdipSize(mGdipBmp, size, pos, align)
  if newGdipbmp.isNil: raise newException(wImageError, "wImage resize failure")
  GdipDisposeImage(mGdipBmp)
  mGdipBmp = newGdipbmp

proc resize*(self: wImage, width, height: int, x, y: int = 0, align = 0)
    {.validate, discardable.} =
  ## Changes the size of the image in-place without scaling it.
  resize((width, height), (x, y), align)

proc transform*(self: wImage, scaleX, scaleY: float = 1,
    angle, deltaX, deltaY: float = 0,
    quality = wImageQualityNormal): wImage {.validate.} =
  ## Returned a transformed version of this image by given parameters.
  let newGdipbmp = wGdipTransform(mGdipBmp, scaleX, scaleY, angle, deltaX, deltaY, quality)
  if newGdipbmp.isNil: raise newException(wImageError, "wImage transform failure")
  result = Image(newGdipbmp, copy=false)

proc retransform*(self: wImage, scaleX, scaleY: float = 1,
    angle, deltaX, deltaY: float = 0,
    quality = wImageQualityNormal) {.validate, discardable.} =
  ## Transforms the image in-place.
  let newGdipbmp = wGdipTransform(mGdipBmp, scaleX, scaleY, angle, deltaX, deltaY, quality)
  if newGdipbmp.isNil: raise newException(wImageError, "wImage transform failure")
  GdipDisposeImage(mGdipBmp)
  mGdipBmp = newGdipbmp

proc paste*(self: wImage, image: wImage, x, y: int = 0, align = 0)
    {.validate, discardable.} =
  ## Copy the data of the given image to the specified position in this image.
  wValidate(image)
  if not wGdipPaste(self.mGdipBmp, image.mGdipBmp, x, y, align):
    raise newException(wImageError, "wImage paste failure")

proc paste*(self: wImage, image: wImage, pos: wPoint, align = 0)
    {.validate, discardable.} =
  ## Copy the data of the given image to the specified position in this image.
  wValidate(image)
  paste(image, pos.x, pos.y, align)

proc rotateFlip*(self: wImage, flag: int) {.validate, discardable.} =
  ## Rotates or flip the image.
  if GdipImageRotateFlip(mGdipBmp, flag) != Ok:
    raise newException(wImageError, "wImage rotateFlip failure")

proc rotateFlip*(self: wImage, angle: int, flipX: bool, flipY: bool)
    {.validate, discardable.} =
  ## Rotates or flip the image. Angle should be one of 0, 90, 180, 270.
  type Flip = enum NONE, X, Y, XY
  var flip: Flip
  if flipX and flipY: flip = XY
  if flipX and not flipY: flip = X
  if not flipX and flipY: flip = Y
  if not flipX and not flipY: flip = NONE

  var flag: RotateFlipType
  case angle:
  of 0:
    flag = case flip:
    of NONE: wImageRotateNoneFlipNone
    of X: wImageRotateNoneFlipX
    of Y: wImageRotateNoneFlipY
    of XY: wImageRotateNoneFlipXY
  of 90:
    flag = case flip:
    of NONE: wImageRotate90FlipNone
    of X: wImageRotate90FlipX
    of Y: wImageRotate90FlipY
    of XY: wImageRotate90FlipXY
  of 180:
    flag = case flip:
    of NONE: wImageRotate180FlipNone
    of X: wImageRotate180FlipX
    of Y: wImageRotate180FlipY
    of XY: wImageRotate180FlipXY
  of 270:
    flag = case flip:
    of NONE: wImageRotate270FlipNone
    of X: wImageRotate270FlipX
    of Y: wImageRotate270FlipY
    of XY: wImageRotate270FlipXY
  else: raise newException(wImageError, "wImage rotateFlip failure")
  rotateFlip(flag)

proc getSubImage*(self: wImage, rect: wRect): wImage {.validate.} =
  ## Returns a sub image of the current one as long as the rect belongs entirely
  ## to the image.
  try:
    result = size((rect.width, rect.height), (-rect.x, -rect.y))
  except:
    raise newException(wImageError, "wImage getSubImage failure")

proc crop*(self: wImage, x, y, width, height: int): wImage {.validate.} =
  ## Returns a cropped image of the current one as long as the rect belongs
  ## entirely to the image.
  try:
    result = size((width, height), (-x, -y))
  except:
    raise newException(wImageError, "wImage crop failure")

when not defined(useWinXP):
  # need GDI+ 1.1, vista later
  proc effect(self: wImage, guid: GUID, pParam: pointer, size: int) {.validate.} =
    var
      effect: ptr CGpEffect
      rect: RECT
      newGdipbmp: ptr GpBitmap

    rect.right = getWidth()
    rect.bottom = getHeight()

    if GdipCreateEffect(guid, &effect) != Ok: raise
    defer: GdipDeleteEffect(effect)

    if GdipSetEffectParameters(effect, pParam, size.UINT) != Ok: raise
    # if GdipBitmapApplyEffect(mGdipBmp, effect, nil, false, nil, nil) != Ok: raise
    # GdipBitmapApplyEffect sometimes crash due to unknow reason (only 64bit)

    # if don't set rect, the image size will change?
    if GdipBitmapCreateApplyEffect(&mGdipBmp, 1, effect, &rect, nil, &newGdipbmp,
      false, nil, nil) != Ok: raise

    GdipDisposeImage(mGdipBmp)
    mGdipBmp = newGdipbmp

  proc blur*(self: wImage, radius: range[0..255] = 0, expandEdge = true)
      {.validate.} =
    ## Blur effect (Windows Vista or later).
    var param = BlurParams(radius: radius.float32, expandEdge: expandEdge)
    try:
      effect(BlurEffectGuid, &param, sizeof(param))
    except:
      raise newException(wImageError, "wImage blur failure")

  proc brightnessContrast*(self: wImage, brightness: range[-255..255] = 0,
      contrast: range[-100..100] = 0) {.validate.} =
    ## Brightness or contrast adjustment (Windows Vista or later).
    var param = BrightnessContrastParams(brightnessLevel: brightness,
      contrastLevel: contrast)

    try:
      effect(BrightnessContrastEffectGuid, &param, sizeof(param))
    except:
      raise newException(wImageError, "wImage brightnessContrast failure")

  proc sharpen*(self: wImage, radius: range[0..255] = 0, amount: range[0..100] = 0)
      {.validate.} =
    ## Sharpen effect (Windows Vista or later).
    var param = SharpenParams(radius: radius.float32, amount: amount.float32)
    try:
      effect(SharpenEffectGuid, &param, sizeof(param))
    except:
      raise newException(wImageError, "wImage sharpen failure")

  proc tint*(self: wImage, hue: range[-180..180] = 0, amount: range[0..100] = 0)
      {.validate.} =
    ## Tint effect (Windows Vista or later).
    var param = TintParams(hue: hue, amount: amount)
    try:
      effect(TintEffectGuid, &param, sizeof(param))
    except:
      raise newException(wImageError, "wImage tint failure")

  proc hueSaturationLightness*(self: wImage, hue: range[-180..180] = 0,
      saturation: range[-100..100] = 0, lightness: range[-100..100] = 0)
      {.validate.} =
    ## Hue, saturation, or lightness adjustment (Windows Vista or later).
    var param = HueSaturationLightnessParams(hueLevel: hue,
      saturationLevel: saturation, lightnessLevel: lightness)

    try:
      effect(HueSaturationLightnessEffectGuid, &param, sizeof(param))
    except:
      raise newException(wImageError, "wImage hueSaturationLightness failure")

  proc colorBalance*(self: wImage, cyanRed: range[-100..100] = 0,
      magentaGreen: range[-100..100] = 0, yellowBlue: range[-100..100] = 0)
      {.validate.} =
    ## Color balance adjustment (Windows Vista or later).
    var param = ColorBalanceParams(cyanRed: cyanRed, magentaGreen: magentaGreen,
      yellowBlue: yellowBlue)

    try:
      effect(ColorBalanceEffectGuid, &param, sizeof(param))
    except:
      raise newException(wImageError, "wImage colorBalance failure")

  proc levels*(self: wImage, highlight: range[0..100] = 0,
      midtone: range[-100..100] = 0, shadow: range[0..100] = 0) {.validate.} =
    ## Light, midtone, or dark adjustment (Windows Vista or later).
    var param = LevelsParams(highlight: highlight, midtone: midtone, shadow: shadow)
    try:
      effect(LevelsEffectGuid, &param, sizeof(param))
    except:
      raise newException(wImageError, "wImage levels failure")

