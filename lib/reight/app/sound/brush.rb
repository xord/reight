class Reight::MusicEditor::Brush < Reight::MusicEditor::Tool

  def initialize(app, &block)
    super app, icon: app.icon(1, 2, 8), &block
    set_help left: name, right: 'Pick Tone'
  end

  def brush(x, y, button)
    canvas.put x, y
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
    pick_tone x, y if button == RIGHT
  end

end# Brush
