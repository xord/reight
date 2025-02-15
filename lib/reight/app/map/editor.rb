using Reight


class Reight::MapEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new self, project.maps.first, project.maps_json_path
  end

  def chips()
    @chips ||= Chips.new self, project.chips
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
