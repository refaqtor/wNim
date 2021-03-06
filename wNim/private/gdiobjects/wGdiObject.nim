#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## wGdiObject is the superclasses of all the GDI objects, such as wPen, wBrush
## and wFont.
#
## :Subclasses:
##   `wPen <wPen.html>`_
##   `wBrusn <wBrusn.html>`_
##   `wFont <wFont.html>`_
##   `wBitmap <wBitmap.html>`_
##   `wIcon <wIcon.html>`_
##   `wCursor <wCursor.html>`_
#
## :Seealso:
##   `wDC <wDC.html>`_
##   `wPredefined <wPredefined.html>`_

type
  wGdiObjectError* = object of wError

proc getHandle*(self: wGdiObject): HANDLE {.validate, property, inline.} =
  ## Gets the real resource handle in system.
  result = mHandle

proc init*(self: wGdiObject) {.validate.} =
  ## Initializer.
  discard # do nothing for now

method delete*(self: wGdiObject) {.base, inline.} =
  ## Nim's garbage collector will delete this object by default.
  ## However, sometimes you maybe want do that by yourself.
  if mHandle != 0:
    DeleteObject(mHandle)
    mHandle = 0
