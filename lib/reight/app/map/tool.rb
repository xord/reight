using Reight


class Reight::MapEditor::Tool < Reight::Button

  def initialize(app, *a, **k, &b)
    super(*a, **k, &b)
    @app = app
  end

  attr_reader :app

  def canvas  = app.canvas

  def history = app.history

  def chips   = app.chips

  def name = self.class.name.split('::').last

  def pick_chip(x, y)
    chip = canvas.chip_at_cursor or return
    chips.mouse_clicked chip.x, chip.y
  end

  def canvas_pressed( x, y, button) = nil
  def canvas_released(x, y, button) = nil
  def canvas_moved(   x, y)         = nil
  def canvas_dragged( x, y, button) = nil
  def canvas_clicked( x, y, button) = nil

end# Tool
