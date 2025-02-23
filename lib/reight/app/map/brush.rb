using Reight


class Reight::MapEditor::Brush < Reight::MapEditor::BrushBase

  def initialize(app, &block)
    super app, icon: app.icon(1, 2, 8), &block
    set_help left: name, right: 'Pick Chip'
  end

  def brush(cursor_from, cursor_to, chip)
    x, y, = cursor_to
    put_or_remove_chip x, y, chip
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
