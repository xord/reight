class Reight::MusicEditor::Eraser < Reight::MusicEditor::Tool

  def initialize(app, &block)
    super app, icon: app.icon(3, 2, 8), &block
    set_help left: name
  end

  def erase(x, y, button)
    canvas.delete x, y
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    canvas.begin_editing
    erase x, y, button
  end

  def canvas_released(x, y, button)
    return unless button == LEFT
    canvas.end_editing
  end

  def canvas_dragged(x, y, button)
    return unless button == LEFT
    erase x, y, button
  end

end# Eraser
