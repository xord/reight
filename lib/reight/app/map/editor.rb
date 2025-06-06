using Reight


class Reight::MapEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new self, project.maps.first
  end

  def chips()
    @chips ||= Chips.new(self, project.chips).tap do |chips|
      chips.offset_changed do |offset|
        chips_index.index = chips.offset2index offset
      end
    end
  end

  def setup()
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
    [chip_sizes, tools].flatten.map(&:sprite)
      .each {|sp| sp.w = sp.h = BUTTON_SIZE}

    chips_index.sprite.tap do |sp|
      sp.w, sp.h = INDEX_SIZE, BUTTON_SIZE
      sp.x       = SPACE
      sp.y       = NAVIGATOR_HEIGHT + SPACE
    end
    chip_sizes.reverse.map {_1.sprite}.each.with_index do |sp, index|
      sp.x = SPACE + CHIPS_WIDTH - (sp.w + (sp.w + 1) * index)
      sp.y = chips_index.sprite.y
    end
    chips.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = chip_sizes.last.sprite.bottom + SPACE
      sp.right  = chip_sizes.last.sprite.right
      sp.bottom = height - SPACE
    end
    map_index.sprite.tap do |sp|
      sp.w, sp.h = INDEX_SIZE, BUTTON_SIZE
      sp.x       = chip_sizes.last.sprite.right + SPACE
      sp.y       = chip_sizes.last.sprite.y
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.x = chips.sprite.right + SPACE + (sp.w + 1) * index
      sp.y = height - (SPACE + sp.h)
    end
    canvas.sprite.tap do |sp|
      sp.x      = map_index.sprite.x
      sp.y      = map_index.sprite.bottom + SPACE
      sp.right  = width - SPACE
      sp.bottom = tools.first.sprite.top - SPACE
    end
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      in [:put_chip,    x, y, id] then canvas.map.remove x, y
      in [:remove_chip, x, y, id] then canvas.map.put    x, y, project.chips[id]
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
      in [:remove_chip, x, y, id] then canvas.map.remove x, y
      in [  :select, _, sel]      then canvas.select(*sel)
      in [:deselect, _]           then canvas.deselect
      end
      self.flash 'Redo!' if flash
    end
  end

  private

  def sprites()
    [chips_index, *chip_sizes, chips, map_index, *tools, canvas]
      .map(&:sprite) + super
  end

  def chips_index()
    @chips_index ||= Reight::Index.new max: project.chips_npages - 1 do |index|
      chips.offset = chips.index2offset index if index != chips.offset2index
    end
  end

  def chip_sizes()
    @chip_sizes ||= group(*[8, 16, 32].map {|size|
      Reight::Button.new name: "#{size}x#{size}", label: size do
        chips.set_frame chips.x, chips.y, size, size
      end
    })
  end

  def map_index()
    @map_index ||= Reight::Index.new do |index|
      canvas.map = project.maps[index] ||= Reight::Map.new
    end
  end

  def tools()
    @tools ||= group brush, line, stroke_rect, fill_rect
  end

  def brush        = @brush       ||= Brush.new(self)             {canvas.tool = _1}
  def line         = @line        ||= Line.new(self)              {canvas.tool = _1}
  def stroke_rect  = @stroke_rect ||= Rect.new(self, fill: false) {canvas.tool = _1}
  def   fill_rect  =   @fill_rect ||= Rect.new(self, fill: true)  {canvas.tool = _1}

end# MapEditor
