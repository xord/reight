using Reight


class Reight::MapEditor::Canvas

  include Reight::Hookable

  def initialize(app, map, path)
    hook :tool_changed

    @app, @map, @path      = app, map, path
    @x, @y, @tool, @cursor = 0, 0, nil, nil, nil
  end

  attr_accessor :x, :y

  attr_reader :map, :tool, :cursor

  def save()
    @app.project.save
  end

  def tool=(tool)
    @tool = tool
    tool_changed! tool
  end

  def set_cursor(x, y, w, h)
    @cursor = correct_bounds x, y, w, h
  end

  def chip_at_cursor()
    x, y, = cursor
    map[@x + x, @y + y]
  end

  def begin_editing(&block)
    @app.history.begin_grouping
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    @app.history.end_grouping
    save
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      pos = -> {to_image sp.mouse_x, sp.mouse_y}
      sp.draw           {draw}
      sp.mouse_pressed  {mouse_pressed( *pos.call, sp.mouse_button)}
      sp.mouse_released {mouse_released(*pos.call, sp.mouse_button)}
      sp.mouse_moved    {mouse_moved(   *pos.call)}
      sp.mouse_dragged  {mouse_dragged( *pos.call, sp.mouse_button)}
      sp.mouse_clicked  {mouse_clicked( *pos.call, sp.mouse_button)}
    end
  end

  private

  def to_image(x, y)
    return x, y unless @x && @y
    return x - @x, y - @y
  end

  def correct_bounds(x, y, w, h)
    x, y, w, h = [x, y, w, h].map &:to_i
    return x / w * w, y / h * h, w, h
  end

  def draw()
    sp = sprite

    clip sp.x, sp.y, sp.w, sp.h
    translate @x, @y

    fill 0, 0, 0
    no_stroke
    rect(-@x, -@y, sp.w, sp.h)

    draw_grids

    map.each_chip(-@x, -@y, sp.w, sp.h, clip_by_chunk: true).each do |chip|
      pos = chip.pos
      copy chip.image, *chip.frame, pos.x, pos.y, chip.w, chip.h
    end

    if @cursor
      no_fill
      stroke 255, 255, 255
      stroke_weight 1
      rect(*@cursor)
    end
  end

  def draw_grids()
    push do
      app    = Reight::App
      sw, sh = app::SCREEN_WIDTH, app::SCREEN_HEIGHT
      mw, mh = sw * 10, sh * 10
      stroke 20
      shape grid 8,      8,      mw, mh if @app.pressing?(SPACE)
      stroke 50
      shape grid sw / 2, sh / 2, mw, mh
      stroke 100
      shape grid sw,     sh,     mw, mh
    end
  end

  def grid(xinterval, yinterval, xmax, ymax)
    (@grids ||= {})[xinterval] ||= create_shape.tap do |sh|
      sh.begin_shape LINES
      (0..xmax).step(xinterval).each do |x|
        sh.vertex x, 0
        sh.vertex x, ymax
      end
      (0..ymax).step(yinterval).each do |y|
        sh.vertex 0,    y
        sh.vertex xmax, y
      end
      sh.end_shape
    end
  end

  def mouse_pressed(...)
    tool&.canvas_pressed(...)  unless hand?
  end

  def mouse_released(...)
    tool&.canvas_released(...) unless hand?
  end

  def mouse_dragged(...)
    if hand?
      sp  = sprite
      @x += sp.mouse_x - sp.pmouse_x
      @y += sp.mouse_y - sp.pmouse_y
    else
      tool&.canvas_dragged(...)
    end
  end

  def mouse_moved(...)   = tool&.canvas_moved(...)
  def mouse_clicked(...) = tool&.canvas_clicked(...)

  def hand? = @app.pressing?(SPACE)

end# Canvas
