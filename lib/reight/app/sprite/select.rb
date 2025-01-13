using Reight


class Reight::SpriteEditor::Select < Reight::SpriteEditor::Tool

  def initialize(app, &block)
    super app, icon: app.icon(0, 2, 8), &block
    set_help left: 'Select or Move'
  end

  def move_or_select(x, y)
    x0, y0 = @press_pos&.to_a || return
    if @moving
      sx, sy, sw, sh = canvas.selection
      dx, dy         = (x - x0).to_i, (y - y0).to_i
      history.group do
        canvas.begin_editing do
          image = canvas.capture_frame [sx, sy, sw, sh]
          app.clear_canvas sx, sy, sw, sh
          canvas.apply_frame image, sx + dx, sy + dy
          canvas.select sx + dx, sy + dy, sw, sh
        end
      end
    else
      canvas.select canvas.x + x0, canvas.y + y0, x - x0, y - y0
    end
  end

  def canvas_pressed(x, y, button)
    @press_pos = create_vector x, y
    @moving    = button == LEFT && is_in_selection?(x, y)
    move_or_select x, y
  end

  def canvas_released(x, y, button)
    @press_pos = nil
    @moving    = false
  end

  def canvas_dragged(x, y, button)
    app.undo flash: false
    move_or_select x, y
  end

  def canvas_clicked(x, y, button)
    app.undo flash: false
    canvas.deselect
  end

  private

  def is_in_selection?(x, y)
    return false unless sel = canvas.selection
    sx, sy, sw, sh = sel
    (sx..(sx + sw)).include?(canvas.x + x) && (sy..(sy + sh)).include?(canvas.y + y)
  end

end# Select
