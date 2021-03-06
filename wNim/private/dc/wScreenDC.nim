#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## A screen device context can be used to paint on the screen.
##
## Like other DC object, wScreenDC need nim's destructors to release the resource.
## For nim version 0.18.0, you must compile with --newruntime option to get
## destructor works.
#
## :Superclass:
##   `wDC <wDC.html>`_

proc ScreenDC*(): wScreenDC =
  ## Constructor.
  result.mHdc = GetDC(0)
  result.wDC.init()

proc delete*(self: var wScreenDC) =
  ## Nim's destructors will delete this object by default.
  ## However, sometimes you maybe want to do that by yourself.
  ## (Nim's destructors don't work in some version?)
  if mHdc != 0:
    self.wDC.final()
    ReleaseDC(0, mHdc)
    mHdc = 0

proc `=destroy`(self: var wScreenDC) = delete()
