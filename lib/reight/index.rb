using Reight


class Reight::Index

  include Reight::Activatable
  include Reight::Hookable
  include Reight::HasHelp

  def initialize(index = 0, min: 0, max: nil, &changed)
    hook :changed

    super()
    @min, @max = min, max

    self.changed(&changed) if changed
    self.index = index
  end

  attr_reader :index

  def index=(index)
    index = index.clamp(@max ? (@min..@max) : (@min..))
    return if index == @index
    @index = index.to_i
    changed! @index
  end

  def draw()
    no_stroke

    sp   = sprite
    w, h = sp.w, sp.h
    dec  = pressing? && prev?
    inc  = pressing? && next?
    decy = dec ? 1 : 0
    incy = inc ? 1 : 0

    fill 220
    rect 0,     decy, h, h, 2 if dec
    rect w - h, incy, h, h, 2 if inc

    text_align CENTER, CENTER
    fill 220
    text '<',   0,     decy + 1, h, h
    text '>',   w - h, incy + 1, h, h
    text index, 0,     1,        w, h
    fill 50
    text '<',   0,     decy,     h, h
    text '>',   w - h, incy,     h, h
    text index, 0,     0,        w, h
  end

  def prev? = sprite.mouse_x < sprite.w / 2

  def next? = !prev?

  def pressed(x, y)
    @pressing = true
  end

  def released(x, y)
    @pressing = false
  end

  def pressing? = @pressing

  def hover(x, y)
    r8.flash x < (sprite.w / 2) ? 'Prev' : 'Next'
  end

  def clicked()
    self.index += 1 if next?
    self.index -= 1 if prev?
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new(physics: false).tap do |sp|
      sp.draw           {draw}
      sp.mouse_pressed  {pressed  sp.mouse_x, sp.mouse_y}
      sp.mouse_released {released sp.mouse_x, sp.mouse_y}
      sp.mouse_moved    {hover    sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {clicked}
    end
  end

end# Index
