using Reight


class Reight::MapEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new self, project.maps.first, project.maps_json_path
  end

  def chips()
    @chips ||= Chips.new self, project.chips
  end

  def activated()
    super
    history.disable do
      tools[0].click
      chip_sizes[0].click
    end
  end

  def draw()
    background 200
    sprite(*sprites)
    super
  end

  def key_pressed()
    super
    shift, ctrl, cmd = %i[shift control command].map {pressing? _1}
    case key_code
    when LEFT  then canvas.x += SCREEN_WIDTH  / 2
    when RIGHT then canvas.x -= SCREEN_WIDTH  / 2
    when UP    then canvas.y += SCREEN_HEIGHT / 2
    when DOWN  then canvas.y -= SCREEN_HEIGHT / 2
    when :z    then shift ? self.redo : undo if ctrl || cmd
    when :b    then  brush.click
    when :l    then   line.click
    when :r    then (shift ? fill_rect : stroke_rect).click
    end
  end

  def window_resized()
    super
    chips.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = NAVIGATOR_HEIGHT + SPACE
      sp.w      = CHIPS_WIDTH
      sp.bottom = height - SPACE
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = chips.sprite.right + SPACE + (sp.w + 1) * index
      sp.y = height - (SPACE + sp.h)
    end
    chip_sizes.reverse.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = width - (SPACE + sp.w * (index + 1) + index)
      sp.y = height - (SPACE + sp.h)
    end
    canvas.sprite.tap do |sp|
      sp.x      = chips.sprite.right + SPACE
      sp.y      = chips.sprite.y
      sp.right  = width - SPACE
      sp.bottom = tools.first.sprite.top - SPACE
    end
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      in [:put_chip,    x, y, id] then canvas.map.delete x, y
      in [:delete_chip, x, y, id] then canvas.map.put    x, y, project.chips[id]
      in [  :select, sel, _]      then sel ? canvas.select(*sel) : canvas.deselect
      in [:deselect, sel]         then       canvas.select(*sel)
      end
      self.flash 'Undo!' if flash
    end
  end

  def redo(flash: true)
    history.redo do |action|
      case action
      in [:put_chip,    x, y, id] then canvas.map.put    x, y, project.chips[id]
      in [:delete_chip, x, y, id] then canvas.map.delete x, y
      in [  :select, _, sel]      then canvas.select(*sel)
      in [:deselect, _]           then canvas.deselect
      end
      self.flash 'Redo!' if flash
    end
  end

  private

  def sprites()
    [canvas, chips, *chip_sizes, *tools]
      .map(&:sprite) + super
  end

  def chip_sizes()
    @chip_sizes ||= group(*[8, 16, 32].map {|size|
      Reight::Button.new name: "#{size}x#{size}", label: size do
        chips.set_frame chips.x, chips.y, size, size
      end
    })
  end

  def tools()
    @tools ||= group brush, line, stroke_rect, fill_rect
  end

  def brush        = @brush       ||= Brush.new(self)             {canvas.tool = _1}
  def line         = @line        ||= Line.new(self)              {canvas.tool = _1}
  def stroke_rect  = @stroke_rect ||= Rect.new(self, fill: false) {canvas.tool = _1}
  def   fill_rect  =   @fill_rect ||= Rect.new(self, fill: true)  {canvas.tool = _1}

end# MapEditor


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


class Reight::MapEditor::Chips

  def initialize(app, chips, size = 8)
    @app, @chips = app, chips
    @offset      = create_vector

    @app.history.disable do
      set_frame 0, 0, size, size
    end
  end

  attr_reader :x, :y, :size

  def chip = @chips.at(x, y, size, size)

  def set_frame(x, y, w, h)
    raise 'Chips: width != height' if w != h
    @x    = align_to_grid(x).clamp(0..@chips.image.width)
    @y    = align_to_grid(y).clamp(0..@chips.image.height)
    @size = w
  end

  def draw()
    sp = sprite

    clip sp.x, sp.y, sp.w, sp.h
    translate(*clamp_offset(@offset).to_a)
    image @chips.image, 0, 0

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
    x  = offset.x.clamp([-(@chips.image.width  - sp.w), 0].min..0)
    y  = offset.y.clamp([-(@chips.image.height - sp.h), 0].min..0)
    create_vector align_to_grid(x), align_to_grid(y)
  end

  def align_to_grid(n)
    n.to_i / 8 * 8
  end

end# Chips


class Reight::MapEditor::Tool < Reight::Button

  def initialize(app, *a, **k, &b)
    super(*a, **k, &b)
    @app = app
  end

  attr_reader :app

  def canvas  = app.canvas

  def history = app.history

  def chips   = app.chips

  def name = self.class.name.split('::').last

  def pick_chip(x, y)
    chip = canvas.chip_at_cursor or return
    chips.mouse_clicked chip.x, chip.y
  end

  def canvas_pressed( x, y, button) = nil
  def canvas_released(x, y, button) = nil
  def canvas_moved(   x, y)         = nil
  def canvas_dragged( x, y, button) = nil
  def canvas_clicked( x, y, button) = nil

end# Tool


class Reight::MapEditor::BrushBase < Reight::MapEditor::Tool

  def brush(cursor_from, cursor_to, chip) = nil

  def put_or_delete_chip(x, y, chip)
    return false unless x && y && chip
    m = canvas.map
    return false if !@deleting && m[x, y]&.id == chip.id

    result = false
    m.each_chip x, y, chip.w, chip.h do |ch|
      m.delete_chip ch
      result |= history.append [:delete_chip, ch.pos.x, ch.pos.y, ch.id]
    end
    unless @deleting
      m.put x, y, chip
      result |= history.append [:put_chip, x, y, chip.id]
    end
    result
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    @cursor_from, @deleting = canvas.cursor.dup, chips.chip.empty?
    @undo_prev              = brush @cursor_from, canvas.cursor, chips.chip
  end

  def canvas_released(x, y, button)
    return unless button == LEFT
  end

  def canvas_moved(x, y)
    update_cursor x, y
  end

  def canvas_dragged(x, y, button)
    update_cursor x, y
    return unless button == LEFT
    app.undo flash: false if @undo_prev
    @undo_prev = brush @cursor_from, canvas.cursor, chips.chip
  end

  def canvas_clicked(x, y, button)
    pick_chip x, y if button == RIGHT
  end

  def update_cursor(x, y)
    canvas.set_cursor x, y, chips.size, chips.size
  end

end# BrushBase


class Reight::MapEditor::Brush < Reight::MapEditor::BrushBase

  def initialize(app, &block)
    super app, icon: app.icon(1, 2, 8), &block
    set_help left: name, right: 'Pick Chip'
  end

  def brush(cursor_from, cursor_to, chip)
    x, y, = cursor_to
    put_or_delete_chip x, y, chip
    false
  end

  def canvas_pressed(...)
    canvas.begin_editing
    super
  end

  def canvas_released(...)
    super
    canvas.end_editing
  end

end# Brush


class Reight::MapEditor::Line < Reight::MapEditor::BrushBase

  def initialize(app, &block)
    super app, icon: app.icon(3, 2, 8), &block
    set_help left: name, right: 'Pick Chip'
  end

  def brush(cursor_from, cursor_to, chip)
    result = false
    canvas.begin_editing do
      fromx, fromy = cursor_from[...2]
      tox,   toy   = cursor_to[...2]
      dx           = fromx < tox ? chip.w : -chip.w
      dy           = fromy < toy ? chip.h : -chip.h
      if (tox - fromx).abs > (toy - fromy).abs
        (fromx..tox).step(dx).each do |x|
          y = map x, fromx, tox, fromy, toy
          y = y / chip.h * chip.h
          result |= put_or_delete_chip x, y, chip
        end
      else
        (fromy..toy).step(dy).each do |y|
          x = map y, fromy, toy, fromx, tox
          x = x / chip.w * chip.w
          result |= put_or_delete_chip x, y, chip
        end
      end
    end
    result
  end

end# Line


class Reight::MapEditor::Rect < Reight::MapEditor::BrushBase

  def initialize(app, fill:, &block)
    @fill = fill
    super app, icon: app.icon(fill ? 5 : 4, 2, 8), &block
    set_help left: "#{fill ? 'Fill' : 'Stroke'} #{name}", right: 'Pick Chip'
  end

  def brush(cursor_from, cursor_to, chip)
    result = false
    canvas.begin_editing do
      fromx, fromy = cursor_from[...2]
      tox,   toy   = cursor_to[...2]
      fromx, tox   = tox, fromx if fromx > tox
      fromy, toy   = toy, fromy if fromy > toy
      (fromy..toy).step(chip.h).each do |y|
        (fromx..tox).step(chip.w).each do |x|
          next if !@fill && fromx < x && x < tox && fromy < y && y < toy
          result |= put_or_delete_chip x, y, chip
        end
      end
    end
    result
  end

end# Rect
