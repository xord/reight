using Reight


class Reight::SpriteEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new(
      self,
      r8.project.sprite_image,
      r8.project.sprite_image_path
    ).tap do |canvas|
      canvas.color_changed {update_active_color}
    end
  end

  def activate()
    super
    history.disable do
      sprite_sizes[0].click
      colors[7].click
      tools[1].click
      brush_sizes[0].click
    end
  end

  def draw()
    background 100, 100, 100
    sprite *sprites
  end

  def resized()
    space, button_size = 8, 12
    colors.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = button_size
      sp.x = space + sp.w * (index % 8)
      sp.y = height - (space + sp.h * (2 - index / 8))
    end
    edit_buttons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = button_size
      sp.x = colors.last.sprite.right + space + (sp.w + 1) * index
      sp.y = colors.first.sprite.y
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = button_size
      sp.x = edit_buttons.last.sprite.right + space + (sp.w + 1) * index
      sp.y = edit_buttons.first.sprite.y
    end
    brush_sizes.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = button_size
      sp.x = tools.first.sprite.x + (sp.w + 1) * index
      sp.y = tools.first.sprite.bottom + 2
    end
    sprite_sizes.reverse.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = button_size
      sp.x = width - (space + sp.w * (index + 1) + index)
      sp.y = tools.first.sprite.y - (sp.h + space)
    end
    sprite_sheet.sprite.tap do |sp|
      sp.w      = 80
      sp.x      = width - (space + sp.w)
      sp.y      = NAVIGATOR_HEIGHT + space
      sp.bottom = sprite_sizes.first.sprite.y - space / 2
    end
    canvas.sprite.tap do |sp|
      sp.x     = space
      sp.y     = sprite_sheet.sprite.y
      sp.right = sprite_sheet.sprite.x - space
      sp.h     = sp.w
    end
  end

  def key_pressed(key)
    pressing_keys.add key
    ss               = sprite_sheet
    shift, ctrl, cmd = %i[shift control command].map {pressing? _1}
    case key
    when LEFT  then ss.set_frame ss.x - ss.size, ss.y, ss.size, ss.size
    when RIGHT then ss.set_frame ss.x + ss.size, ss.y, ss.size, ss.size
    when UP    then ss.set_frame ss.x, ss.y - ss.size, ss.size, ss.size
    when DOWN  then ss.set_frame ss.x, ss.y + ss.size, ss.size, ss.size
    when :c    then copy  if ctrl || cmd
    when :x    then cut   if ctrl || cmd
    when :v    then paste if ctrl || cmd
    when :z    then shift ? self.redo : undo if ctrl || cmd
    when :s    then select.click
    when :b    then  brush.click
    when :f    then   fill.click
    when :r    then (shift ? fill_rect    : stroke_rect   ).click
    when :e    then (shift ? fill_ellipse : stroke_ellipse).click
    end
  end

  def key_released(key)
    pressing_keys.delete key
  end

  def copy(flash: true)
    sel   = canvas.selection || canvas.frame
    image = canvas.capture_frame(sel) || return
    x, y, = sel
    @copy = [image, x - canvas.x, y - canvas.y]
    self.flash 'Copy!' if flash
  end

  def cut(flash: true)
    copy flash: false
    image, x, y = @copy || return
    canvas.begin_editing do
      clear_canvas x, y, image.width, image.height
    end
    self.flash 'Cut!' if flash
  end

  def paste(flash: true)
    image, x, y = @copy || return
    w, h        = image.width, image.height
    history.group do
      canvas.deselect
      canvas.begin_editing do
        canvas.paint do |g|
          g.copy image, 0, 0, w, h, x, y, w, h
        end
      end
      canvas.select canvas.x + x, canvas.y + y, w, h
    end
    self.flash 'Paste!' if flash
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      in [:frame, [x, y, w, h], _]       then sprite_sheet.set_frame x, y, w, h
      in [:capture, before, after, x, y] then canvas.apply_frame before, x, y
      in [  :select, sel, _]             then sel ? canvas.select(*sel) : canvas.deselect
      in [:deselect, sel]                then canvas.select *sel
      end
      self.flash 'Undo!' if flash
    end
  end

  def redo(flash: true)
    history.redo do |action|
      case action
      in [:frame, _, [x, y, w, h]]       then sprite_sheet.set_frame x, y, w, h
      in [:capture, before, after, x, y] then canvas.apply_frame after, x, y
      in [  :select, _, sel]             then canvas.select *sel
      in [:deselect, _]                  then canvas.deselect
      end
      self.flash 'Redo!' if flash
    end
  end

  def clear_canvas(x, y, w, h)
    canvas.clear [x, y, w, h], color: colors.first.color
  end

  def set_brush_size(size)
    brush.size = size
    flash "Brush Size #{size}"
  end

  private

  def pressing_keys()
    @pressing_keys ||= Set.new
  end

  def pressing?(key)
    pressing_keys.include? key
  end

  def sprites()
    [
      *sprite_sizes,
      canvas,
      sprite_sheet,
      *colors,
      *edit_buttons,
      *tools,
      *brush_sizes
    ].map {_1.sprite}
  end

  def sprite_sizes()
    @sprite_sizes ||= group(*[8, 16, 32].map {|size|
      Reight::Button.new name: "#{size}x#{size}", label: size do
        sprite_sheet.set_frame sprite_sheet.x, sprite_sheet.y, size, size
      end
    })
  end

  def sprite_sheet()
    @sprite_sheet ||= SpriteSheet.new self, r8.project.sprite_image do |x, y, w, h|
      canvas.set_frame x, y, w, h
    end
  end

  def edit_buttons()
    @edit_buttons ||= [
      Reight::Button.new(name: 'Copy',  label: 'Co') {copy  flash: false},
      Reight::Button.new(name: 'Cut',   label: 'Cu') {cut   flash: false},
      Reight::Button.new(name: 'Paste', label: 'Pa') {paste flash: false},
    ]
  end

  def tools()
    @tools ||= group(
      select,
      brush,
      fill,
      stroke_rect,
        fill_rect,
      stroke_ellipse,
        fill_ellipse
    )
  end

  def select         = @select         ||= Select.new(self)                 {canvas.tool = _1}
  def brush          = @brush          ||= Brush.new(self)                  {canvas.tool = _1}
  def fill           = @fill           ||= Fill.new(self)                   {canvas.tool = _1}
  def stroke_rect    = @stroke_rect    ||= Shape.new(self, :rect,    false) {canvas.tool = _1}
  def   fill_rect    =   @fill_rect    ||= Shape.new(self, :rect,    true)  {canvas.tool = _1}
  def stroke_ellipse = @stroke_ellipse ||= Shape.new(self, :ellipse, false) {canvas.tool = _1}
  def   fill_ellipse =   @fill_ellipse ||= Shape.new(self, :ellipse, true)  {canvas.tool = _1}

  def brush_sizes()
    @brush_sizes ||= group(*[1, 2, 3, 5, 10].map {|size|
      Reight::Button.new name: "Button Size #{size}", label: size do
        set_brush_size size
      end
    })
  end

  def colors()
    @colors ||= r8.project.palette_colors.map {|color|
      rgb = self.color(color)
        .then {[red(_1), green(_1), blue(_1), alpha(_1)]}.map &:to_i
      Color.new(rgb) {canvas.color = rgb}
    }
  end

  def update_active_color()
    colors.each do |button|
      button.active = button.color == canvas.color
    end
  end

end# SpriteEditor


class Reight::SpriteEditor::Canvas

  def initialize(app, image, path)
    @app, @image, @path       = app, image, path
    @tool, @color, @selection = nil, [255, 255, 255], nil

    @app.history.disable do
      set_frame 0, 0, 16, 16
    end
  end

  attr_accessor :tool

  attr_reader :x, :y, :w, :h, :color, :selection

  def width  = @image.width

  def height = @image.height

  def save()
    @image.save @path
  end

  def set_frame(x, y, w, h)
    old            = [@x, @y, @w, @h]
    new            = correct_bounds x, y, w, h
    return if new == old
    @x, @y, @w, @h = new
    @app.history.push [:frame, old, new]
  end

  def frame = [x, y, w, h]

  def color=(color)
    return if color == @color
    @color = color
    color_changed!
  end

  def select(x, y, w, h)
    old        = @selection
    new        = correct_bounds x, y, w, h
    return if new == old
    @selection = new
    @app.history.push [:select, old, new]
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
    @app.history.push [:deselect, old]
  end

  def paint(&block)
    @image.begin_draw do |g|
      g.clip(*(selection || frame))
      g.push do
        g.translate x, y
        block.call g
      end
    end
  end

  def update_pixels(&block)
    tmp = sub_image x, y, w, h
    tmp.update_pixels {|pixels| block.call pixels}
    @image.begin_draw do |g|
      g.copy tmp, 0, 0, w, h, x, y, w, h
    end
  end

  def sub_image(x, y, w, h)
    create_graphics(w, h).tap do |g|
      g.begin_draw {g.copy @image, x, y, w, h, 0, 0, w, h}
    end
  end

  def pixel_at(x, y)
    img = sub_image x, y, 1, 1
    img.load_pixels
    c = img.pixels[0]
    [red(c), green(c), blue(c), alpha(c)].map &:to_i
  end

  def clear(frame, color: [0, 0, 0])
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
    save
    @app.history.push [:capture, @before, capture_frame, x, y]
  end

  def capture_frame(frame = self.frame)
    x, y, w, h = frame
    create_graphics(w, h).tap do |g|
      g.begin_draw do
        g.copy @image, x, y, w, h, 0, 0, w, h
      end
    end
  end

  def apply_frame(image, x, y)
    @image.begin_draw do |g|
      w, h = image.width, image.height
      g.copy image, 0, 0, w, h, x, y, w, h
    end
  end

  def color_changed(&block)
    (@color_changeds ||= []).push block if block
  end

  def color_changed!()
    @color_changeds&.each {_1.call color}
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      pos = -> {to_image sp.mouse_x, sp.mouse_y}
      sp.draw          {draw}
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
    copy @image, x, y, w, h, 0, 0, sp.w, sp.h if @image && x && y && w && h

    sx, sy = sp.w / w, sp.h / h
    scale sx, sy
    translate -x, -y
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
    (@grids ||= [])[interval] ||= create_shape.tap do |sh|
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
      rect *@selection
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


class Reight::SpriteEditor::SpriteSheet

  def initialize(app, image, size = 8, &selected)
    @app, @image, @selected = app, image, selected
    @offset = create_vector

    @app.history.disable do
      set_frame 0, 0, size, size
    end
  end

  attr_reader :x, :y, :size

  def set_frame(x, y, w, h)
    raise 'SpriteSheet: width != height' if w != h
    @x    = align_to_grid(x).clamp(0..@image.width)
    @y    = align_to_grid(y).clamp(0..@image.height)
    @size = w
    selected
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h
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
      -@offset.y + align_to_grid(y),
      size,
      size)
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw          {draw}
      sp.mouse_pressed  {mouse_pressed  sp.mouse_x, sp.mouse_y}
      sp.mouse_released {mouse_released sp.mouse_x, sp.mouse_y}
      sp.mouse_dragged  {mouse_dragged  sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {mouse_clicked  sp.mouse_x, sp.mouse_y}
    end
  end

  private

  def clamp_offset(offset)
    sp = sprite
    x  = offset.x.clamp(-(@image.width  - sp.w)..0)
    y  = offset.y.clamp(-(@image.height - sp.h)..0)
    create_vector align_to_grid(x), align_to_grid(y)
  end

  def align_to_grid(n)
    n.to_i / 8 * 8
  end

  def selected()
    @selected.call @x, @y, @size, @size
  end

end# SpriteSheet


class Reight::SpriteEditor::Tool < Reight::Button

  def initialize(app, *a, **k, &b)
    super(*a, **k, &b)
    @app = app
  end

  attr_reader :app

  def canvas  = app.canvas

  def history = app.history

  def pick_color(x, y)
    canvas.color = canvas.pixel_at x, y
  end

  def canvas_pressed(x, y, button)
  end

  def canvas_released(x, y, button)
  end

  def canvas_moved(x, y)
  end

  def canvas_dragged(x, y, button)
  end

  def canvas_clicked(x, y, button)
  end

end# Tool


class Reight::SpriteEditor::Select < Reight::SpriteEditor::Tool

  def initialize(app, &block)
    super app, label: 'S', &block
    set_help left: 'Select or Move'
  end

  def move_or_select(x, y)
    x0, y0 = @press_pos&.to_a || return
    if @moving
      sx, sy, sw, sh = canvas.selection
      dx, dy         = (x - x0).to_i, (y - y0).to_i
      history.group do
        canvas.begin_editing do
          image = canvas.capture_frame [sx, sy, sw, sh]
          app.clear_canvas sx, sy, sw, sh
          canvas.apply_frame image, sx + dx, sy + dy
          canvas.select sx + dx, sy + dy, sw, sh
        end
      end
    else
      canvas.select canvas.x + x0, canvas.y + y0, x - x0, y - y0
    end
  end

  def canvas_pressed(x, y, button)
    @press_pos = create_vector x, y
    @moving    = button == LEFT && is_in_selection?(x, y)
    move_or_select x, y
  end

  def canvas_released(x, y, button)
    @press_pos = nil
    @moving    = false
  end

  def canvas_dragged(x, y, button)
    app.undo flash: false
    move_or_select x, y
  end

  def canvas_clicked(x, y, button)
    app.undo flash: false
    canvas.deselect
  end

  private

  def is_in_selection?(x, y)
    return false unless sel = canvas.selection
    sx, sy, sw, sh = sel
    (sx..(sx + sw)).include?(canvas.x + x) && (sy..(sy + sh)).include?(canvas.y + y)
  end

end# Select


class Reight::SpriteEditor::Brush < Reight::SpriteEditor::Tool

  def initialize(app, &block)
    super app, label: 'B', &block
    @size = 1
    set_help left: 'Brush', right: 'Pick Color'
  end

  attr_accessor :size

  def brush(x, y, button)
    canvas.paint do |g|
      g.no_fill
      g.stroke *canvas.color
      g.stroke_weight size
      g.point x, y
    end
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    canvas.begin_editing
    brush x, y, button
  end

  def canvas_released(x, y, button)
    return unless button == LEFT
    canvas.end_editing
  end

  def canvas_dragged(x, y, button)
    return unless button == LEFT
    brush x, y, button
  end

  def canvas_clicked(x, y, button)
    pick_color x, y if button == RIGHT
  end

end# Brush


class Reight::SpriteEditor::Fill < Reight::SpriteEditor::Tool

  def initialize(app, &block)
    super app, label: 'F', &block
    set_help left: 'Fill', right: 'Pick Color'
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    x, y           = [x, y].map &:to_i
    fx, fy, fw, fh = canvas.frame
    sx, sy, sw, sh = canvas.selection || canvas.frame
    sx -= fx
    sy -= fy
    return unless (sx...(sx + sw)).include?(x) && (sy...(sy + sh)).include?(y)
    canvas.begin_editing
    count = 0
    canvas.update_pixels do |pixels|
      from = pixels[y * fw + x]
      to   = color *canvas.color
      rest = [[x, y]]
      until rest.empty?
        xx, yy = rest.shift
        next if pixels[yy * fw + xx] == to
        pixels[yy * fw + xx] = to
        count += 1
        _x, x_ = xx - 1, xx + 1
        _y, y_ = yy - 1, yy + 1
        rest << [_x, yy] if _x >= sx      && pixels[yy * fw + _x] == from
        rest << [x_, yy] if x_ <  sx + sw && pixels[yy * fw + x_] == from
        rest << [xx, _y] if _y >= sy      && pixels[_y * fw + xx] == from
        rest << [xx, y_] if y_ <  sy + sh && pixels[y_ * fw + xx] == from
      end
    end
    canvas.end_editing if count > 0
  end

  def canvas_clicked(x, y, button)
    pick_color x, y if button == RIGHT
  end

end# Fill


class Reight::SpriteEditor::Shape < Reight::SpriteEditor::Tool

  def initialize(app, shape, fill, &block)
    @shape, @fill = shape, fill
    super app, label: "#{shape[0].capitalize}#{fill ? :f : :s}", &block
    set_help left: name, right: 'Pick Color'
  end

  def name = "#{@fill ? :Fill : :Stroke} #{@shape.capitalize}"

  def draw_shape(x, y)
    canvas.begin_editing do
      canvas.paint do |g|
        @fill ? g.fill(*canvas.color) : g.no_fill
        g.stroke(*canvas.color)
        g.rect_mode    CORNER
        g.ellipse_mode CORNER
        g.send @shape, @x, @y, x - @x, y - @y
      end
    end
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    @x, @y = x, y
    draw_shape x, y
  end

  def canvas_dragged(x, y, button)
    return unless button == LEFT
    app.undo flash: false
    draw_shape x, y
  end

  def canvas_clicked(x, y, button)
    pick_color x, y if button == RIGHT
  end

end# Shape


class Reight::SpriteEditor::Color < Reight::Button

  def initialize(color, &clicked)
    super name: '', &clicked
    @color = color
  end

  attr_reader :color

  def draw()
    sp = sprite

    fill *color
    no_stroke
    rect 0, 0, sp.w, sp.h

    if active?
      no_fill
      stroke_weight 1
      stroke '#000000'
      rect 2, 2, sp.w - 4, sp.h - 4
      stroke '#ffffff'
      rect 1, 1, sp.w - 2, sp.h - 2
    end
  end

end# Color
