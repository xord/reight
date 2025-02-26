using Reight


class Reight::SpriteEditor::Canvas

  include Reight::Hookable

  def initialize(app, image, path)
    hook :color_changed

    @app, @image, @path       = app, image, path
    @tool, @color, @selection = nil, [255, 255, 255, 255], nil

    @app.history.disable do
      set_frame 0, 0, 16, 16
    end
  end

  attr_accessor :tool

  attr_reader :x, :y, :w, :h, :color

  def width  = @image.width

  def height = @image.height

  def save()
    @image.save @path
    @app.project.save
  end

  def set_frame(x, y, w, h)
    old            = [@x, @y, @w, @h]
    new            = correct_bounds x, y, w, h
    return if new == old
    @x, @y, @w, @h = new
    @app.history.append [:frame, old, new]
  end

  def frame = [x, y, w, h]

  def color=(color)
    return if color == @color
    @color = color
    color_changed! color
  end

  def select(x, y, w, h)
    old        = @selection
    new        = correct_bounds x, y, w, h
    return if new == old
    @selection = new
    @app.history.append [:select, old, new]
  end

  def selection()
    xrange, yrange = x..(x + w), y..(y + h)
    sx, sy, sw, sh = @selection
    return nil unless
      xrange.include?(sx) && xrange.include?(sx + sw) &&
      yrange.include?(sy) && yrange.include?(sy + sh)
    @selection
  end

  def deselect()
    return if @selection == nil
    old, @selection = @selection, nil
    @app.history.append [:deselect, old]
  end

  def paint(&block)
    @image.begin_draw do |g|
      g.clip(*(selection || frame))
      g.push do
        g.translate x, y
        g.blend_mode REPLACE
        block.call g
      end
    end
  end

  def update_pixels(&block)
    tmp = sub_image x, y, w, h
    tmp.update_pixels {|pixels| block.call pixels}
    @image.begin_draw do |g|
      g.blend tmp, 0, 0, w, h, x, y, w, h, REPLACE
    end
  end

  def sub_image(x, y, w, h)
    create_graphics(w, h).tap do |g|
      g.begin_draw {g.blend @image, x, y, w, h, 0, 0, w, h, REPLACE}
    end
  end

  def pixel_at(x, y)
    img = sub_image self.x + x, self.y + y, 1, 1
    img.load_pixels
    c = img.pixels[0]
    [red(c), green(c), blue(c), alpha(c)].map &:to_i
  end

  def clear(frame, color:)
    paint do |g|
      g.fill(*color)
      g.no_stroke
      g.rect(*frame)
    end
  end

  def begin_editing(&block)
    @before = capture_frame
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    return unless @before
    @app.history.append [:capture, @before, capture_frame, x, y]
    save
  end

  def capture_frame(frame = self.frame)
    x, y, w, h = frame
    create_graphics(w, h).tap do |g|
      g.begin_draw do
        g.blend @image, x, y, w, h, 0, 0, w, h, REPLACE
      end
    end
  end

  def apply_frame(image, x, y)
    @image.begin_draw do |g|
      w, h = image.width, image.height
      g.blend image, 0, 0, w, h, x, y, w, h, REPLACE
    end
    save
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new.tap do |sp|
      pos = -> {to_image sp.mouse_x, sp.mouse_y}
      sp.draw           {draw}
      sp.mouse_pressed  {tool&.canvas_pressed( *pos.call, sp.mouse_button)}
      sp.mouse_released {tool&.canvas_released(*pos.call, sp.mouse_button)}
      sp.mouse_moved    {tool&.canvas_moved(   *pos.call)}
      sp.mouse_dragged  {tool&.canvas_dragged( *pos.call, sp.mouse_button)}
      sp.mouse_clicked  {tool&.canvas_clicked( *pos.call, sp.mouse_button)}
    end
  end

  private

  def to_image(x, y)
    return x, y unless @w && @h
    sp = sprite
    return x * (@w.to_f / sp.w), y * (@h.to_f / sp.h)
  end

  def correct_bounds(x, y, w, h)
    x2, y2 = x + w, y + h
    x, x2  = x2, x if x > x2
    y, y2  = y2, y if y > y2
    x, y   = x.floor, y.floor
    return x, y, (x2 - x).ceil, (y2 - y).ceil
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h

    fill 0
    no_stroke
    rect 0, 0, sp.w, sp.h

    copy @image, x, y, w, h, 0, 0, sp.w, sp.h if @image && x && y && w && h

    sx, sy = sp.w / w, sp.h / h
    scale sx, sy
    translate(-x, -y)
    no_fill
    stroke_weight 0

    draw_grids
    draw_selection sx, sy
  end

  def draw_grids()
    push do
      stroke 50, 50, 50
      shape grid 8
      stroke 100, 100, 100
      shape grid 16
      stroke 150, 150, 150
      shape grid 32
    end
  end

  def grid(interval)
    (@grids ||= {})[interval] ||= create_shape.tap do |sh|
      w, h = @image.width, @image.height
      sh.begin_shape LINES
      (0..w).step(interval).each do |x|
        sh.vertex x, 0
        sh.vertex x, h
      end
      (0..h).step(interval).each do |y|
        sh.vertex 0, y
        sh.vertex w, y
      end
      sh.end_shape
    end
  end

  def draw_selection(scale_x, scale_y)
    return unless @selection&.size == 4
    push do
      stroke 255, 255, 255
      shader selection_shader.tap {|sh|
        sh.set :time, frame_count.to_f / 60
        sh.set :scale, scale_x, scale_y
      }
=begin
      begin_shape LINES
      x, y, w, h = @selection
      vertex x,     y,     x, 0
      vertex x + w, y,     x + w, 0
      vertex x + w, y,     x, 0
      vertex x + w, y + h, x + w, 0
      vertex x + w, y + h, x, 0
      vertex x,     y + h, x + w, 0
      vertex x,     y + h, x, 0
      vertex x,     y,     x + w, 0
      end_shape
=end
      rect(*@selection)
    end
  end

  def selection_shader()
    @selection_shader ||= create_shader nil, <<~END
      varying vec4  vertTexCoord;
      uniform float time;
      uniform vec2  scale;
      void main()
      {
        vec2 pos = vertTexCoord.xy * scale;
        float t  = floor(time * 4.) / 4.;
        float x  = mod( pos.x + time, 4.) < 2. ? 1. : 0.;
        float y  = mod(-pos.y + time, 4.) < 2. ? 1. : 0.;
        gl_FragColor = x != y ? vec4(0., 0., 0., 1.) : vec4(1., 1., 1., 1.);
      }
    END
  end

end# Canvas
