using Reight


class Reight::Index

  include Reight::Activatable
  include Reight::Hookable
  include Reight::HasHelp

  def initialize(index = 0, &changed)
    super()
    @index = index

    hook :changed
    self.changed(&changed) if changed
  end

  attr_reader :index

  def draw()
    sp                 = sprite
    button_w, button_h = sp.h, sp.h

    no_stroke

    fill 230
    if pressing? && prev?
      rect 0,        0, sp.w / 2, button_h
    elsif pressing? && next?
      rect sp.w / 2, 0, sp.w / 2, button_h
    end

    fill 50
    text_align CENTER, CENTER
    text '<',   0,               0, button_w, button_h
    text '>',   sp.w - button_w, 0, button_w, button_h
    text index, 0,               0, sp.w,     sp.h
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
    old     = @index
    @index += 1 if next?
    @index -= 1 if prev?
    @index  = 0 if @index < 0
    changed! @index if @index != old
  end

  def sprite()
    @sprite ||= Sprite.new(physics: false).tap do |sp|
      sp.draw           {draw}
      sp.mouse_pressed  {pressed  sp.mouse_x, sp.mouse_y}
      sp.mouse_released {released sp.mouse_x, sp.mouse_y}
      sp.mouse_moved    {hover    sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {clicked}
    end
  end

end# Index
