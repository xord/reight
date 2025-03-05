module Reight::Context

  include Processing::GraphicsContext
  include RubySketch::GraphicsContext

  TIMER_PREFIX__ = '__r8__'

  # @private
  def initialize(rootContext, project)
    @rootContext__, @project__ = rootContext, project
    init__ Rays::Image.new(@rootContext__.width, @rootContext__.height)
  end

  # Returns the project object.
  #
  def project()
    @project__
  end

  # @private
  def screenOffset(*args)
    unless args.empty?
      args    = args.flatten
      x, y, z =
        case arg = args.first
        when Vector  then [arg.x,   arg.y,        arg.z]
        when Numeric then [args[0], args[1] || 0, args[2] || 0]
        when nil     then [0,       0,            0]
        else raise ArgumentError
        end
      cx, cy, = @canvasFrame__
      if cx && cy
        zoom = spriteWorld__.zoom
        x   += cx / zoom
        y   += cy / zoom
      end
      spriteWorld__.offset = [x, y, z]
    end
    spriteWorld__.offset
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#size-instance_method
  def size(width, height, **)
    return if width == self.width || height == self.height
    @resizeCanvas__ = [width, height]
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#createCanvas-instance_method
  alias createCanvas size

  # @see https://www.rubydoc.info/gems/processing/Processing/Context#mouseX-instance_method
  def mouseX()
    x, (cx, _) = @rootContext__.mouseX,  @canvasFrame__
    cx ? (x - cx) / spriteWorld__.zoom : x
  end

  # @see https://www.rubydoc.info/gems/processing/Processing/Context#mouseY-instance_method
  def mouseY()
    y, (_, cy) = @rootContext__.mouseY,  @canvasFrame__
    cy ? (y - cy) / spriteWorld__.zoom : y
  end

  # @see https://www.rubydoc.info/gems/processing/Processing/Context#pmouseX-instance_method
  def pmouseX()
    x, (cx, _) = @rootContext__.pmouseX, @canvasFrame__
    cx ? (x - cx) / spriteWorld__.zoom : x
  end

  # @see https://www.rubydoc.info/gems/processing/Processing/Context#pmouseY-instance_method
  def pmouseY()
    y, (_, cy) = @rootContext__.pmouseY, @canvasFrame__
    cy ? (y - cy) / spriteWorld__.zoom : y
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#createSprite-instance_method
  def createSprite(*args, klass: nil, **kwargs, &block)
    klass ||= Reight::Sprite
    spriteWorld__.createSprite(*args, klass: klass, **kwargs, &block)
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#addSprite-instance_method
  def addSprite(...)
    spriteWorld__.addSprite(...)
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#removeSprite-instance_method
  def removeSprite(...)
    spriteWorld__.removeSprite(...)
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#gravity-instance_method
  def gravity(...)
    spriteWorld__.gravity(...)
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#setTimeout-instance_method
  def setTimeout( *a, id: @rootContext__.nextTimerID__, **k, &b)
    id = [TIMER_PREFIX__, id]
    @rootContext__.setTimeout(*a, id: id, **k, &b)
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#setInterval-instance_method
  def setInterval(*a, id: @rootContext__.nextTimerID__, **k, &b)
    id = [TIMER_PREFIX__, id]
    @rootContext__.setInterval(*a, id: id, **k, &b)
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#clearTimer-instance_method
  def clearTimer(id)
    @rootContext__.clearTimer [TIMER_PREFIX__, id]
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#clearTimeout-instance_method
  def clearTimeout(id)
    @rootContext__.clearTimeout [TIMER_PREFIX__, id]
  end

  # @see https://rubydoc.info/gems/rubysketch/RubySketch/Context#clearInterval-instance_method
  def clearInterval(id)
    @rootContext__.clearInterval [TIMER_PREFIX__, id]
  end

  # @private
  def beginDraw__()
    super
    @painter__.__send__ :begin_paint
  end

  # @private
  def endDraw__()
    @painter__.__send__ :end_paint
    super
    resizeCanvas__
  end

  # @private
  def spriteWorld__()
    @spriteWorld__ ||= SpriteWorld.new(pixelsPerMeter: 8)
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

    spriteWorld__.zoom = wide ? rootw.to_f / w : rooth.to_f / h
  end

  # @private
  attr_reader :canvasFrame__

end# Context
