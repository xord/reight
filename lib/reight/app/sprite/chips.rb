using Reight


class Reight::SpriteEditor::Chips

  include Reight::Hookable

  def initialize(app, image, size = 8, &block)
    hook :frame_changed

    @app, @image = app, image
    @offset      = create_vector

    @app.history.disable do
      set_frame 0, 0, size, size
    end

    frame_changed(&block)
  end

  attr_reader :x, :y, :size

  def set_frame(x, y, w = size, h = size)
    raise 'Chips: width != height' if w != h
    @x    = align_to_grid(x).clamp(0..@image.width)
    @y    = align_to_grid(y).clamp(0..@image.height)
    @size = w
    frame_changed! @x, @y, @size, @size
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h

    fill 0
    no_stroke
    rect 0, 0, sp.w, sp.h

    translate(*clamp_offset(@offset).to_a)
    image @image, 0, 0

    no_fill
    stroke 255, 255, 255
    stroke_weight 1
    rect @x, @y, @size, @size
  end

  def mouse_pressed(x, y)
    @prev_pos = create_vector x, y
  end

  def mouse_released(x, y)
    @offset = clamp_offset @offset
  end

  def mouse_dragged(x, y)
    pos       = create_vector x, y
    @offset  += pos - @prev_pos if @prev_pos
    @prev_pos = pos
  end

  def mouse_clicked(x, y)
    set_frame(
      -@offset.x + align_to_grid(x),
      -@offset.y + align_to_grid(y))
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new.tap do |sp|
      sp.draw           {draw}
      sp.mouse_pressed  {mouse_pressed  sp.mouse_x, sp.mouse_y}
      sp.mouse_released {mouse_released sp.mouse_x, sp.mouse_y}
      sp.mouse_dragged  {mouse_dragged  sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {mouse_clicked  sp.mouse_x, sp.mouse_y}
    end
  end

  private

  def clamp_offset(offset)
    sp = sprite
    x  = offset.x.clamp([-(@image.width  - sp.w), 0].min..0)
    y  = offset.y.clamp([-(@image.height - sp.h), 0].min..0)
    create_vector align_to_grid(x), align_to_grid(y)
  end

  def align_to_grid(n)
    n.to_i / 8 * 8
  end

  def selected()
    @selected.call @x, @y, @size, @size
  end

end# Chips
