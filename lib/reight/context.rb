module Reight::Context

  include Processing::GraphicsContext
  include RubySketch::GraphicsContext

  TIMER_PREFIX__ = '__r8__'

  def initialize(rootContext, project)
    @rootContext__, @project__ = rootContext, project
    init__ Rays::Image.new(@rootContext__.width, @rootContext__.height)
  end

  def project()
    @project__
  end

  def size(width, height, **)
    return if width == self.width || height == self.height
    @resizeCanvas__ = [width, height]
  end

  alias createCanvas size

  def createSprite(...)
    spriteWorld__.createSprite(...)
  end

  def addSprite(...)
    spriteWorld__.addSprite(...)
  end

  def removeSprite(...)
    spriteWorld__.removeSprite(...)
  end

  def gravity(...)
    spriteWorld__.gravity(...)
  end

  def mouseX()
    (cx, _, cw),    x = @canvasFrame__, @rootContext__.mouseX
    cx && cw ? (x - cx) * (width  / cw) : x
  end

  def mouseY()
    (_, cy, _, ch), y = @canvasFrame__, @rootContext__.mouseY
    cy && ch ? (y - cy) * (height / ch) : y
  end

  def pmouseX()
    (cx, _, cw),    x = @canvasFrame__, @rootContext__.mouseX
    cx && cw ? (x - cx) * (width  / cw) : x
  end

  def pmouseY()
    (_, cy, _, ch), y = @canvasFrame__, @rootContext__.mouseY
    cy && ch ? (y - cy) * (height / ch) : y
  end

  def setTimeout( *a, id: @rootContext__.nextTimerID__, **k, &b)
    id = [TIMER_PREFIX__, id]
    @root_context__.setTimeout(*a, id: id, **k, &b)
  end

  def setInterval(*a, id: @rootContext__.nextTimerID__, **k, &b)
    id = [TIMER_PREFIX__, id]
    @rootContext__.setInterval(*a, id: id, **k, &b)
  end

  def clearTimer(id)
    @rootContext__.clearTimer [TIMER_PREFIX__, id]
  end

  def clearTimeout(id)
    @rootContext__.clearTimeout [TIMER_PREFIX__, id]
  end

  def clearInterval(id)
    @rootContext__.clearInterval [TIMER_PREFIX__, id]
  end

  # @private
  def beginDraw__()
    super
    @painter__.__send__ :begin_paint
    push
  end

  # @private
  def endDraw__()
    pop
    @painter__.__send__ :end_paint
    super
    resizeCanvas__
  end

  # @private
  def spriteWorld__()
    @spriteWorld__ ||= SpriteWorld.new(pixels_per_meter: 8)
  end

  # @private
  def resizeCanvas__()
    w, h            = @resizeCanvas__ || return
    @resizeCanvas__ = nil
    updateCanvas__ Rays::Image.new(w.to_i, h.to_i)

    rootw, rooth = @rootContext__.width, @rootContext__.height
    if w == rootw && h == rooth
      @canvasFrame__ = nil
    else
      wide           = w.to_f / h >= rootw.to_f / rooth
      canvasw        = wide ? rootw                : rooth * (w.to_f / h)
      canvash        = wide ? rootw * (h.to_f / w) : rooth
      @canvasFrame__ = [
        (rootw - canvasw) / 2,
        (rooth - canvash) / 2,
        canvasw,
        canvash
      ].map(&:to_i)
    end
  end

  # @private
  attr_reader :canvasFrame__

end# Context
