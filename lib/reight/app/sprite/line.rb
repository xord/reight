using Reight


class Reight::SpriteEditor::Line < Reight::SpriteEditor::Tool

  def initialize(app, &block)
    super app, icon: app.icon(3, 2, 8), &block
    set_help left: name, right: 'Pick Color'
  end

  def draw_line(x, y)
    canvas.begin_editing do
      canvas.paint do |g|
        g.stroke(*canvas.color)
        g.stroke_weight 0
        g.line @x, @y, x, y
      end
    end
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    @x, @y = x, y
    draw_line x, y
  end

  def canvas_dragged(x, y, button)
    return unless button == LEFT
    app.undo flash: false
    draw_line x, y
  end

  def canvas_clicked(x, y, button)
    pick_color x, y if button == RIGHT
  end

end# Line
