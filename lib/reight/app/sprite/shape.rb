using Reight


class Reight::SpriteEditor::Shape < Reight::SpriteEditor::Tool

  def initialize(app, shape, fill, &block)
    @shape, @fill = shape, fill
    icon_index = [:rect, :ellipse].product([false, true]).index([shape, fill])
    super app, icon: app.icon(icon_index + 4, 2, 8), &block
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
