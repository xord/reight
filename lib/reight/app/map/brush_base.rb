using Reight


class Reight::MapEditor::BrushBase < Reight::MapEditor::Tool

  def brush(cursor_from, cursor_to, chip) = nil

  def put_or_remove_chip(x, y, chip)
    return false unless x && y && chip
    m = canvas.map
    return false if !@deleting && m[x, y]&.id == chip.id

    result = false
    m.each_chip x, y, chip.w, chip.h do |ch|
      m.remove_chip ch
      result |= history.append [:remove_chip, ch.pos.x, ch.pos.y, ch.id]
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
