using Reight


class Reight::SpriteEditor::Brush < Reight::SpriteEditor::Tool

  def initialize(app, &block)
    super app, icon: app.icon(1, 2, 8), &block
    @size = 1
    set_help left: 'Brush', right: 'Pick Color'
  end

  attr_accessor :size

  def brush(x, y, button)
    canvas.paint do |g|
      g.no_fill
      g.stroke(*canvas.color)
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
