using Reight


class Reight::SpriteEditor::Chips

  include Reight::Hookable

  def initialize(app, image, size = 8)
    hook :frame_changed
    hook :offset_changed

    @app, @image = app, image
    @offset      = create_vector 0, 0

    @app.history.disable do
      set_frame 0, 0, size, size
    end
  end

  attr_reader :x, :y, :size, :offset

  def set_frame(x, y, w = size, h = size)
    raise 'Chips: width != height' if w != h
    @x    = align_to_grid(x).clamp(0..@image.width)
    @y    = align_to_grid(y).clamp(0..@image.height)
    @size = w
    frame_changed! @x, @y, @size, @size
  end

  def offset=(pos)
    sp      = sprite
    x       = pos.x.clamp([-(@image.width  - sp.w), 0].min..0)
    y       = pos.y.clamp([-(@image.height - sp.h), 0].min..0)
    offset  = create_vector x, y#align_to_grid(x), align_to_grid(y)
    return if offset == @offset
    @offset = offset
    offset_changed! @offset
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h

    fill 0
    no_stroke
    rect 0, 0, sp.w, sp.h

    translate offset.x, offset.y
    draw_offset_grids
    image @image, 0, 0
    draw_frame
  end

  def draw_offset_grids()
    no_fill
    stroke 50
    iw, ih = @app.project.then {[_1.chips_image_width, _1.chips_image_height]}
    cw, ch = @app.project.then {[_1.chips_page_width,  _1.chips_page_height]}
    (cw...iw).step(cw) {|x| line x, 0, x,  ih}
    (ch...ih).step(ch) {|y| line 0, y, iw, y}
  end

  def draw_frame()
    no_fill
    stroke 255
    stroke_weight 1
    rect @x, @y, @size, @size
  end

  def mouse_pressed(x, y)
    @prev_pos = create_vector x, y
  end

  def mouse_released(x, y)
  end

  def mouse_dragged(x, y)
    pos          = create_vector x, y
    self.offset += pos - @prev_pos if @prev_pos
    @prev_pos    = pos
  end

  def mouse_clicked(x, y)
    set_frame(
      -offset.x + align_to_grid(x),
      -offset.y + align_to_grid(y))
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

  def align_to_grid(n)
    n.to_i / 8 * 8
  end

  def selected()
    @selected.call @x, @y, @size, @size
  end

end# Chips
