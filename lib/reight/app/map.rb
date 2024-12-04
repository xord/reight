using Reight


class Reight::MapEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new self, project.maps.first, project.maps_path
  end

  def chips()
    @chips ||= ChipList.new self, project.chips
  end

  def activate
    super
    history.disable do
      tools[0].click
      chip_sizes[0].click
    end
  end

  def draw()
    background 100, 100, 100
    sprite *sprites
  end

  def window_resized()
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = SPACE + (sp.w + 1) * index
      sp.y = height - (SPACE + sp.h)
    end
    chip_sizes.reverse.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = width - (SPACE + sp.w * (index + 1) + index)
      sp.y = height - (SPACE + sp.h)
    end
    chips.sprite.tap do |sp|
      sp.w      = 80
      sp.x      = width - (SPACE + sp.w)
      sp.y      = NAVIGATOR_HEIGHT + SPACE
      sp.bottom = chip_sizes.first.sprite.y - SPACE / 2
    end
    canvas.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = NAVIGATOR_HEIGHT + SPACE
      sp.right  = chips.sprite.left - SPACE
      sp.bottom = tools.first.sprite.top - SPACE
    end
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      in [:put_chip,    x, y, id] then canvas.map.delete x, y
      in [:delete_chip, x, y, id] then canvas.map.put    x, y, project.chips[id]
      end
      self.flash 'Undo!' if flash
    end
  end

  def redo(flash: true)
    history.redo do |action|
      case action
      in [:put_chip,    x, y, id] then canvas.map.put    x, y, project.chips[id]
      in [:delete_chip, x, y, id] then canvas.map.delete x, y
      end
      self.flash 'Redo!' if flash
    end
  end

  private

  def sprites()
    [canvas, chips, *chip_sizes, *tools]
      .map &:sprite
  end

  def chip_sizes()
    @chip_sizes ||= group(*[8, 16, 32].map {|size|
      Reight::Button.new name: "#{size}x#{size}", label: size do
        chips.set_frame chips.x, chips.y, size, size
      end
    })
  end

  def tools()
    @tools ||= group brush, eraser
  end

  def brush  = @brush  ||= Brush.new(self)  {canvas.tool = _1}
  def eraser = @eraser ||= Eraser.new(self) {canvas.tool = _1}

end# MapEditor


class Reight::MapEditor::Canvas

  def initialize(app, map, path)
    @app, @map, @path = app, map, path
    @tool, @cursor    = nil, nil
  end

  attr_accessor :tool

  attr_reader :map, :cursor

  def save()
    @app.project.save
  end

  def set_cursor(x, y, w, h)
    @cursor = correct_bounds x, y, w, h
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
      sp.draw           {draw}
      sp.mouse_pressed  {tool&.canvas_pressed( sp.mouse_x, sp.mouse_y, sp.mouse_button)}
      sp.mouse_released {tool&.canvas_released(sp.mouse_x, sp.mouse_y, sp.mouse_button)}
      sp.mouse_moved    {tool&.canvas_moved(   sp.mouse_x, sp.mouse_y)}
      sp.mouse_dragged  {tool&.canvas_dragged( sp.mouse_x, sp.mouse_y, sp.mouse_button)}
      sp.mouse_clicked  {tool&.canvas_clicked( sp.mouse_x, sp.mouse_y, sp.mouse_button)}
    end
  end

  private

  def correct_bounds(x, y, w, h)
    x, y, w, h = [x, y, w, h].map &:to_i
    return x / w * w, y / h * h, w, h
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h

    fill 0, 0, 0
    noStroke
    rect 0, 0, sp.w, sp.h

    map.each_chip(0, 0, sp.w, sp.h, clip_by_chunk: true).each do |chip|
      pos = chip.pos
      copy chip.image, *chip.frame, pos.x, pos.y, chip.w, chip.h
    end

    if @cursor
      noFill
      stroke 255, 255, 255
      strokeWeight 1
      rect *@cursor
    end
  end

end# Canvas


class Reight::MapEditor::ChipList

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
    raise 'ChipList: width != height' if w != h
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
    x  = offset.x.clamp(-(@chips.image.width  - sp.w)..0)
    y  = offset.y.clamp(-(@chips.image.height - sp.h)..0)
    create_vector align_to_grid(x), align_to_grid(y)
  end

  def align_to_grid(n)
    n.to_i / 8 * 8
  end

end# ChipList


class Reight::MapEditor::Tool < Reight::Button

  def initialize(app, *a, **k, &b)
    super(*a, **k, &b)
    @app = app
  end

  attr_reader :app

  def history = app.history

  def canvas  = app.canvas

  def chips   = app.chips

  def pick(x, y)
    canvas.chip = canvas.chip_at x, y
  end

  def canvas_pressed( x, y, button) = nil
  def canvas_released(x, y, button) = nil
  def canvas_moved(   x, y)         = nil
  def canvas_dragged( x, y, button) = nil
  def canvas_clicked( x, y, button) = nil

end# Tool


class Reight::MapEditor::Brush < Reight::MapEditor::Tool

  def initialize(app, &block)
    super app, label: 'B', &block
    set_help left: 'Brush', right: 'Pick Chip'
  end

  def brush()
    map_, chip, x, y, = canvas.map, app.chips.chip, *canvas.cursor
    return unless chip && x && y
    return if map_[x, y]&.id == chip.id
    map_.each_chip x, y, chip.w, chip.h do |ch|
      map_.delete_chip ch
      history.append [:delete_chip, ch.pos.x, ch.pos.y, ch.id]
    end
    map_.put x, y, chip
    history.append [:put_chip, x, y, chip.id]
  end

  def update_cursor(x, y)
    canvas.set_cursor x, y, chips.size, chips.size
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    canvas.begin_editing
    brush
  end

  def canvas_released(x, y, button)
    return unless button == LEFT
    canvas.end_editing
  end

  def canvas_moved(x, y)
    update_cursor x, y
  end

  def canvas_dragged(x, y, button)
    return unless button == LEFT
    update_cursor x, y
    brush
  end

  def canvas_clicked(x, y, button)
    pick x, y if button == RIGHT
  end

end# Brush


class Reight::MapEditor::Eraser < Reight::MapEditor::Tool

  def initialize(app, &block)
    super app, label: 'E', &block
    set_help left: 'Eraser'
  end

  def erase()
    map_, cursor = canvas.map, canvas.cursor
    return unless cursor
    map_.each_chip(*cursor) do |chip|
      map_.delete_chip chip
      history.append [:delete_chip, chip.pos.x, chip.pos.y, chip.id]
    end
  end

  def update_cursor(x, y)
    canvas.set_cursor x, y, chips.size, chips.size
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    canvas.begin_editing
    erase
  end

  def canvas_released(x, y, button)
    return unless button == LEFT
    canvas.end_editing
  end

  def canvas_moved(x, y)
    update_cursor x, y
  end

  def canvas_dragged(x, y, button)
    return unless button == LEFT
    update_cursor x, y
    erase
  end

end# Eraser
